"""Provider that serves as an API for adding any files needed for apko build"""

ApkoConfigInfo = provider(
    doc = "Information about apko config. May be used when generating apko config file instead of using hardcoded ones.",
    fields = {
        "files": "depset of files that will be needed for building.",
    },
)

def _apko_config_impl(ctx):
    gen_script = ctx.actions.declare_file(ctx.attr.name + ".gen_script.sh")

    include = ""
    if ctx.file.include:
        include = ctx.file.include.path
    config_path = ""
    if ctx.file.config:
        config_path = ctx.file.config.path

    ctx.actions.expand_template(
        template = ctx.file._config_template,
        output = gen_script,
        substitutions = {
            "{{INCLUDE}}": include,
            "{{CONFIG_PATH}}": config_path,
        },
        is_executable = True,
    )

    out = ctx.actions.declare_file(ctx.attr.name)
    inputs = [gen_script]
    if ctx.file.config:
        inputs.append(ctx.file.config)
    ctx.actions.run_shell(
        command = "{} > {}".format(gen_script.path, out.path),
        inputs = inputs,
        outputs = [out],
    )

    apko_depsets = []
    if ctx.attr.include and ApkoConfigInfo in ctx.attr.include:
        apko_depsets.append(ctx.attr.include[ApkoConfigInfo].files)
    if ctx.attr.config and ApkoConfigInfo in ctx.attr.config:
        apko_depsets.append(ctx.attr.config[ApkoConfigInfo].files)

    direct_deps = []
    if ctx.file.include:
        direct_deps.append(ctx.file.include)
    if ctx.file.config:
        direct_deps.append(ctx.file.config)

    return [
        DefaultInfo(
            files = depset([out]),
        ),
        ApkoConfigInfo(
            files = depset(direct_deps, transitive = apko_depsets),
        ),
    ]

apko_config = rule(
    implementation = _apko_config_impl,
    attrs = {
        "include": attr.label(allow_single_file = True),
        "config": attr.label(allow_single_file = True),
        "_config_template": attr.label(default = ":apko_config.tmpl.sh", allow_single_file = True),
    },
)
