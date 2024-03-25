"""Internal functions to parse versions."""

# Taken from https://github.com/bazel-contrib/bazel_features/blob/main/private/parse.bzl
# We can't use bazel_features because it requires two loads and macro calls in the WORKSPACE
# file but rules_apko users make one load and two macro calls where marcros exported from
# the same file which makes it not possible to add bazel_features to `repositories.bzl` file
# and load from it in the repositories.bzl file.
#
# TODO(2.0): depend on bazel_features directly by splitting the repositories.bzl file into two.
# https://github.com/chainguard-dev/rules_apko/issues/55

def _safe_int(s, v):
    if not s.isdigit():
        fail("invalid Bazel version '{}': non-numeric segment '{}'".format(v, s))
    return int(s)

def _partition(s):
    for i in range(len(s)):
        c = s[i]
        if c == "-":
            return s[:i], s[i + 1:]
        if not c.isdigit() and c != ".":
            return s[:i], s[i:]
    return s, ""

def parse_version(v):
    """Parses the given Bazel version string into a comparable value.

    Args:
      v (str): version string

    Returns:
      a triple ([major, minor, patch], is_released, prerelease)
    """
    if not v:
        # An empty string is treated as a "dev version", which is greater than anything.
        v = "999999.999999.999999"
    release, prerelease = _partition(v.partition(" ")[0])
    segments = release.split(".")
    if len(segments) != 3:
        fail("invalid Bazel version '{}': got {} dot-separated segments, want 3".format(v, len(segments)))
    return [_safe_int(s, v) for s in segments], not prerelease, prerelease

def bazel_version_gte(version):
    return parse_version(native.bazel_version) >= parse_version(version)
