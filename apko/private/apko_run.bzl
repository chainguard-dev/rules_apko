"A rule for running apko - convenience layer to stay within consistent versions."

_ATTRS = {
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
if test "${BUILD_WORKING_DIRECTORY+x}"; then
  cd $BUILD_WORKING_DIRECTORY
fi

echo "Workdir: ${PWD}" >&2
${LAUNCHER_DIR}/{{apko_binary}} "${@:1}"
"""

def _impl(ctx):
    output = ctx.actions.declare_file("_{}_run.sh".format(ctx.label.name))
    apko_info = ctx.toolchains["@rules_apko//apko:toolchain_type"].apko_info

    ctx.actions.write(output = output, content = LAUNCHER_TEMPLATE.replace("{{apko_binary}}", apko_info.binary.path), is_executable = True)

    return DefaultInfo(executable = output, runfiles = ctx.runfiles(files = [apko_info.binary]))

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
