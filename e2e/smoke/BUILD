"""Provides a simple way to test your rules as an external workspace."""

load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_apko//apko:defs.bzl", "apko_image", "apko_lock_test")

apko_image(
    name = "lock",
    config = ":apko.yaml",
    contents = "@example_lock//:contents",
    tag = "lock:latest",
)

build_test(
    name = "test",
    targets = [
        ":lock",
    ],
)

apko_lock_test(
    name = "lock_test",
    config = ":apko.yaml",
    lockfile = ":apko.lock.json",
)
