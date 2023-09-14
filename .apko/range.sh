#!/usr/bin/env bash
echo -n '{"headers":{"Range":['
cat | sed -n 's/.*#_apk_range_bytes_\([[:digit:]]*-[[:digit:]]*\).*/"bytes=\1"/p' | tr -d '\n'
echo ']}}'
