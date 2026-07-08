# local keyring e2e

This e2e proves that `apk_keyring` serves a public key from a local key file's
contents instead of downloading it.

The keyring in [`apko.lock.json`](./apko.lock.json) points at an unreachable
`.invalid` host, so the [`build_test`](./BUILD) can only pass if the key is
resolved from the local key file contents at
[`//keys/rules-apko-e2e-local.rsa.pub`](./keys), wired in via
`apko.translate_lock(local_keys = "//keys:BUILD.bazel")` in
[`MODULE.bazel`](./MODULE.bazel). If the local-key branch regresses to a network
download, this build fails.
