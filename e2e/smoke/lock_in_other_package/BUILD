"""Test apko_image with a config that has no lock file next to it.

The lock for this config lives in the parent package (the config is a byte-for-byte
copy of //:apko.yaml, so its checksum matches the one recorded in //:apko.lock.json).
apko_image only adds a companion `.lock` target when it finds a lock file next to
the config, and must not fail to load when there is none.
"""

load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_apko//apko:defs.bzl", "apko_image")

apko_image(
    name = "image",
    config = "apko.yaml",
    contents = "@example_lock//:contents",
    tag = "lock:latest",
)

build_test(
    name = "test",
    targets = [
        ":image",
    ],
)
