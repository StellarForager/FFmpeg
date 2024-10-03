#!/bin/bash

sudo apt update
sudo NEEDRESTART_MODE=a apt-get -y install \
  build-essential curl tar pkg-config
sudo NEEDRESTART_MODE=a apt-get -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
  gawk \
  libssl-dev \
  libtool \
  pkg-config
[ -n "$CROSS_COMPILE" ] && sudo NEEDRESTART_MODE=a apt-get -y \
  "gcc-$CROSS_COMPILE" "g++-$CROSS_COMPILE"
