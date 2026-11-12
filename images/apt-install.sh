#!/bin/sh
# apt-install.sh PACKAGE...: install packages from the sources of the image
# (the date-pinned snapshot) and leave behind nothing that differs from one
# build to the next: no package lists, no download cache, no logs (they hold
# the build's clock), no ldconfig or debconf cache, no compiled Python.
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update -o APT::Update::Error-Mode=any
apt-get install -y --no-install-recommends "$@"
rm -rf /var/lib/apt/lists/*
# Files only: the directories belong to packages.
find /var/cache/apt /var/log -type f -delete
rm -f /var/cache/ldconfig/aux-cache /var/cache/debconf/*-old
# Byte-compiled Python (python3's postinst writes it) records the time of the
# build; Python writes it again, where it can, when a module is imported.
find /usr /etc /var -name '*.pyc' -delete
find /usr /etc /var -name __pycache__ -type d -empty -delete
