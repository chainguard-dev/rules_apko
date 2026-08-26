"""Provides a simple way to test your rules as an external workspace."""

load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_apko//apko:defs.bzl", "apko_image")

apko_image(
    name = "lock",
    config = ":apko.yaml",
    contents = "@example_lock//:contents",
    tag = "lock:latest",
)

# Exercises the hermetic action environment opt-in.
apko_image(
    name = "lock_hermetic_env",
    config = ":apko.yaml",
    contents = "@example_lock//:contents",
    tag = "lock:latest",
    use_default_shell_env = False,
)

build_test(
    name = "test",
    targets = [
        ":lock",
        ":lock_hermetic_env",
    ],
)
