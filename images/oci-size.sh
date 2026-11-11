#!/usr/bin/env bash
# oci-size.sh IMAGE.tar: the compressed size, in bytes, of the layers of the
# (first) image in an OCI archive: what a pull transfers.
set -euo pipefail
tarball=$1
blob() { tar -xOf "$tarball" "blobs/${1%%:*}/${1#*:}"; }
digest=$(tar -xOf "$tarball" index.json | jq -r '.manifests[0].digest')
manifest=$(blob "$digest")
while jq -e '.manifests' <<< "$manifest" > /dev/null; do
  manifest=$(blob "$(jq -r '.manifests[0].digest' <<< "$manifest")")
done
jq '[.layers[].size] | add' <<< "$manifest"
