"""Provides a simple way to test your rules as an external workspace."""

load("@aspect_bazel_lib//lib:testing.bzl", "assert_contains")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_apko//apko:defs.bzl", "apko_image")

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

# apko_image adds a `.lock` target next to it because apko.lock.json sits next to apko.yaml.
# `bazel run` executes it from the workspace root, so for a config in the root package the
# lock file has to be written to a workspace-relative path, not to the filesystem root.
genquery(
    name = "lock_target_query",
    expression = "//:lock.lock",
    opts = ["--output=build"],
    scope = [":lock.lock"],
)

assert_contains(
    name = "lock_target_output_test",
    actual = ":lock_target_query",
    expected = "\"--output=apko.lock.json\"",
)
