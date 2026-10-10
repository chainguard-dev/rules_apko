# Bazel rules for apko

Wraps the https://github.com/chainguard-dev/apko tool for use under Bazel.

Need help? This ruleset has support provided by <https://aspect.dev>.

## Installation

Follow instructions in the release notes from the release you wish to use.
<https://github.com/chainguard-dev/rules_apko/releases>

To use a commit rather than a release, you can point at any SHA of the repo,
using the GitHub-provided source archive like
`https://github.com/chainguard-dev/rules_apko/archive/abc123.tar.gz``

> [!NOTE]  
> Note that GitHub source archives don't have a strong guarantee on the sha256 stability.
> See https://github.blog/2023-02-21-update-on-the-future-stability-of-source-code-archives-and-hashes/

## Usage

Apko usage begins with an `apko.yaml` configuration file. The `apko lock` tool will create a corresponding
`apko.lock.json` file, and this is where Bazel will read to fetch external content.
Assuming `rules_apko` is already loaded in your `MODULE.bazel` or `WORKSPACE` file one can call:
`bazel run @rules_apko//apko -- lock ./apko.yaml` to lock the dependencies and generate `apko.lock.json` file.

Then you import these base layers into Bazel:

- With [bzlmod], call `apk.translate_lock` in `MODULE.bazel`
- Otherwise, call `translate_apko_lock` in `WORKSPACE`

Now you can use the `apko_image` rule to build the image, producing an OCI format output.
As long as the apko `.yaml` file is in the same directory as the `apko_image` you can periodically refresh the
`apko.lock.json` file by just calling: `bazel run path/to/image.lock`.
Alternatively you can call `apko lock path/to/apko.yaml` or `bazel run @rules_apko//apko lock path/to/apko.yaml`
to regenerate the `apko.lock.json` file manually.
To resolve all the files in the repository, such a [snippet](./examples/lock.sh) can be useful.

Finally, we recommend using <https://github.com/bazel-contrib/rules_oci> as the next step in your Bazel build
to add application code from your repo as the next layers of the image.

See the examples folder in this repository, which relies on base layers declared in `/MODULE.bazel`.

Also see the `e2e` folder in this repository, where we declare our end-to-end test.

## Fetching and Caching Contents

To ensure efficient operation, the `apko_image` rule must maintain a cache of remote contents that it fetches from repositories. While outside of Bazel, `apko` manages its own cache, under Bazel, the cache must be maintained by Bazel to ensure correctness and speed. Therefore, Bazel needs to know what needs to be fetched and from where to cache these HTTP requests and provide them to `apko` as required.

The `apko.lock.json` file contains all the necessary information about how to perform the HTTP fetches required by `apko` to build the container image.

### Generating the Lock File

> **Note:** Documentation for lockfile generation will be added once the `apko lock` command is available.

### Using `translate_lock`

Having just the `apko/lock.json` file alone is insufficient; all the information needs to be converted into `apk_<content_type>` repository calls to make them accessible to Bazel. The `translate_lock` tool accomplishes this by taking the `apko.lock.json` file and dynamically generating the required Bazel repositories.

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
apk = use_extension("@rules_apko//apko:extensions.bzl", "apko")

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

## Public API

The API reference is generated from the sources and rendered on the Bazel
Central Registry: <https://registry.bazel.build/modules/rules_apko/latest/docs>

- `translate_lock` Repository rules for translating `apko.lock.json`
- `apko_image` Build OCI images from APK packages directly without `Dockerfile`

See [Fetching and Caching Contents](#fetching-and-caching-contents) for how
contents are fetched and cached.
