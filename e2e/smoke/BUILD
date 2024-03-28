"""Provides a simple way to test your rules as an external workspace."""

load("@rules_apko//apko:defs.bzl", "apko_bazelrc", "apko_image")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

apko_bazelrc()

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

copy_file(
    name = "generated_config",
    src = ":apko.yaml",
    out = "apko.generated.yaml",
)

apko_image(
    name = "lock_from_generated",
    config = ":apko.generated.yaml",
    contents = "@example_lock//:contents",
    tag = "lock:latest",
)
