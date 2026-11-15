#!/usr/bin/env bash
# Flatpak's sandbox, for real, in the ci-flatpak image: what its consumers do.
# Needs the container started with `--privileged` (bubblewrap makes namespaces
# and mounts /proc), as root:
#   docker run --rm --privileged -v "$PWD/images/flatpak-sandbox-check.sh:/check.sh:ro" IMAGE bash /check.sh
# It runs VSCodium's Electron as plain Node inside the sandbox, through a
# session bus (`flatpak-spawn --host` talks to the session helper over it), and
# has the sandbox start a program on the "host" (here, the container).
set -euo pipefail

app=com.vscodium.codium
electron=/app/share/codium/com.vscodium.codium
# The runtime directory the image's ENV names; a job may have another HOME.
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo "VSCodium commit: $(cat /etc/ci-flatpak/vscodium-commit)"
echo "runtime commit:  $(cat /etc/ci-flatpak/runtime-commit)"
echo "uid $(id -u), XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"

echo "+ Electron, as Node, in the sandbox"
version=$(dbus-run-session -- flatpak run --command="$electron" --env=ELECTRON_RUN_AS_NODE=1 "$app" \
  -e 'console.log(process.versions.electron)')
echo "electron $version"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] || { echo "FAILED: no Electron version: $version" >&2; exit 1; }

echo "+ the sandbox is not the container, and reaches it through flatpak-spawn --host"
marker=$(mktemp /usr/local/bin/sandbox-check.XXXXXX)
trap 'rm -f "$marker"' EXIT
dbus-run-session -- flatpak run --command=sh "$app" -c '
  set -eu
  echo "inside the sandbox: $FLATPAK_ID"
  test ! -e "$1" || { echo "FAILED: $1 is visible in the sandbox" >&2; exit 1; }
  flatpak-spawn --host test -e "$1"
  echo "the host sees it"
' sh "$marker"
echo "sandbox check passed"
