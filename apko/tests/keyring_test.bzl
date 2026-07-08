"""Unit tests for the apk_keyring local-key lookup helpers.

See https://bazel.build/rules/testing#testing-starlark-utilities
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apko/private:apk.bzl", "apk_private_for_testing")

_keyring_filename = apk_private_for_testing.keyring_filename
_cache_path_from_url = apk_private_for_testing.cache_path_from_url

def _keyring_filename_test_impl(ctx):
    env = unittest.begin(ctx)

    # Wolfi-style keyring: filename is the final path segment.
    asserts.equals(
        env,
        "wolfi-signing.rsa.pub",
        _keyring_filename("https://packages.wolfi.dev/os/wolfi-signing.rsa.pub"),
    )

    return unittest.end(env)

def _cache_path_from_url_test_impl(ctx):
    env = unittest.begin(ctx)

    # RSA public keys are nested in a directory named after the full filename,
    # so a local key file round-trips to the same on-disk cache location that a
    # downloaded copy would use.
    asserts.equals(
        env,
        "https%3A%2F%2Fpackages.wolfi.dev%2F/os/wolfi-signing.rsa.pub/wolfi-signing.rsa.pub",
        _cache_path_from_url("https://packages.wolfi.dev/os/wolfi-signing.rsa.pub"),
    )

    return unittest.end(env)

# The unittest library requires that we export the test cases as named test rules,
# but their names are arbitrary and don't appear anywhere.
_keyring_filename_test = unittest.make(_keyring_filename_test_impl)
_cache_path_from_url_test = unittest.make(_cache_path_from_url_test_impl)

def keyring_test_suite(name):
    unittest.suite(
        name,
        _keyring_filename_test,
        _cache_path_from_url_test,
    )
