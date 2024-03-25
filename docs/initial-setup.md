# Initial setup

You can skip initial setup if you are using Bazel 7.1 or above. Users who are still Bazel 6.x should perform this one time initial setup.
If you have already performed this initial setup but have already upgraded to Bazel >=7.1, you can revert changes proposed by this document.

rules_apko requires a one-time setup to configure bazel to be able to make partial fetches.

Paste this into your root BUILD file

```py
load("@rules_apko//apko:defs.bzl", "apko_bazelrc")

apko_bazelrc()
```

> NOTE: by default `apko_bazelrc` will generate `.bazelrc` to accomodate for fetching from  `dl-cdn.alpinelinux.org` and `packages.wolfi.dev`. this can be configured by passing the `repositories` attribute to `apko_bazelrc()` call.

Then run

```sh
bazel run @@//:apko_bazelrc && chmod +x .apko/range.sh
```

And finally paste this into your preferred \`.bazelrc\` file,

```sh
# Required for rules_apko to make range requests
try-import %workspace%/.apko/.bazelrc
```