"""Unit tests for `apko/private/util.bzl` helpers."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//apko/private:util.bzl", "util")

def _apk_namespace_known_hosts_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "wolfi",
        util.apk_namespace("https://packages.wolfi.dev/os/x86_64/foo-1.0.apk"),
    )
    asserts.equals(
        env,
        "chainguard",
        util.apk_namespace("https://packages.cgr.dev/extras/x86_64/bar-1.0.apk"),
    )
    asserts.equals(
        env,
        "alpine",
        util.apk_namespace("https://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/musl-1.2.5-r11.apk"),
    )
    return unittest.end(env)

def _apk_namespace_unknown_host_falls_back_to_alpine_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "alpine",
        util.apk_namespace("https://mirror.example.test/v3.21/main/x86_64/foo-1.0.apk"),
    )
    return unittest.end(env)

def _apk_namespace_override_wins_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(
        env,
        "corp",
        util.apk_namespace(
            "https://mirror.corp.example/v3.21/main/x86_64/foo-1.0.apk",
            {"mirror.corp.example": "corp"},
        ),
    )

    # Override on a known host wins over the built-in default.
    asserts.equals(
        env,
        "custom-wolfi",
        util.apk_namespace(
            "https://packages.wolfi.dev/os/x86_64/foo-1.0.apk",
            {"packages.wolfi.dev": "custom-wolfi"},
        ),
    )
    return unittest.end(env)

_apk_namespace_known_hosts_test = unittest.make(_apk_namespace_known_hosts_test_impl)
_apk_namespace_unknown_host_falls_back_to_alpine_test = unittest.make(_apk_namespace_unknown_host_falls_back_to_alpine_test_impl)
_apk_namespace_override_wins_test = unittest.make(_apk_namespace_override_wins_test_impl)

def util_test_suite(name):
    unittest.suite(
        name,
        _apk_namespace_known_hosts_test,
        _apk_namespace_unknown_host_falls_back_to_alpine_test,
        _apk_namespace_override_wins_test,
    )
