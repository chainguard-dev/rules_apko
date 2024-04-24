"""Provides a simple way to test your rules as an external workspace."""

load("@rules_apko//apko:defs.bzl", "apko_bazelrc", "apko_image")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load(":apko_config.bzl", "apko_config_example")

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

build_test(
    name = "test_generated_config",
    targets = [
        ":lock_from_generated",
    ],
)

apko_config_example(
    name = "generated_config_with_extra_files",
    config = ":apko.yaml",
)

apko_image(
    name = "image_from_config_with_extra_files",
    config = ":generated_config_with_extra_files",
    contents = "@example_lock//:contents",
    lockfile_basename = "apko.lock.json",
    tag = "lock:latest",
)

build_test(
    name = "test_generated_config_with_extra_files",
    targets = [
        ":image_from_config_with_extra_files",
    ],
)
