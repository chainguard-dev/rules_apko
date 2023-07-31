#!/usr/bin/env python3

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

if "APK_RANGE" in payload["uri"]:
    parsed=urlparse(payload["uri"])
    headers["Range"] = [parsed.fragment.removeprefix("APK_RANGE=")] 

print(json.dumps({"headers": headers}))