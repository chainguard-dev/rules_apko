"utility functions"

# Define the list of reserved characters and their percent-encoded values
_reserved_chars = [
    # To avoid double-escaping, percent must be handled before any other replacements.
    ("%", "%25"),
    #
    (" ", "%20"),
    ("!", "%21"),
    ('"', "%22"),
    ("#", "%23"),
    ("$", "%24"),
    ("&", "%26"),
    ("'", "%27"),
    ("(", "%28"),
    (")", "%29"),
    ("*", "%2A"),
    ("+", "%2B"),
    (",", "%2C"),
    ("/", "%2F"),
    (":", "%3A"),
    (";", "%3B"),
    ("<", "%3C"),
    ("=", "%3D"),
    (">", "%3E"),
    ("?", "%3F"),
    ("@", "%40"),
    ("[", "%5B"),
    ("\\", "%5C"),
    ("]", "%5D"),
    ("^", "%5E"),
    ("`", "%60"),
    ("{", "%7B"),
    ("|", "%7C"),
    ("}", "%7D"),
    ("~", "%7E"),
]

def _url_escape(url):
    """Replace reserved characters with their percent-encoded values"""
    for char, encoded_value in _reserved_chars:
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

def _repo_metadata(rctx, reproducible):
    """Reports this repo's reproducibility to the repo contents cache.

    `repository_ctx.repo_metadata` (and the repo contents cache it feeds) is
    only available since Bazel 8.3.0, which is above the minimum Bazel version
    supported by rules_apko. On older Bazels there is no cache to inform, so
    fall back to the implicit None return those versions have always accepted.

    Args:
        rctx: repository_ctx
        reproducible: True if refetching this repo with the same recorded
            inputs is guaranteed to produce the same contents
    Returns:
        a value to return from the repository rule's implementation function
    """
    if not hasattr(rctx, "repo_metadata"):
        return None
    return rctx.repo_metadata(reproducible = reproducible)

_BASE64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
_HEX_DIGITS = "0123456789abcdef"

def _normalize_sri(checksum):
    """Converts SRI string to a plain checksum hex.

    Decoded in Starlark rather than by shelling out: the previous
    `base64 -d | xxd -p` pipeline printed nothing and still exited 0 on hosts
    without xxd, so the returned hex, and the file names built from it,
    depended on the host while the repository was marked reproducible.

    Args:
        checksum: SRI string
    Returns:
        normalized checksum hex
    """
    encoded = checksum.split("-", 1)[1].rstrip("=")
    hex_digits = []
    bits = 0
    bit_count = 0
    for c in encoded.elems():
        value = _BASE64_ALPHABET.find(c)
        if value < 0:
            fail("normalize_sri: invalid base64 in {}".format(checksum))
        bits = (bits << 6) | value
        bit_count += 6
        if bit_count >= 8:
            bit_count -= 8
            byte = (bits >> bit_count) & 0xff
            bits &= (1 << bit_count) - 1
            hex_digits.append(_HEX_DIGITS[byte >> 4] + _HEX_DIGITS[byte & 0xf])
    return "".join(hex_digits)

# TODO: this shouldn't be necessary in the first place. change apko so that it except to find the original apk in the cache
def _concatenate_gzip_segments(rctx, output, control, data, signature = None):
    """concatenates gzip segments into one gzip file in signature, control, data order

    Args:
        rctx: repository_ctx
        output: final output path
        control: path to the control segment
        data: path to the data segment
        signature: path to the signature segment, or None for unsigned apks
    Returns:
        None
    """
    p = rctx.path("gzip_seg.sh")
    rctx.file(p, """out=$1; shift; cat "$@" > "$out" """, executable = True)
    args = [p, output]
    if signature:
        args.append(signature)
    args.append(control)
    args.append(data)
    r = rctx.execute(args)
    if r.return_code != 0:
        fail("""concatenate_gzip_segments failed.\nstderr: {}\nstdout: {}""".format(r.stdout, r.stderr))

util = struct(
    concatenate_gzip_segments = _concatenate_gzip_segments,
    normalize_sri = _normalize_sri,
    parse_lock = _parse_lock,
    repo_metadata = _repo_metadata,
    sanitize_string = _sanitize_string,
    repo_url = _repo_url,
    url_escape = _url_escape,
)
