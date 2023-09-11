"""Extensions for bzlmod.

Installs a apko toolchain.
Every module can define a toolchain version under the default name, "apko".
The latest of those versions will be selected (the rest discarded),
and will always be registered by rules_apko.

Additionally, the root module can define arbitrarily many more toolchain versions under different
names (the latest version will be picked for each name) and can register them as it sees fit,
effectively overriding the default named toolchain due to toolchain resolution precedence.
"""

load(":repositories.bzl", "apko_register_toolchains")
load(":translate_lock.bzl", "translate_apko_lock")
load("//apko/private:apk.bzl", "apk_import", "apk_repository")
load("//apko/private:util.bzl", "parse_lock", "sanitize_string")

_DEFAULT_NAME = "apko"

apko_toolchain = tag_class(attrs = {
    "name": attr.string(doc = """\
Base name for generated repositories, allowing more than one apko toolchain to be registered.
Overriding the default is only permitted in the root module.
""", default = _DEFAULT_NAME),
    "apko_version": attr.string(doc = "Explicit version of apko.", mandatory = True),
})

apko_translate_lock = tag_class(attrs = {
    "name": attr.string(mandatory = True),
    "lock": attr.label(mandatory = True),
})

def _apko_extension_impl(module_ctx):
    registrations = {}
    for mod in module_ctx.modules:
        for lock in mod.tags.translate_lock:
            lock_file = parse_lock(module_ctx.read(lock.lock))

            for repository in lock_file["repositories"]:
                apk_repository(
                    name = sanitize_string("{}_{}_{}".format(lock.name, repository["name"], repository["architecture"])),
                    url = repository["url"],
                    architecture = repository["architecture"],
                )

            for package in lock_file["packages"]:
                apk_import(
                    name = sanitize_string("{}_{}_{}_{}".format(lock.name, package["name"], package["architecture"], package["version"])),
                    package_name = package["name"],
                    version = package["version"],
                    architecture = package["architecture"],
                    url = package["url"],
                    signature_range = package["signature"]["range"],
                    signature_checksum = package["signature"]["checksum"],
                    control_range = package["control"]["range"],
                    control_checksum = package["control"]["checksum"],
                    data_range = package["data"]["range"],
                    data_checksum = package["data"]["checksum"],
                )

            translate_apko_lock(name = lock.name, target_name = lock.name, lock = lock.lock)

        for toolchain in mod.tags.toolchain:
            if toolchain.name != _DEFAULT_NAME and not mod.is_root:
                fail("""\
                Only the root module may override the default name for the apko toolchain.
                This prevents conflicting registrations in the global namespace of external repos.
                """)
            if toolchain.name not in registrations.keys():
                registrations[toolchain.name] = []
            registrations[toolchain.name].append(toolchain.apko_version)

    for name, versions in registrations.items():
        if len(versions) > 1:
            # TODO: should be semver-aware, using MVS
            selected = sorted(versions, reverse = True)[0]

            # buildifier: disable=print
            print("NOTE: apko toolchain {} has multiple versions {}, selected {}".format(name, versions, selected))
        else:
            selected = versions[0]

        apko_register_toolchains(
            name = name,
            apko_version = selected,
            register = False,
        )

apko = module_extension(
    implementation = _apko_extension_impl,
    tag_classes = {
        "toolchain": apko_toolchain,
        "translate_lock": apko_translate_lock,
    },
)
