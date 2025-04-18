load("@rules_apko//apko:defs.bzl", "apko_config", "apko_image", "apko_lock", "apko_show_config")
load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@aspect_bazel_lib//lib:diff_test.bzl", "diff_test")

apko_config(
    name = "intermediate_config",
    config = ":intermediate_config.apko.yaml",
    deps = [":base_config.apko.yaml"],
)

apko_config(
    name = "final_config",
    config = ":final_config.apko.yaml",
    deps = [":intermediate_config"],
)

apko_image(
    name = "image_from_generated_config",
    config = ":final_config",
    contents = "@example_multifile_lock//:contents",
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
    args = [
        "--log-level=debug",  # illustration that you can pass args to the executables (bazel run) rules
    ],
    config = ":final_config",
    lockfile_name = "apko.generated.lock.json",
    visibility = ["//visibility:private"],  # illustration that you can control visibility.
)

apko_show_config(
    name = "show_config",
    config = "final_config",
)

diff_test(
    name = "show_config_test",
    file1 = ":show_config",
    file2 = "expected_expanded_config.yaml",
)
