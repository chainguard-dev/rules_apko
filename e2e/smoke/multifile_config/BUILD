load("@rules_apko//apko:defs.bzl", "apko_config", "apko_image", "apko_lock")
load("@bazel_skylib//rules:build_test.bzl", "build_test")

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
    config = ":final_config",
    lockfile_name = "apko.generated.lock.json",
)
