"A rule for running apko with prepopulated cache"

_ATTRS = {
    "contents": attr.label(mandatory = True),
    "config": attr.label(allow_single_file = True, mandatory = True),
    "output": attr.string(default = "oci", values = ["oci", "docker"]),
    "architecture": attr.string(),
    "tag": attr.string(mandatory = True),
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

    if ctx.attr.architecture:
        args.add("--arch")
        args.add(ctx.attr.architecture)

    inputs = [ctx.file.config] + ctx.files.contents

    for content in ctx.files.contents:
        content_owner = content.owner.workspace_name
        content_cache_entry_key = content.path[content.path.find(content_owner) + len(content_owner) + 1:]
        content_entry = ctx.actions.declare_file("/".join([cache_name, content_cache_entry_key]))
        ctx.actions.symlink(
            target_file = content,
            output = content_entry,
        )
        inputs.append(content_entry)

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
