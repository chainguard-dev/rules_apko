"""E2E test: apk_keyring serves local key file contents instead of downloading.

The keyring URL in apko.lock.json points at an unreachable ".invalid" host, so
building the keyring can only succeed if it is served from the key file contents
at //keys/rules-apko-e2e-local.rsa.pub (wired via local_keys). If the local-key
branch of apk_keyring regresses (and it falls back to downloading), this build
fails.
"""

load("@bazel_skylib//rules:build_test.bzl", "build_test")

build_test(
    name = "test",
    targets = [
        "@local_keyring_lock//:contents",
    ],
)
