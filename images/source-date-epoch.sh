#!/bin/sh
# source-date-epoch.sh [DOCKERFILE]: print the build timestamp of the images,
# as Unix seconds: the date of DEBIAN_SNAPSHOT in the Dockerfile. It is the
# value of SOURCE_DATE_EPOCH, and the only place the images' timestamps come
# from, so it moves when (and only when) the snapshot does.
set -eu
dockerfile=${1:-"$(dirname "$0")/Dockerfile"}
snapshot=$(sed -n 's/^ARG DEBIAN_SNAPSHOT=\([0-9TZ]*\)$/\1/p' "$dockerfile")
case $snapshot in
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z) ;;
  *) echo "no DEBIAN_SNAPSHOT (YYYYMMDDTHHMMSSZ) in $dockerfile" >&2; exit 1 ;;
esac
iso=$(printf '%s' "$snapshot" | sed 's/^\(....\)\(..\)\(..\)T\(..\)\(..\)\(..\)Z$/\1-\2-\3 \4:\5:\6/')
epoch=$(date -u -d "$iso" +%s)
# rewrite-timestamp only lowers mtimes: a file made before the epoch keeps the
# time it was made at, and the digest then depends on the clock.
if [ "$epoch" -gt "$(date -u +%s)" ]; then
  echo "DEBIAN_SNAPSHOT $snapshot is in the future: builds would not be reproducible" >&2
  exit 1
fi
echo "$epoch"
