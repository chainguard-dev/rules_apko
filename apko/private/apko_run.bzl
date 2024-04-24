"A rule for running apko - convenience layer to stay within consistent versions."

load("//apko/private:image_config.bzl", "ApkoConfigInfo")

_WORKDIR_DOC = """
  The dir where apko will get executed:
    - working - the dir where bazel was called.
    - workspace - the root directory of the bazel workspace (usually repository root)"""

_DATA_DOC = """
  Any files that will be used for the apko run
"""

_ATTRS = {
    "workdir": attr.string(default = "working", doc = _WORKDIR_DOC, mandatory = False, values = ["working", "workspace"]),
    "data": attr.label_list(allow_files = True, doc = _DATA_DOC),
}

_DOC = """
apko_run is used internally to defune @rules_apko//apko target that allows to run an apko tool in the version supplied by Bazel.

Thanks to this, `bazel run @rules_apko//apko {flags}` can be called, without need to download/install apko outside of Bazel.
The workdir of the running command is the directory from which bazel has been called.
"""

LAUNCHER_TEMPLATE = """
#!#!/usr/bin/env sh

set -e
LAUNCHER_DIR="${PWD}"
if test "${{{workdir_env}}+x}"; then
  cd ${{workdir_env}}
fi

echo "Workdir: ${PWD}" >&2
${LAUNCHER_DIR}/{{apko_binary}} "${@:1}"
"""

def _impl(ctx):
    output = ctx.actions.declare_file("_{}_run.sh".format(ctx.label.name))
    apko_info = ctx.toolchains["@rules_apko//apko:toolchain_type"].apko_info

    ctx.actions.write(
        output = output,
        content = LAUNCHER_TEMPLATE
            .replace("{{apko_binary}}", apko_info.binary.path)
            .replace("{{workdir_env}}", "BUILD_" + ctx.attr.workdir.upper() + "_DIRECTORY"),
        is_executable = True,
    )

    additional_files = []
    for data in ctx.attr.data:
        if ApkoConfigInfo in data:
            additional_files += data[ApkoConfigInfo].files.to_list()

    return DefaultInfo(
        executable = output,
        files = depset(ctx.files.data + additional_files),
        runfiles = ctx.runfiles(
            files = [apko_info.binary],
        ),
    )

apko_run_lib = struct(
    attrs = _ATTRS,
    documentation = _DOC,
    implementation = _impl,
    toolchains = ["@rules_apko//apko:toolchain_type"],
)

apko_run = rule(
    implementation = apko_run_lib.implementation,
    attrs = apko_run_lib.attrs,
    toolchains = apko_run_lib.toolchains,
    doc = apko_run_lib.documentation,
    executable = True,
)
