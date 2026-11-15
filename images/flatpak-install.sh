#!/bin/sh
# flatpak-install.sh: the Flatpak half of the ci-flatpak image. Run at build
# time, as root, with the Flathub remote file at /dl/flathub.flatpakrepo (hash-
# checked) and the ARGs of the Dockerfile in the environment:
#
#   VSCODIUM_REF, VSCODIUM_COMMIT   the app, and the exact build of it
#   RUNTIME_REF,  RUNTIME_COMMIT    its runtime, and the exact build of it
#
# Both are pulled by commit (`ostree pull REMOTE REF@COMMIT`, signature-checked
# against Flathub's key like any pull) and then installed from that local copy,
# so the image holds what the ARGs say whatever Flathub's current build is. A
# SYSTEM installation (/var/lib/flatpak), so every uid sees it and nothing
# depends on a home directory. No dependencies or related extensions (the base
# app is part of the app's files already; GL, locale and codecs are for windows
# the image never opens). What varies from one build to the next (caches,
# summaries, appstream data) is removed: see "Reproducible builds" in
# images/versions.md.
set -eu

: "${VSCODIUM_REF:?}" "${VSCODIUM_COMMIT:?}" "${RUNTIME_REF:?}" "${RUNTIME_COMMIT:?}"
repo=/var/lib/flatpak/repo

flatpak remote-add --system flathub /dl/flathub.flatpakrepo

pull_and_install() {
  ref=$1 commit=$2
  ostree --repo="$repo" pull flathub "$ref@$commit"
  flatpak install --system --noninteractive --assumeyes --no-pull --no-deps --no-related flathub "$ref"
  have=$(flatpak info --system --show-commit "${ref#*/}")
  [ "$have" = "$commit" ] || { echo "installed $ref is $have, not $commit" >&2; exit 1; }
}
pull_and_install "$RUNTIME_REF" "$RUNTIME_COMMIT"
pull_and_install "$VSCODIUM_REF" "$VSCODIUM_COMMIT"

flatpak list --system --columns=ref,commit,installation

# What a job logs, and what the smoke test compares to the labels.
mkdir -p /etc/ci-flatpak
printf '%s\n' "$VSCODIUM_COMMIT" > /etc/ci-flatpak/vscodium-commit
printf '%s\n' "$RUNTIME_COMMIT" > /etc/ci-flatpak/runtime-commit

# Not part of the installation, and not the same twice: ostree's cache of the
# remote's summary and its temporary files, flatpak's lock files.
rm -rf "$repo"/tmp/* "$repo"/.lock /var/lib/flatpak/.changed /var/tmp/flatpak-cache-* 2> /dev/null || true
