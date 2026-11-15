#!/bin/sh
# flatpak-install.sh: the Flatpak half of the ci-flatpak image. Run at build
# time, as root, with the Flathub remote file at /dl/flathub.flatpakrepo (hash-
# checked) and the ARGs of the Dockerfile in the environment:
#
#   VSCODIUM_REF, VSCODIUM_COMMIT   the app, and the exact build of it
#   RUNTIME_REF,  RUNTIME_COMMIT    its runtime, and the exact build of it
#
# Installed by the latest Flathub has, then moved to the exact commit with
# `flatpak update --commit` (Flathub keeps the history of a ref), and the
# commits nobody refers to any more are pruned. The commit is what the image
# holds, whatever Flathub's current build is. (ostree's own `pull REF@COMMIT`
# would fetch the commit directly, but Flathub answers 403 to the `ostree`
# client's user agent: only flatpak's is let through.) A SYSTEM installation
# (/var/lib/flatpak), so every uid sees it and nothing depends on a home
# directory. No dependencies or related extensions: the base app is part of the
# app's files already, and GL, locale and codecs are for windows the image never
# opens. What varies from one build to the next (caches, summaries, appstream
# data) is removed: see "Reproducible builds" in images/versions.md.
set -eu

: "${VSCODIUM_REF:?}" "${VSCODIUM_COMMIT:?}" "${RUNTIME_REF:?}" "${RUNTIME_COMMIT:?}"
repo=/var/lib/flatpak/repo

flatpak remote-add --system flathub /dl/flathub.flatpakrepo

install_pinned() {
  ref=$1 commit=$2
  # NAME/ARCH/BRANCH, which every flatpak command takes.
  name=${ref#*/}
  flatpak install --system --noninteractive --assumeyes --no-deps --no-related flathub "$name"
  flatpak update --system --noninteractive --assumeyes --no-deps --no-related --commit="$commit" "$name"
  have=$(flatpak info --system --show-commit "$name")
  [ "$have" = "$commit" ] || { echo "installed $ref is $have, not $commit" >&2; exit 1; }
}
install_pinned "$RUNTIME_REF" "$RUNTIME_COMMIT"
install_pinned "$VSCODIUM_REF" "$VSCODIUM_COMMIT"

# The latest builds the installs started from: no ref points at them now.
ostree --repo="$repo" prune --refs-only --depth=0
ostree --repo="$repo" refs

flatpak list --system --columns=ref,commit,installation

# What a job logs, and what the smoke test compares to the labels.
mkdir -p /etc/ci-flatpak
printf '%s\n' "$VSCODIUM_COMMIT" > /etc/ci-flatpak/vscodium-commit
printf '%s\n' "$RUNTIME_COMMIT" > /etc/ci-flatpak/runtime-commit

# Not part of the installation, and not the same twice: ostree's cache of the
# remote's summary and its temporary files, flatpak's lock files.
rm -rf "$repo"/tmp/* "$repo"/.lock /var/lib/flatpak/.changed /var/tmp/flatpak-cache-* 2> /dev/null || true
