"Fixtures for staging a tree artifact through copy_to_workdir."

# buildifier: disable=bzl-visibility
load("@rules_apko//apko/private:apko_config.bzl", "COREUTILS_TOOLCHAIN_TYPE", "copy_to_workdir")

def _tree_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.name)
    ctx.actions.run_shell(
        outputs = [out],
        command = 'mkdir -p "$1/sub" && echo extra > "$1/sub/file"',
        arguments = [out.path],
    )
    return DefaultInfo(files = depset([out]))

tree = rule(implementation = _tree_impl)

def _staged_tree_check_impl(ctx):
    src = ctx.attr.src[DefaultInfo].files.to_list()[0]
    staged = ctx.actions.declare_directory(ctx.attr.name + "_staged")
    copy_to_workdir(ctx, src, staged)

    # Staging a directory must put its contents at the destination, not nest
    # the directory one level down at <destination>/<basename>.
    marker = ctx.actions.declare_file(ctx.attr.name + ".ok")
    ctx.actions.run_shell(
        inputs = [staged],
        outputs = [marker],
        command = 'test -f "$1/sub/file" && ! test -e "$1/$3" && touch "$2"',
        arguments = [staged.path, marker.path, src.basename],
    )
    return DefaultInfo(files = depset([marker]))

staged_tree_check = rule(
    implementation = _staged_tree_check_impl,
    attrs = {"src": attr.label(mandatory = True)},
    toolchains = [COREUTILS_TOOLCHAIN_TYPE],
)
