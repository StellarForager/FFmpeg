#!/usr/bin/env sh

sudo apt update
sudo apt-get \
  --allow-remove-essential -y install \
  build-essential curl tar pkg-config
sudo apt-get \
  --allow-remove-essential -y install \
  autoconf \
  automake \
  build-essential \
  file \
  gawk \
  libtool \
  pkg-config
if [ -n "$CROSS_COMPILE" ]; then
  apt-get \
    --allow-remove-essential --allow-change-held-packages -y \
    "gcc-$CROSS_COMPILE" "g++-$CROSS_COMPILE"
fi
