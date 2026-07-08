"""Test that keyring bytes embedded in the lockfile are used without hitting the URL.

The lockfile in this package points at an unreachable host but embeds the keyring
content inline. If the URL is ever fetched, the build fails; if the content path
is used, the build succeeds.
"""

load("@bazel_skylib//rules:build_test.bzl", "build_test")

build_test(
    name = "keyring_content_test",
    targets = ["@keyring_content_lock//:contents"],
)
