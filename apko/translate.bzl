load("//apko/private:yaml.bzl", "parse")

def parse_lock(content):
    return json.decode(content)


def _apk_impl(rctx):
    output = "{}/{}-{}.apk".format(rctx.attr.architecture, rctx.attr.package_name, rctx.attr.version)
    rctx.download(
        url = ["{}#APK_RANGE={}".format(rctx.attr.url, rctx.attr.signature_range)],
        output = "{}/{}.sig.tar.gz".format(output, rctx.attr.control_checksum.replace("sha1-", "")),
    )
    rctx.download(
        url = ["{}#APK_RANGE={}".format(rctx.attr.url, rctx.attr.control_range)],
        output = "{}/{}.ctl.tar.gz".format(output, rctx.attr.control_checksum.replace("sha1-", "")),
    )
    rctx.download(
        url = ["{}#APK_RANGE={}".format(rctx.attr.url, rctx.attr.data_range)],
        output = "{}/{}.dat.tar.gz".format(output, rctx.attr.data_checksum),
        sha256 = rctx.attr.data_checksum,
    )
    rctx.file("BUILD.bazel", 
"""filegroup(
    name = "archive", 
    srcs = glob(["**/*.tar.gz"]),
    visibility = ["//visibility:public"]
)
""")


apk_import = repository_rule(
    implementation = _apk_impl,
    attrs={
        "package_name": attr.string(mandatory=True),
        "version": attr.string(mandatory=True),
        "architecture": attr.string(mandatory=True),
        "url": attr.string(mandatory=True),
        "signature_range": attr.string(mandatory=True),
        "signature_checksum": attr.string(mandatory=True),
        "control_range": attr.string(mandatory=True),
        "control_checksum": attr.string(mandatory=True),
        "data_range": attr.string(mandatory=True),
        "data_checksum": attr.string(mandatory=True),
    }
)



def _impl(rctx):
    lock_raw = rctx.read(rctx.attr.lock)
    lock = json.decode(lock_raw)
    rctx.file("BUILD.bazel", 
"""filegroup(
    name = "packages", 
    srcs = {},
    visibility = ["//visibility:public"]
)
""".format([
        "@{}_{}_{}//:archive".format(package["name"], package["architecture"], package["version"]) 
        for package in lock["packages"]
    ])
)
    pass



translate_apko_lock = repository_rule(
    implementation = _impl,
    attrs={
        "lock": attr.label(mandatory=True)
    }
)
