"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//apko/private:toolchains_repo.bzl", "PLATFORMS", "toolchains_repo")
load("//apko/private:versions.bzl", "APKO_VERSIONS")

LATEST_APKO_VERSION = APKO_VERSIONS.keys()[0]

def http_archive(name, **kwargs):
    maybe(_http_archive, name = name, **kwargs)

# WARNING: any changes in this function may be BREAKING CHANGES for users
# because we'll fetch a dependency which may be different from one that
# they were previously fetching later in their WORKSPACE setup, and now
# ours took precedence. Such breakages are challenging for users, so any
# changes in this function should be marked as BREAKING in the commit message
# and released only in semver majors.
# This is all fixed by bzlmod, so we just tolerate it for now.
def rules_apko_dependencies():
    # The minimal version of bazel_skylib we require
    http_archive(
        name = "bazel_skylib",
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
        ],
    )

########
# Remaining content of the file is only used to support toolchains.
########
_DOC = "Fetch external tools needed for apko toolchain"
_ATTRS = {
    "apko_version": attr.string(mandatory = True, values = APKO_VERSIONS.keys()),
    "platform": attr.string(mandatory = True, values = PLATFORMS.keys()),
}

def _apko_repo_impl(repository_ctx):
    url = "https://github.com/thesayyn/apko/releases/download/v{version}/apko_{version}_{platform}.tar.gz".format(
        version = repository_ctx.attr.apko_version.lstrip("v"),
        platform = repository_ctx.attr.platform,
    )
    repository_ctx.download_and_extract(
        integrity = APKO_VERSIONS[repository_ctx.attr.apko_version][repository_ctx.attr.platform],
        stripPrefix = "apko_{}_{}".format(
            repository_ctx.attr.apko_version.lstrip("v"),
            repository_ctx.attr.platform,
        ),
        url = url,
    )
    repository_ctx.file(
        "BUILD.bazel",
        """\
# Generated by apko/repositories.bzl
load("@rules_apko//apko:toolchain.bzl", "apko_toolchain")
apko_toolchain(
    name = "apko_toolchain", 
    # After https://github.com/chainguard-dev/apko/issues/827 is fixed,
    # this may need to be conditional so it's "apko.exe" on Windows.
    apko = "apko"
)
""",
    )

apko_repositories = repository_rule(
    _apko_repo_impl,
    doc = _DOC,
    attrs = _ATTRS,
)

# Wrapper macro around everything above, this is the primary API
def apko_register_toolchains(name, apko_version = LATEST_APKO_VERSION, register = True):
    """Convenience macro for users which does typical setup.

    - create a repository for each built-in platform like "apko_linux_amd64" -
      this repository is lazily fetched when node is needed for that platform.
    - create a repository exposing toolchains for each platform like "apko_platforms"
    - register a toolchain pointing at each platform
    Users can avoid this macro and do these steps themselves, if they want more control.
    Args:
        name: base name for all created repos, like "apko1_14"
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users, but false when used under bzlmod extension
        apko_version: version of apko
    """
    for platform in PLATFORMS.keys():
        apko_repositories(
            name = name + "_" + platform,
            platform = platform,
            apko_version = apko_version,
        )
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    toolchains_repo(
        name = name + "_toolchains",
        user_repository_name = name,
    )
