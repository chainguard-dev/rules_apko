"A rule for running apko with prepopulated cache"

def _impl(ctx):
    apko_info = ctx.toolchains["@rules_apko//apko:toolchain_type"].apko_info

    cache_name = "cache_{}".format(ctx.label.name)

    output = ctx.actions.declare_file("{}.tar".format(ctx.label.name))

    args = ctx.actions.args()
    args.add("build")
    args.add(ctx.file.config.path)
    args.add(ctx.attr.tag)
    args.add(output.path)
    args.add("--vcs=false")
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

apko_image = rule(
    implementation = _impl,
    attrs = {
        "packages": attr.label(),
        "tag": attr.string(mandatory = True),
        "config": attr.label(allow_single_file = True, mandatory = True),
    },
    toolchains = ["@rules_apko//apko:toolchain_type"],
)
