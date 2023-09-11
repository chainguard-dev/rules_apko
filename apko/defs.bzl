"Public API re-exports"

load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("//apko/private:apko_image.bzl", _apko_image = "apko_image")

apko_image = _apko_image

def apko_bazelrc(name = "apko_bazelrc", **kwargs):
    if native.package_name() != "":
        fail("apko_bazelrc() should only be called from the root BUILD file.")
    write_source_files(
        name = name,
        files = {
            ".apko/.bazelrc.apko": "@rules_apko//apko/private/range:range.bazelrc",
            ".apko/range.sh": "@rules_apko//apko/private/range:range.sh",
        },
        **kwargs
    )
