# Fetching and Caching Contents

To ensure efficient operation, the `apko_image` rule must maintain a cache of remote contents that it fetches from repositories. While outside of Bazel, `apko` manages its own cache, under Bazel, the cache must be maintained by Bazel to ensure correctness and speed. Therefore, Bazel needs to know what needs to be fetched and from where to cache these HTTP requests and provide them to `apko` as required.

The `apko.lock.json` file contains all the necessary information about how to perform the HTTP fetches required by `apko` to build the container image.

## Generating the Lock File

> **Note:** Documentation for lockfile generation will be added once the `apko resolve` command is available.

## Using `translate_lock`

Having just the `apko.lock.json` file alone is insufficient; all the information needs to be converted into `apk_<content_type>` repository calls to make them accessible to Bazel. The `translate_lock` tool accomplishes this by taking the `apko.lock.json` file and dynamically generating the required Bazel repositories.

`translate_lock` will create a new bazel repository named after itself. this repository will also have a target named contents, which you can pass to apko_image:

```starlark
apko_image(
    name = "lock",
    config = "apko.yaml",
    # name of the repository is the same translate_lock!
    contents = "@examples_lock//:contents",
    tag = "lock:latest",
)
```

#### Usage with `bzlmod`

```starlark
apk = use_extension("//apko:extensions.bzl", "apko")

apk.translate_lock(
    name = "examples_lock",
    lock = "//path/to/lock:apko.lock.json",
)
use_repo(apk, "examples_lock")
```

#### Usage with Workspace

```starlark
load("@rules_apko//apko:translate_lock.bzl", "translate_apko_lock")

translate_apko_lock(
    name = "example_lock",
    lock = "//path/to/lock:apko.lock.json",
)

load("@example_lock//:repositories.bzl", "apko_repositories")

apko_repositories()
```