"A rule for running apko with prepopulated cache"

_ATTRS = {
    "packages": attr.label(),
    "tag": attr.string(mandatory = True),
    "config": attr.label(allow_single_file = True, mandatory = True),
    "output": attr.string(default = "oci", values = ["oci", "docker"]),
    "args": attr.string_list(),
}

def _impl(ctx):
    apko_info = ctx.toolchains["@rules_apko//apko:toolchain_type"].apko_info

    cache_name = "cache_{}".format(ctx.label.name)

    if ctx.attr.output == "oci":
        output = ctx.actions.declare_directory(ctx.label.name)
    else:
        output = ctx.actions.declare_file("{}.tar".format(ctx.label.name))

    args = ctx.actions.args()
    args.add("build")
    args.add(ctx.file.config.path)
    args.add(ctx.attr.tag)
    args.add(output.path)

    args.add("--vcs=false")

    args.add_all(ctx.attr.args)

    args.add("--cache-dir={}/{}/{}".format(ctx.bin_dir.path, ctx.label.package, cache_name))
    args.add("--offline")

    inputs = [ctx.file.config] + ctx.files.packages

    for package in ctx.files.packages:
        package_owner = package.owner.workspace_name
        package_cache_entry_key = package.path[package.path.find(package_owner) + len(package_owner) + 1:]
        package_entry = ctx.actions.declare_file("/".join([cache_name, package_cache_entry_key]))
        ctx.actions.symlink(
            target_file = package,
            output = package_entry,
        )
        inputs.append(package_entry)

    ctx.actions.run(
        executable = apko_info.binary,
        arguments = [args],
        inputs = inputs,
        outputs = [output],
    )

    return DefaultInfo(
        files = depset([output]),
    )

apko_image_lib = struct(
    attrs = _ATTRS,
    implementation = _impl,
    toolchains = ["@rules_apko//apko:toolchain_type"],
)

apko_image = rule(
    implementation = apko_image_lib.implementation,
    attrs = apko_image_lib.attrs,
    toolchains = apko_image_lib.toolchains,
)
