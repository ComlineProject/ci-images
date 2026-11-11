#!/bin/sh
# envinfo.sh: print `key=value` lines about the tools in this environment.
# Run from the directory of the project, so rustup resolves its toolchain.
first() { "$@" 2>&1 | head -n 1; }

echo "os=$(. /etc/os-release && echo "$PRETTY_NAME")"
echo "valgrind=$(first valgrind --version)"
glibc=
for f in /lib/x86_64-linux-gnu/libc.so.6 /lib64/libc.so.6 /lib/libc.so.6 /usr/lib/libc.so.6; do
  if [ -e "$f" ]; then glibc=$(first "$f"); break; fi
done
echo "glibc=$glibc"
echo "rustc=$(first rustc --version)"
echo "cargo=$(first cargo --version)"
echo "iai_callgrind_runner=$(iai-callgrind-runner --version 2>&1 | head -n 1 || true)"
echo "gh=$(first gh --version)"
echo "gcc=$(first cc --version)"
echo "python3=$(first python3 --version)"
echo "git=$(first git --version)"
echo "zstd=$(first zstd --version)"
echo "setarch=$(command -v setarch || echo missing)"
if command -v dpkg-query >/dev/null 2>&1; then
  dpkg-query -W -f 'pkg=${Package} ${Version}\n' \
    valgrind libc6 libc6-dbg gcc build-essential git python3 zstd ca-certificates 2>/dev/null || true
elif command -v apk >/dev/null 2>&1; then
  apk list -I 2>/dev/null \
    | grep -E '^(valgrind|glibc|glibc-dev|gcc|build-base|git|gh|python-3[^ ]*|zstd|ca-certificates-bundle|binutils|make)-[0-9]' \
    | sed 's/ .*//; s/^/pkg=/' || true
elif [ -r /etc/nix-packages ]; then
  # The nix variant: its image has no package manager; the flake writes the
  # names of the packages it was built from.
  sed 's/^/pkg=/' /etc/nix-packages
fi
