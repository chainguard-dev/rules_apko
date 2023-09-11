echo -n '{"headers":{"Range":[' &&
cat | sed -n 's/.*#__rules_apko_range__=\(bytes=[[:digit:]]*-[[:digit:]]*\).*/"\1"/p' | tr -d '\n' &&
echo -n ']}'