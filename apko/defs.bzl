"Public API re-exports"

load("//apko/private:apko_image.bzl", _apko_image = "apko_image")
load("//apko/private/range:bazelrc.bzl", _apko_bazelrc = "apko_bazelrc")

apko_image = _apko_image
apko_bazelrc = _apko_bazelrc
