""""""

load("//apko/private:apko_run.bzl", "apko_run")

def apko_lock(name, config, lockfile_name):
    config_label = native.package_relative_label(config)

    package_prefix = config_label.package + "/" if config_label.package else ""
    apko_run(
        name = name,
        # args is subject to make variables substitution: https://bazel.build/reference/be/common-definitions#common-attributes-binaries
        args = ["lock", "$(execpath {})".format(config), "--output={}{}".format(package_prefix, lockfile_name)],
        workdir = "workspace",
        data = [config],
    )
