#!/usr/bin/env bash
set -o nounset -o pipefail


example=$1

output=$(mktemp)

while [ true ]; do
    echo "" > $output
    bazel build $example &> $output
    if [ $? -ne 0 ]; then
        required="$(cat $output | sed -n "s/.*apk\ at\ \(.*\): Get.*/\1/p" | head -1)"
        if [[ -n "$required" ]]; then 
            echo "🥖 Found missing apk $required"

            echo "🥕 Fetching $required"
            json=$(./resolve.sh $required 2>&1 > /dev/null | jq -c)
            lock="$(jq --argjson package "$json" '.contents.packages |= . + [$package]' "$example/apko.lock.json")"

            echo "$lock" > "$example/apko.lock.json"
            echo "👌 $required"
            echo ""
        else 
            cat "$output"
            exit 1
        fi
    else
        echo "🥖 🙌 All good!"
        exit 0
    fi
    sleep 1
done
