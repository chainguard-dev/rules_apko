"""Provides a simple way to test your rules as an external workspace."""

load("@rules_apko//apko:defs.bzl", "apko_bazelrc", "apko_image")
load("@bazel_skylib//rules:build_test.bzl", "build_test")

apko_bazelrc()

apko_image(
    name = "lock",
    config = "apko.yaml",
    packages = "@example_lock//:packages",
    tag = "lock:latest",
)

build_test(
    name = "test",
    targets = [
        ":lock",
    ],
)
