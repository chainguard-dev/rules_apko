#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail


# THIS IS A HACKY BASH SCRIPT THAT IS NOT MEANT TO BE USED BY USERS.

# Updates lock file for given a example for missing packages. 
# 
# Runs bazel build <example_folder> and tries to add package entries for missing packages by
# capturing the error message.
#
# Can be run as ./resolve-all.sh <relative_path_to_the_example>
# 
# Eg: `./resolve-all.sh examples/wolfi-base`

example="$1"
dir="${2:-$1}"
lockfile="$dir/apko.lock.json"

echo "🔗 Lockfile is at $lockfile"
echo ""

output=$(mktemp)

while [ true ]; do
    echo "" > $output
    if ! bazel build $example &> $output; then
        required="$(cat $output | sed -n "s/.*apk\ at\ \(.*\): Get.*/\1/p" | head -1)"
        if [[ -n "$required" ]]; then 
            echo "🥖 Found missing apk $required"

            echo "🥕 Fetching $required"
            resolve=$(mktemp)
            json=$(mktemp)
            if ./resolve.sh $required 2> $json > $resolve; then 
                lock="$(jq --argjson package "$(cat $json | jq -c)" '.contents.packages |= . + [$package]' "$dir/apko.lock.json")"                
                echo "$lock" > "$dir/apko.lock.json"
                echo "👌 Fetched succesfully $(jq -r '.name + "-" + .version + " (" + .architecture + ")"' $json)"
                echo ""
            else
                echo ""
                echo "❗ err"
                echo ""
                cat "$resolve"
                cat "$json"
                exit 1
            fi
        else 
            cat "$output"
            exit 1
        fi
    else
        echo "🙌 All good!"
        exit 0
    fi
done
