#!/bin/bash

sudo apt update
sudo apt-get install build-essential curl tar pkg-config
sudo apt-get -y --force-yes install \
  autoconf \
  automake \
  build-essential \
  cmake \
  gawk \
  libssl-dev \
  libtool \
  pkg-config
[ -n "$CROSS_COMPILE" ] && sudo apt -y --force-yes \
  "gcc-$CROSS_COMPILE" "g++-$CROSS_COMPILE"

./build.sh "$@"

