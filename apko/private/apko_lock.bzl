"""Rule for generating apko locks."""

load("//apko/private:apko_config.bzl", "ApkoConfigInfo")
load("@bazel_skylib//lib:paths.bzl", "paths")

_ATTRS = {
    "config": attr.label(allow_single_file = True),
    "lockfile_name": attr.string(),
}

_DOC = """
apko_lock generates the lock file based on the provided config.
"""

LAUNCHER_TEMPLATE = """
#!#!/usr/bin/env sh

set -e

config={{config}}
output={{output}}

{{apko_binary}} lock $config --output=${BUILD_WORKSPACE_DIRECTORY}/${output} "${@}"
"""

def _impl(ctx):
    output = ctx.actions.declare_file("_{}_run.sh".format(ctx.label.name))
    apko_info = ctx.toolchains["@rules_apko//apko:toolchain_type"].apko_info

    ctx.actions.write(
        output = output,
        content = LAUNCHER_TEMPLATE
            .replace("{{apko_binary}}", apko_info.binary.short_path)
            .replace("{{config}}", ctx.file.config.short_path)
            .replace("{{output}}", ctx.attr.lockfile_name),
        is_executable = True,
    )

    transitive_data = []
    if ApkoConfigInfo in ctx.attr.config:
        transitive_data.append(ctx.attr.config[ApkoConfigInfo].files)

    return DefaultInfo(
        executable = output,
        runfiles = ctx.runfiles(
            files = [apko_info.binary] + depset(ctx.files.config, transitive = transitive_data).to_list(),
        ),
    )

_apko_lock = rule(
    implementation = _impl,
    attrs = _ATTRS,
    doc = _DOC,
    executable = True,
    toolchains = ["@rules_apko//apko:toolchain_type"],
)

def apko_lock(name, config, lockfile_name, **kwargs):
    """Generates executable rule for producing apko lock files.

    When run, the rule will output the lockfile to the lockfile_name in the directory of the package where the rule is defined.
    That is, if you define `apko_lock` in `foo/bar/BUILD.bazel` with `lockfile_name="baz.lock.json` the rule will output the lock into
    `foo/bar/baz.lock.json`.

    Args:
        name: name of the rule,
        config: label of the apko config. It can be either a source file or generated target. Additionally, if the target provides ApkoConfigInfo provider,
            the transitive dependencies listed in ApkoConfigInfo.files will be added to runfiles as well.
        lockfile_name: name of the lockfile
        **kwargs: the rule inherits standard attributes, like: tags, visibility, and args.
    """
    config_label = native.package_relative_label(config)
    _apko_lock(
        name = name,
        config = config,
        lockfile_name = paths.join(config_label.package, lockfile_name),
        **kwargs
    )
