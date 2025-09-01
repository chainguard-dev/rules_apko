# Bazel rules for apko

Wraps the https://github.com/chainguard-dev/apko tool for use under Bazel.

Need help? This ruleset has support provided by <https://aspect.dev>.

## Installation

Follow instructions in the release notes from the release you wish to use.
Be sure to follow the "Initial Setup" instructions as well.
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

- With Bazel 6 and [bzlmod], call `apk.translate_lock` in `MODULE.bazel`
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

## Public API

- [translate_lock](./docs/translate_lock.md) Repository rules for translating `apko.lock.json`
- [rules](./docs/rules.md) Build OCI images from APK packages directly without `Dockerfile`
