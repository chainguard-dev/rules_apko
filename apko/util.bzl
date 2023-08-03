"utility functions"

# Define the list of reserved characters and their percent-encoded values
_reserved_chars = {
    " ": "%20",
    "!": "%21",
    '"': "%22",
    "#": "%23",
    "$": "%24",
    "%": "%25",
    "&": "%26",
    "'": "%27",
    "(": "%28",
    ")": "%29",
    "*": "%2A",
    "+": "%2B",
    ",": "%2C",
    "/": "%2F",
    ":": "%3A",
    ";": "%3B",
    "<": "%3C",
    "=": "%3D",
    ">": "%3E",
    "?": "%3F",
    "@": "%40",
    "[": "%5B",
    "\\": "%5C",
    "]": "%5D",
    "^": "%5E",
    "`": "%60",
    "{": "%7B",
    "|": "%7C",
    "}": "%7D",
    "~": "%7E",
}

def url_escape(url):
    # Replace reserved characters with their percent-encoded values
    for char, encoded_value in _reserved_chars.items():
        url = url.replace(char, encoded_value)

    return url

def repo_url(url, arch):
    arch_index = url.find("{}/".format(arch))
    if arch_index != -1:
        return url[0:arch_index - 1]
    return url
