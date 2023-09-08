#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

apk="$TMPDIR/$(echo $1 | base64)"

if [[ ! -f "$apk" ]]; then
    curl -fsSL $1 -o $apk
fi

streams=($(cat $apk | xxd -p -c0 | grep -b -o "1f8b" | cut -d":" -f1 | awk '{print $1/=2}' | awk '{print int($1+0.5)}')) 

function extract_section () {
    local input_file=$1
    local start_offset=$2
    local end_offset=$3
    if [[ -z "${end_offset}" ]]; then
        tail -c +"$((start_offset + 1))" "$input_file"
    else 
        local length=$((end_offset - start_offset + 1))
        # Use head to skip to the start offset and tail to extract the section
        head -c "$end_offset" "$input_file" | tail -c +"$((start_offset + 1))"
    fi
}


sig_begin="${streams[0]}"
control_begin="${streams[1]}"
data_begin="${streams[2]}"
control_len=$(($data_begin-$control_begin))

echo ""
echo "@ sanity check"
echo ""
t=$(mktemp -t "t1")
t2=$(mktemp -t "t2")

extract_section $apk $sig_begin $control_begin >> $t
curl -fsSL $1 -H "Range: bytes=$sig_begin-$(($control_begin-1))" >> $t2
wc -c $t $t2
diffoscope $t $t2

extract_section $apk $control_begin $data_begin >> $t
curl -fsSL $1 -H "Range: bytes=$control_begin-$(($data_begin-1))" >> $t2
wc -c $t $t2
diffoscope $t $t2

extract_section $apk $data_begin "" >> $t
curl -fsSL $1 -H "Range: bytes=$data_begin-" >> $t2
wc -c $t $t2
diffoscope $t $t2


echo ""
echo "@ sections"
echo ""

echo "-> sig"
echo ""
extract_section $apk $sig_begin $control_begin | tar -tf  -

echo ""
echo "-> control"
echo ""
extract_section $apk $control_begin $data_begin | tar -tf  - 

echo ""
echo "-> data"
echo ""
extract_section $apk $data_begin "" | tar -tf  -


echo ""
echo "@ gather info"
echo ""
info=$(extract_section $apk $control_begin $data_begin | tar -xOz - .PKGINFO)

pkgname=
pkgver=
pkgarch=
sig_sig=$(extract_section $apk $sig_begin $control_begin | shasum -a 256 | cut -d '-' -f 1 | tr -d ' ' | xxd -r -p | base64)
control_sig=$(extract_section $apk $control_begin $data_begin | shasum -a 1 | cut -d '-' -f 1 | tr -d ' ' | xxd -r -p | base64)
data_sig=$(extract_section $apk $data_begin "" | shasum -a 256 | cut -d '-' -f 1 | tr -d ' ' | xxd -r -p | base64)

while IFS=$'\n' read -r line; do
    key=$(echo "$line" | cut -d '=' -f 1 | tr -d ' ')
    value=$(echo "$line" | cut -d '=' -f 2 | tr -d ' ')
    if [[ "$key" == "pkgname" ]]; then 
        pkgname="$value"
    elif [[ "$key" == "pkgver" ]]; then
        pkgver="$value"
    elif [[ "$key" == "arch" ]]; then
        pkgarch="$value"
    fi
done < <(extract_section $apk $control_begin $data_begin | tar -xOz - .PKGINFO) 

echo ""
echo "@ Add this to lock"
echo ""

cat <<EOF
{ 
    "name": "$pkgname", 
    "version": "$pkgver", 
    "architecture": "$pkgarch",
    "url": "$1",
    "signature": { 
        "range": "bytes=$sig_begin-$(($control_begin-1))", 
        "checksum": "sha256-$sig_sig"
    },
    "control": { 
        "range": "bytes=$control_begin-$(($data_begin-1))", 
        "checksum": "sha1-$control_sig"
    },
    "data": { 
        "range": "bytes=$data_begin-", 
        "checksum": "sha256-$data_sig"
    }
}
EOF