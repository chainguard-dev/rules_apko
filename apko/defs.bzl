"Public API re-exports"

URL="https%3A%2F%2Fdl-cdn.alpinelinux.org%2Falpine%2Fedge%2Fmain"

def _impl(ctx):

    apko_info = ctx.toolchains["@rules_apko//apko:toolchain_type"].apko_info

    cache_name = "cache_{}".format(ctx.label.name)

    output = ctx.actions.declare_file("{}.tar".format(ctx.label.name))

    args=ctx.actions.args()
    args.add("build")
    args.add(ctx.file.config.path)
    args.add("apko-alpine:edge")
    args.add(output.path)
    args.add("--vcs=false")
    args.add("--cache-dir={}".format(cache_name))

    # args.add("--cache-dir=/var/folders/c3/qcpmmp4s0_1cy0b3bxjwcsqh0000gn/T/tmp.UvdmRIrK")
 

    inputs = [ctx.file.config] + ctx.files.packages
    
    for package in ctx.files.packages:
        package_entry = ctx.actions.declare_file("{cache_name}/{base_url}/{arch}/{basename}".format(
            cache_name = cache_name, 
            base_url = URL, 
            arch = package.dirname.rsplit("/", 2)[-2], 
            basename = package.basename
        ))
        ctx.actions.symlink(
            target_file = package,
            output = package_entry
        )
        inputs.append(package_entry)


    ctx.actions.run(
        executable = apko_info.binary,
        arguments=[args],
        inputs=inputs,
        outputs=[output]
    )

    return DefaultInfo(
        files = depset([output])
    )



apko_image = rule(
    implementation = _impl,
    attrs = {
        "packages": attr.label(),
        "config": attr.label(allow_single_file = True, mandatory = True)
    },
    toolchains = ["@rules_apko//apko:toolchain_type"]
)