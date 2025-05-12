"A rule for expanding apko config"

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//apko/private:apko_config.bzl", "prepare_apko_config_in_workdir")

def _impl(ctx):
    output = ctx.actions.declare_file(ctx.attr.name)
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

    args = ctx.actions.args()
    args.add("show-config")
    args.add(ctx.file.config.short_path)

    # TODO: Add --include-paths once show-config supports it. See apko_image.bzl
    # for usage and reasoning.

    inputs = prepare_apko_config_in_workdir(workdir, ctx)

    args.add("--offline")

    apko_binary = ctx.actions.declare_file(paths.join(workdir, apko_info.binary.short_path))
    ctx.actions.symlink(
        target_file = apko_info.binary,
        output = apko_binary,
    )
    inputs.append(apko_binary)

    ctx.actions.run_shell(
        command = "cd {} && {} $@ > {}".format(paths.join(ctx.bin_dir.path, ctx.label.workspace_root, ctx.label.package, workdir), apko_info.binary.short_path, paths.join("../", output.basename)),
        arguments = [args],
        inputs = inputs,
        tools = [apko_info.binary],
        outputs = [output],
    )

    return DefaultInfo(
        files = depset([output]),
    )

apko_show_config = rule(
    implementation = _impl,
    attrs = {
        "config": attr.label(
            doc = """Label to the `apko.yaml` file.  
For more advanced use-cases (multi-file configuration), use target providing `ApkoConfigInfo`
(e.g. output of `apko_config` rule).""",
            allow_single_file = True,
            mandatory = True,
        ),
    },
    doc = "Wrapper around `apko show-config` command to generate expanded config as bazel build action.",
    toolchains = ["@rules_apko//apko:toolchain_type"],
)
