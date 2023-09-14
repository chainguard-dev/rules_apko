"""This module implements the language-specific toolchain rule."""

ApkoInfo = provider(
    doc = "Information about how to invoke the apko executable.",
    fields = {
        "binary": "Path to an apko binary",
    },
)

def _apko_toolchain_impl(ctx):
    binary = ctx.executable.apko
    template_variables = platform_common.TemplateVariableInfo({
        "APKO_BIN": binary.path,
    })
    default = DefaultInfo(
        files = depset([binary]),
        runfiles = ctx.runfiles(files = [binary]),
    )
    apko_info = ApkoInfo(binary = binary)
    toolchain_info = platform_common.ToolchainInfo(
        apko_info = apko_info,
        template_variables = template_variables,
        default = default,
    )
    return [
        default,
        toolchain_info,
        template_variables,
    ]

apko_toolchain = rule(
    implementation = _apko_toolchain_impl,
    attrs = {
        "apko": attr.label(
            doc = "A hermetically downloaded executable target for the target platform.",
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Defines an apko toolchain. See: https://docs.bazel.build/versions/main/toolchains.html#defining-toolchains.",
)
