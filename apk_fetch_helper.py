#!/usr/bin/env python3

# Adds Range header to requests if the url contains a fragment (#) named "APK_RANGE".
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests
# This is a credential helper called by bazel when making outgoing http requests.
# https://github.com/bazelbuild/proposals/blob/main/designs/2022-06-07-bazel-credential-helpers.md

import sys
import json
import logging.config
import urllib.parse
import subprocess
import base64
import requests
import www_authenticate
from urllib.parse import urlparse

headers = {}

payload = json.loads(sys.stdin.read())

if "__rules_apko_range__" in payload["uri"]:
    parsed=urlparse(payload["uri"])
    headers["Range"] = [parsed.fragment.removeprefix("__rules_apko_range__=")] 


file1 = open("/Users/thesayyn/Documents/rules_apko/test.log", "a")  # append mode
file1.write(json.dumps({"headers": headers, "payload": payload})+"\n")
file1.close()

print(json.dumps({"headers": headers}))