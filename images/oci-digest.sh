#!/usr/bin/env bash
# oci-digest.sh IMAGE.tar: the digest of the (first) image manifest in an OCI
# archive: what a registry would hold the image under. It does not depend on
# the archive's own tar headers, only on the manifest, so two builds of the
# same image have the same digest exactly when their config and every layer are
# the same bytes.
set -euo pipefail
tarball=$1
blob() { tar -xOf "$tarball" "blobs/${1%%:*}/${1#*:}"; }
digest=$(tar -xOf "$tarball" index.json | jq -r '.manifests[0].digest')
while jq -e '.manifests' <<< "$(blob "$digest")" > /dev/null; do
  digest=$(blob "$digest" | jq -r '.manifests[0].digest')
done
echo "$digest"
