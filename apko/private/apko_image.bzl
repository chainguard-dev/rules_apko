"A rule for running apko with prepopulated cache"

load("//apko/private:apko_run.bzl", "apko_run")
load("//apko/private:apko_config.bzl", "prepare_apko_config_in_workdir")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:versions.bzl", "versions")

_ATTRS = {
    "contents": attr.label(doc = "Label to the contents repository generated by translate_lock. See [apko-cache](./apko-cache.md) documentation.", mandatory = True, providers = [OutputGroupInfo]),
    "config": attr.label(doc = "Label to the `apko.yaml` file.", allow_single_file = True, mandatory = True),
    "output": attr.string(default = "oci", values = ["oci", "docker"]),
    "architecture": attr.string(doc = "the CPU architecture which this image should be built to run on. See https://github.com/chainguard-dev/apko/blob/main/docs/apko_file.md#archs-top-level-element"),
    "tag": attr.string(doc = "tag to apply to the resulting docker tarball. only applicable when `output` is `docker`", mandatory = True),
    "args": attr.string_list(doc = "additional arguments to provide when running the `apko build` command."),
}

def _impl(ctx):
    apko_info = ctx.toolchains["@rules_apko//apko:toolchain_type"].apko_info

    # We execute apko build within ctx.bin_dir.path/workdir and make all the files available within the workdir.
    # The key part here is that the path to input file in action is:
    # - bin_dir/target.short_path for generated targets (example bazel-out/.../path/to/my_config)
    # - target.short_path for source files. (example path/to/source_config)
    #
    # For each input file we create a symlink as workdir/input.short_path
    # Since the symlink is a generated target, its path is:
    # bin_dir/workspace_root/package/workdir/input.short_path
    #
    # Then when we move to bin_dir/workspace_root/package the relative path become target.short_path for all kinds of input files.
    workdir = "workdir_{}".format(ctx.label.name)
    cache_name = "cache_{}".format(ctx.label.name)

    if ctx.attr.output == "oci":
        output = ctx.actions.declare_directory(ctx.label.name)
    else:
        output = ctx.actions.declare_file("{}.tar".format(ctx.label.name))

    args = ctx.actions.args()
    args.add("build")
    args.add(ctx.file.config.short_path)
    args.add(ctx.attr.tag)

    args.add("../" + output.basename)

    args.add("--vcs=false")

    # This is a solution for building apko images with base image that's configs are declared in remote repositories.
    # 1. short paths in Bazel depend on the caller context. For example. There are
    #     - //foo:bar and //foo:baz targets in repo A,
    #     - //foo:bar depends on //foo:baz.
    #     - When calling bazel build //foo:bar within A, the shortpath of //foo:baz is foo/baz.
    #     - But if one calls bazel build @A//foo:bar from repo B, the short path of foo:baz is ../A/foo/baz
    # 2. On the other hand apko dumps the checksum of config file into lockfile, so we cannot generate config files that would very depending on
    #    where they are called from.
    # 3. This is a problem only when foo/bar is called both from A and from B - we need to choose one of the short paths in the config. The other possibility
    #    is added with include-paths flag.
    supports_include_paths = versions.is_at_least("0.15.0", apko_info.version)
    if supports_include_paths:
        args.add("--include-paths=../{}".format(ctx.label.workspace_name))

    args.add_all(ctx.attr.args)

    lockfile = ctx.attr.contents[OutputGroupInfo].lockfile.to_list()[0]
    apks = ctx.attr.contents[OutputGroupInfo].apks
    indexes = ctx.attr.contents[OutputGroupInfo].indexes
    keyrings = ctx.attr.contents[OutputGroupInfo].keyrings

    inputs = prepare_apko_config_in_workdir(workdir, ctx)

    deps = [apks, keyrings]

    supports_lockfile = versions.is_at_least("0.13.0", apko_info.version)
    if supports_lockfile:
        lockfile_symlink = ctx.actions.declare_file(paths.join(workdir, lockfile.short_path))
        ctx.actions.symlink(
            target_file = lockfile,
            output = lockfile_symlink,
        )
        inputs.append(lockfile_symlink)
        args.add("--lockfile={}".format(lockfile.short_path))
    else:
        deps.append(indexes)

    args.add("--cache-dir={}".format(cache_name))
    args.add("--offline")

    if ctx.attr.architecture:
        args.add("--arch")
        args.add(ctx.attr.architecture)

    for content in depset(transitive = deps).to_list():
        content_owner = content.owner.workspace_name
        content_cache_entry_key = content.path[content.path.find(content_owner) + len(content_owner) + 1:]
        content_entry = ctx.actions.declare_file(paths.join(workdir, cache_name, content_cache_entry_key))
        ctx.actions.symlink(
            target_file = content,
            output = content_entry,
        )
        inputs.append(content_entry)

    sbom = ctx.actions.declare_directory(ctx.label.name + "_sbom")
    args.add("--sbom-path={}".format("../" + sbom.basename))

    apko_binary = ctx.actions.declare_file(paths.join(workdir, apko_info.binary.short_path))
    ctx.actions.symlink(
        target_file = apko_info.binary,
        output = apko_binary,
    )
    inputs.append(apko_binary)

    ctx.actions.run_shell(
        command = "cd {} && {} $@".format(paths.join(ctx.bin_dir.path, ctx.label.workspace_root, ctx.label.package, workdir), apko_info.binary.short_path),
        arguments = [args],
        inputs = inputs,
        tools = [apko_info.binary],
        outputs = [output, sbom],
    )

    return [
        DefaultInfo(files = depset([output])),
        OutputGroupInfo(sbom = depset([sbom])),
    ]

