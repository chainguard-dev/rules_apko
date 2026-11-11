"A test rule that checks whether an apko lock file is up to date with its config."

load("//apko/private:apko_config.bzl", "ApkoConfigInfo")

_DOC = """
apko_lock_test fails when the lock file is stale, i.e. was not generated from the current version of the config.

`apko lock` records a checksum of the config in the lock file, and `apko build` refuses a lock file whose checksum
does not match the config. This test performs the same check as a `bazel test` target, so lock drift is reported by
`bazel test //...` without building any image, downloading any packages or accessing the network.

The checksum covers the config file and every file it pulls in through `include`, so changing any of them makes
the lock stale. Include paths are resolved relative to the workspace root, the same way `apko_lock` resolves them.

```starlark
apko_lock_test(
    name = "lock_test",
    config = "apko.yaml",
    lockfile = "apko.lock.json",
)
```

The test uses the `yq` and `coreutils` toolchains from `aspect_bazel_lib`. They are registered automatically with
bzlmod; in WORKSPACE mode call `register_yq_toolchains()` and `register_coreutils_toolchains()` from
`@aspect_bazel_lib//lib:repositories.bzl`.
"""

_ATTRS = {
    "config": attr.label(
        doc = """Label to the `apko.yaml` file the lock file was generated from.
For multi-file configuration, use a target providing `ApkoConfigInfo` (e.g. output of `apko_config` rule).""",
        allow_single_file = True,
        mandatory = True,
    ),
    "lockfile": attr.label(
        doc = "Label to the `apko.lock.json` file to check.",
        allow_single_file = True,
        mandatory = True,
    ),
    "update_target": attr.string(
        doc = "Label of the target that regenerates the lock file (e.g. an `apko_lock` target). Mentioned in the failure message.",
    ),
}

_LAUNCHER_TEMPLATE = """#!/usr/bin/env sh

set -eu

yq_bin='{{yq}}'
coreutils='{{coreutils}}'
config='{{config}}'
lockfile='{{lockfile}}'
update_hint='{{update_hint}}'

fail() {
    echo "ERROR: $1" >&2
    echo "Regenerate the lock file with $update_hint." >&2
    exit 1
}

# JSON is valid YAML, so yq reads the lock file as YAML as well. Both formats are
# explicit because newer yq versions guess them from the file extension.
yq() {
    "$yq_bin" --input-format=yaml --output-format=yaml "$@"
}

expected="$(yq '.config.checksum // ""' "$lockfile")"
if [ -z "$expected" ]; then
    fail "$lockfile does not record the checksum of its config, so it cannot be checked."
fi

# apko computes the checksum over the bytes of the config followed by the bytes
# of each file it includes, in include order. See ImageConfiguration.parse in
# https://github.com/chainguard-dev/apko/blob/main/pkg/build/types/image_configuration.go
set -- "$config"
file="$config"
while :; do
    include="$(yq '.include // ""' "$file")"
    if [ -z "$include" ]; then
        break
    fi
    if [ ! -f "$include" ]; then
        echo "ERROR: cannot find $include, included from $file." >&2
        echo "Pass the config as an apko_config target that lists the included files in its deps." >&2
        exit 1
    fi
    set -- "$@" "$include"
    file="$include"
done

hex="$("$coreutils" cat "$@" | "$coreutils" sha256sum | "$coreutils" cut -d ' ' -f 1)"
actual="sha256-$(printf '%s' "$hex" | "$coreutils" tr 'a-f' 'A-F' | "$coreutils" basenc --base16 --decode | "$coreutils" base64)"

if [ "$actual" != "$expected" ]; then
    fail "$lockfile is out of date with $config: the lock file records config checksum $expected, but the config's checksum is $actual."
fi
"""

def _impl(ctx):
    launcher = ctx.actions.declare_file("_{}_test.sh".format(ctx.label.name))
    yq_bin = ctx.toolchains["@aspect_bazel_lib//lib:yq_toolchain_type"].yqinfo.bin
    coreutils_bin = ctx.toolchains["@aspect_bazel_lib//lib:coreutils_toolchain_type"].coreutils_info.bin

    if ctx.attr.update_target:
        update_hint = "`bazel run {}`".format(ctx.attr.update_target)
    else:
        update_hint = "`apko lock` (or by running the matching `apko_lock` target)"

    ctx.actions.write(
        output = launcher,
        content = _LAUNCHER_TEMPLATE
            .replace("{{yq}}", yq_bin.short_path)
            .replace("{{coreutils}}", coreutils_bin.short_path)
            .replace("{{config}}", ctx.file.config.short_path)
            .replace("{{lockfile}}", ctx.file.lockfile.short_path)
            .replace("{{update_hint}}", update_hint),
        is_executable = True,
    )

    transitive_data = []
    if ApkoConfigInfo in ctx.attr.config:
        transitive_data.append(ctx.attr.config[ApkoConfigInfo].files)

    return DefaultInfo(
        executable = launcher,
        runfiles = ctx.runfiles(
            files = [yq_bin, coreutils_bin, ctx.file.lockfile],
            transitive_files = depset(ctx.files.config, transitive = transitive_data),
        ),
    )

apko_lock_test = rule(
    implementation = _impl,
    attrs = _ATTRS,
    doc = _DOC,
    test = True,
    toolchains = [
        "@aspect_bazel_lib//lib:coreutils_toolchain_type",
        "@aspect_bazel_lib//lib:yq_toolchain_type",
    ],
)
