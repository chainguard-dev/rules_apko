# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

rules_apko is a Bazel ruleset that wraps the [apko](https://github.com/chainguard-dev/apko) tool from Chainguard. It allows building OCI (Open Container Initiative) images from APK packages directly without using Dockerfiles. The ruleset handles fetching and caching remote package contents, managing lockfiles, and providing build rules to integrate apko into Bazel workflows.

## Common Commands

### Building

```bash
# Build a specific apko_image target
bazel build //path/to:target

# Run tests
bazel test //...

# Generate a lock file from an apko.yaml configuration
bazel run @rules_apko//apko lock ./path/to/apko.yaml

# Run a specific lock target
bazel run //path/to:lock_target

# Update all locks in the repo
./scripts/update_locks.sh
```

### Working with Examples

```bash
# Build an example image
bazel build //examples/wolfi-base:wolfi-base

# Test an example
bazel test //examples/wolfi-base:test
```

### Initial Setup (for Bazel 6.x users)

If using Bazel 6.x (not needed for Bazel 7.1+):

```bash
# Generate required .bazelrc file
bazel run @@//:apko_bazelrc && chmod +x .apko/range.sh

# Then add to your .bazelrc file:
# try-import %workspace%/.apko/.bazelrc
```

## Architecture

The rules_apko repository provides several key components:

1. **Translation Layer** (`translate_lock.bzl`): Converts `apko.lock.json` files into Bazel repository rules, making remote package contents available to Bazel builds.

2. **Core Rules**:
   - `apko_image`: Main rule for building container images from APK packages
   - `apko_config`: Allows composing multiple configuration files
   - `apko_lock`: Rule for generating lock files
   - `apko_show_config`: Shows the expanded configuration

3. **Toolchain Resolution**: Ensures the correct version of apko tool is available for builds

4. **Caching System**: Manages fetching and caching of remote package contents used during image builds

### Workflow

The typical workflow for using rules_apko is:

1. Create an `apko.yaml` configuration file defining your image
2. Generate an `apko.lock.json` file using `apko lock` command
3. Use `translate_lock` to make the locked packages available to Bazel
4. Use `apko_image` to build the container image
5. Optionally, use with `rules_oci` to add application code to the image

The lock file contains information about all remote packages needed to build the image, and the translation layer converts these into Bazel repository rules that perform the necessary HTTP fetches.

## Implementation Notes

- The repository uses `bzlmod` extensions for Bazel 6+ but also supports WORKSPACE-based workflows
- The `apko_bazelrc` helper helps configure Bazel for partial package fetches (required for Bazel 6.x)
- For multiarch images, specify the architecture in the `apko_image` rule
- The `apko_config` rule allows composing configurations across multiple files