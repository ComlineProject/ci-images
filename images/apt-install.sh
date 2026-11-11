#!/bin/sh
# apt-install.sh PACKAGE...: install packages from the sources of the image
# (the date-pinned snapshot) and leave no package lists behind.
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update -o APT::Update::Error-Mode=any
apt-get install -y --no-install-recommends "$@"
rm -rf /var/lib/apt/lists/*
