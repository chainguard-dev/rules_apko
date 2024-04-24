"""Example of generated apko config with ApkoConfigInfo."""

load("@rules_apko//apko:defs.bzl", "ApkoConfigInfo")

def _apko_config_example_impl(ctx):
    config_out = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.run_shell(
        inputs = [ctx.file.config],
        outputs = [config_out],
        command = "cp {} {}".format(ctx.file.config.path, config_out.path),
    )
    additional_file = ctx.actions.declare_file(ctx.attr.name + ".additional")
    ctx.actions.write(output = additional_file, content = "HELLO")
    return [
        DefaultInfo(files = depset([config_out])),
        ApkoConfigInfo(files = depset([additional_file])),
    ]

apko_config_example = rule(
    implementation = _apko_config_example_impl,
    attrs = {
        "config": attr.label(allow_single_file = True),
    },
)
