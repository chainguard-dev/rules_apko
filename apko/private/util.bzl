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

def _url_escape(url):
    """Replace reserved characters with their percent-encoded values"""
    for char, encoded_value in _reserved_chars.items():
        url = url.replace(char, encoded_value)

    return url

def _repo_url(url, arch):
    """Returns the base url for a given apk url

    For example, given `https://dl-cdn.alpinelinux.org/alpine/edge/main/x86_64/APKINDEX.tar.gz`
    it returns `https://dl-cdn.alpinelinux.org/alpine/edge/main`

    Args:
        url: full url
        arch: arch string
    Returns:
        base url for the url
    """
    arch_index = url.find("{}/".format(arch))
    if arch_index != -1:
        return url[0:arch_index - 1]
    return url

def _sanitize_string(string):
    """Sanitizes a string to be a valid workspace name

    workspace names may contain only A-Z, a-z, 0-9, '-', '_' and '.'

    Args:
        string: unsanitized workspace string
    Returns:
        a valid workspace string
    """

    result = ""
    for i in range(0, len(string)):
        c = string[i]
        if c == "@" and (not result or result[-1] == "_"):
            result += "at"
        if not c.isalnum() and c != "-" and c != "_" and c != ".":
            c = "_"
        result += c
    return result

def _parse_lock(content):
    return json.decode(content)

def _normalize_sri(rctx, checksum):
    """Converts SRI string to a plain checksum hex.

    Args:
        rctx: repository_ctx
        checksum: SRI string
    Returns:
        normalized checksum hex
    """
    checksum = checksum.split("-", 1)[1]
    p = rctx.path("sri.sh")
    rctx.file(p, """echo "$1" | base64 -d | xxd -p -c 10000000 | tr -d '\\n'""", executable = True)
    r = rctx.execute([p, checksum])
    if r.return_code != 0:
        fail("""normalize_sri failed.\nstderr: {}\nstdout: {}""".format(r.stdout, r.stderr))
    return r.stdout

# TODO: this shouldn't be necessary in the first place. change apko so that it except to find the original apk in the cache
def _concatenate_gzip_segments(rctx, output, signature, control, data):
    """concatenates gzip segments into one gzip file in signature, control, data order

    Args:
        rctx: repository_ctx
        output: final output path
        signature: path to the signature segment
        control: path to the control segment
        data: path to the data segment
    Returns:
        None
    """
    p = rctx.path("gzip_seg.sh")
    rctx.file(p, """cat $2 $3 $4 > $1""", executable = True)
    r = rctx.execute([p, output, signature, control, data])
    if r.return_code != 0:
        fail("""concatenate_gzip_segments failed.\nstderr: {}\nstdout: {}""".format(r.stdout, r.stderr))

util = struct(
    concatenate_gzip_segments = _concatenate_gzip_segments,
    normalize_sri = _normalize_sri,
    parse_lock = _parse_lock,
    sanitize_string = _sanitize_string,
    repo_url = _repo_url,
    url_escape = _url_escape,
)
