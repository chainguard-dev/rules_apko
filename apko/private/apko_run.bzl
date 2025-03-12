"A rule for running apko - convenience layer to stay within consistent versions."

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
    "_runfiles_script": attr.label(default = Label("@bazel_tools//tools/bash/runfiles"), allow_single_file = True)
}

_DOC = """
apko_run is used internally to defune @rules_apko//apko target that allows to run an apko tool in the version supplied by Bazel.

Thanks to this, `bazel run @rules_apko//apko {flags}` can be called, without need to download/install apko outside of Bazel.
The workdir of the running command is the directory from which bazel has been called.
"""

LAUNCHER_TEMPLATE = """
#!/usr/bin/env bash
# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${{RUNFILES_DIR:-/dev/null}}/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "${{RUNFILES_MANIFEST_FILE:-/dev/null}}" | cut -f2- -d' ')" 2>/dev/null || \
source "$0.runfiles/$f" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
{{ echo>&2 "ERROR: cannot find $f"; exit 1; }}; f=; set -e
# --- end runfiles.bash initialization v3 ---

set +uo pipefail

apko_binary_file="$(rlocation {apko_binary})"

set -e
echo "Workdir env: {workdir_env}=${workdir_env}" >&2
if [ -n "${workdir_env}" ] ; then
  cd "${workdir_env}"
fi

echo "Workdir: $PWD" >&2
"$apko_binary_file" "${{@:1}}"
"""

def _impl(ctx):
    output = ctx.actions.declare_file("_{}_run.sh".format(ctx.label.name))
    apko_info = ctx.toolchains["@rules_apko//apko:toolchain_type"].apko_info
    ctx.actions.write(
        output = output,
        content = LAUNCHER_TEMPLATE
            .format(
                apko_binary = apko_info.repo + "/apko", 
                workdir_env = "BUILD_" + ctx.attr.workdir.upper() + "_DIRECTORY"
            ),
        is_executable = True,
    )

    return DefaultInfo(
        executable = output,
        files = depset(ctx.files.data),
        runfiles = ctx.runfiles(
            files = [apko_info.binary, ctx.file._runfiles_script],
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
