"""Provider that serves as an API for adding any files needed for apko build"""

ApkoConfigInfo = provider(
    doc = "Information about apko config. May be used when generating apko config file instead of using hardcoded ones.",
    fields = {
        "files": "depset of files that will be needed for building.",
    },
)
