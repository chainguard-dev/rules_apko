# Initial setup

rules_apko requires a one-time setup to configure bazel to be able to make partial fetches.

> See the issue: https://github.com/bazelbuild/bazel/issues/17829

Paste this into your root BUILD file

```py
load("@rules_apko//apko:defs.bzl", "apko_bazelrc")

apko_bazelrc()
```

Then run

```sh
bazel run @@//:apko_bazelrc && chmod +x .apko/range.sh
```

And finally paste this into your preferred \`.bazelrc\` file,

```sh
# Required for rules_apko to make range requests
try-import %workspace%/.apko/.bazelrc
```