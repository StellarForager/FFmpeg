#!/bin/bash

sudo apt update
sudo NEEDRESTART_MODE=a apt-get \
  --allow-remove-essential --allow-change-held-packages --force-yes -y install \
  build-essential curl tar pkg-config
sudo NEEDRESTART_MODE=a apt-get \
  --allow-remove-essential --allow-change-held-packages --force-yes -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
  gawk \
  libssl-dev \
  libtool \
  pkg-config
[ -n "$CROSS_COMPILE" ] && sudo NEEDRESTART_MODE=a apt-get \
  --allow-remove-essential --allow-change-held-packages --force-yes -y \
  "gcc-$CROSS_COMPILE" "g++-$CROSS_COMPILE"
