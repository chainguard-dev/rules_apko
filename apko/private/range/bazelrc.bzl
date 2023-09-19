"helper macros for .bazelrc generation"

load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@bazel_skylib//rules:expand_template.bzl", "expand_template")

DEFAULT_REPOSITORIES = [
    "dl-cdn.alpinelinux.org",
    "packages.wolfi.dev",
]

COMMON_TMPL = """\
common --credential_helper="{}=%workspace%/.apko/range.sh"
"""

def apko_bazelrc(name = "apko_bazelrc", repositories = DEFAULT_REPOSITORIES, **kwargs):
    """Helper macro for generating `.bazelrc` and `range.sh` files to allow for partial package fetches.

    See [initial setup](./initial-setup.md) documentation for more information.

    Args:
        name: name of the target
        repositories: list of repositories to generate .bazelrc for
        **kwargs: passed to expanding targets. only well known attributes such as `tags` `testonly` ought to be present.
    """
    if native.package_name() != "":
        fail("apko_bazelrc() should only be called from the root BUILD file.")

    expand_template(
        name = "{}_bazelrc".format(name),
        out = "{}.bazelrc".format(name),
        substitutions = {
            "{common_entries}": "".join([
                COMMON_TMPL.format(repo)
                for repo in repositories
            ]),
        },
        template = "@rules_apko//apko/private/range:range.bazelrc",
        **kwargs
    )
    write_source_files(
        name = name,
        files = {
            ".apko/.bazelrc": "{}_bazelrc".format(name),
            ".apko/range.sh": "@rules_apko//apko/private/range:range.sh",
        },
        **kwargs
    )
