#!/bin/bash

sudo apt update
sudo apt-get -y install \
  build-essential curl tar pkg-config
sudo apt-get -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
  gawk \
  libssl-dev \
  libtool \
  pkg-config
[ -n "$CROSS_COMPILE" ] && sudo apt-get -y \
  "gcc-$CROSS_COMPILE" "g++-$CROSS_COMPILE"

./build.sh "$@"

