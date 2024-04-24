"""Provides a simple way to test your rules as an external workspace."""

load("@rules_apko//apko:defs.bzl", "apko_bazelrc", "apko_config", "apko_image", "apko_lock")
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

apko_config(
    name = "apko_config_include",
    include = ":apko.generated.yaml",
)

apko_config(
    name = "apko_config_with_config",
    include = ":apko_config_include",
    config = ":environment_only.apko.yaml",
)

apko_config(
    name = "apko_config",
    config = ":apko_config_with_config",
)

apko_image(
    name = "image_from_generated_config",
    config = ":apko_config",
    contents = "@example_lock//:contents",
    tag = "lock:latest",
)

build_test(
    name = "test_generated_config",
    targets = [
        ":image_from_generated_config",
    ],
)

apko_lock(
    name = "lock_from_generated_config",
    config = ":apko_config",
    lockfile_name = "apko.generated.lock.json",
)