apko_image_lib = struct(
    attrs = _ATTRS,
    implementation = _impl,
    toolchains = ["@rules_apko//apko:toolchain_type"],
)

_apko_image = rule(
    implementation = apko_image_lib.implementation,
    attrs = apko_image_lib.attrs,
    toolchains = apko_image_lib.toolchains,
)

def apko_image(
        name,
        contents,
        config,
        tag,
        output = "oci",
        architecture = None,
        args = [],
        **kwargs):
    """Build OCI images from APK packages directly without Dockerfile

    This rule creates images using the 'apko.yaml' configuration file and relies on cache contents generated by [translate_lock](./translate_lock.md) to be fast.

    ```starlark
    apko_image(
        name = "example",
        config = "apko.yaml",
        contents = "@example_lock//:contents",
        tag = "example:latest",
    )
    ```

    The label `@example_lock//:contents` is generated by the `translate_lock` extension, which consumes an 'apko.lock.json' file.
    For more details, refer to the [documentation](./docs/apko-cache.md).

    An example demonstrating usage with [rules_oci](https://github.com/bazel-contrib/rules_oci)

    ```starlark
    apko_image(
        name = "alpine_base",
        config = "apko.yaml",
        contents = "@alpine_base_lock//:contents",
        tag = "alpine_base:latest",
    )

    oci_image(
        name = "app",
        base = ":alpine_base"
    )
    ```

    For more examples checkout the [examples](/examples) directory.

    Args:
     name:         of the target for the generated image.
     contents:     Label to the contents repository generated by translate_lock. See [apko-cache](./apko-cache.md) documentation.
     config:       Label to the `apko.yaml` file.  For more advanced use-cases (multi-file configuration), use target providing `ApkoConfigInfo`
        (e.g. output of `apko_config` rule).
     output:       "oci" of  "docker",
     architecture: the CPU architecture which this image should be built to run on. See https://github.com/chainguard-dev/apko/blob/main/docs/apko_file.md#archs-top-level-element"),
     tag:          tag to apply to the resulting docker tarball. only applicable when `output` is `docker`
     args:         additional arguments to provide when running the `apko build` command.
     **kwargs:       other common arguments like: tags, visibility.
    """
    _apko_image(
        name = name,
        config = config,
        contents = contents,
        output = output,
        architecture = architecture,
        tag = tag,
        args = args,
        **kwargs
    )
    config_label = native.package_relative_label(config)

    # We generate the `.lock` (or `.resolve`)s target only if the config (apko.yaml file) is in the same package as the apko_image rule.
    if config_label.workspace_name == "" and config_label.package == native.package_name() and config_label.name.endswith(".yaml"):
        lock_json_name = config_label.name.removesuffix(".yaml") + ".lock.json"

        # We generate the .lock target only if the `.apko.lock.json` file exists in the same package.
        for _ in native.glob([lock_json_name]):
            apko_run(
                name = name + ".lock",
                # args is subject to make variables substitution: https://bazel.build/reference/be/common-definitions#common-attributes-binaries
                args = ["lock", "$(execpath {})".format(config), "--output={}/{}".format(config_label.package, lock_json_name)],
                workdir = "workspace",
                data = [config],
            )

        resolved_json_name = config_label.name.removesuffix(".yaml") + ".resolved.json"

        # We generate the .resolve target only if the `.apko.resolved.json` file exists in the same package.
        for _ in native.glob([resolved_json_name], allow_empty = True):
            apko_run(
                name = name + ".resolve",
                # args is subject to make variables substitution: https://bazel.build/reference/be/common-definitions#common-attributes-binaries
                args = ["resolve", "$(execpath {})".format(config), "--output={}/{}".format(config_label.package, lock_json_name)],
                workdir = "workspace",
                data = [config],
                deprecation = "Please use .lock target instead. Rename your .resolve.json file to .lock.json file.",
            )
