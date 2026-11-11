#!/bin/sh
# fetch.sh URL SHA256 DEST: download URL to DEST and fail unless it hashes to SHA256.
set -eu
url=$1 sha256=$2 dest=$3
curl -fsSL --retry 5 --retry-all-errors --retry-delay 5 -o "$dest" "$url"
echo "$sha256  $dest" | sha256sum -c -
