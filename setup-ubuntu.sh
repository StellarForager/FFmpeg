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
  gawk \
  libtool \
  pkg-config
if [ -n "$CROSS_COMPILE" ]; then
  if [ "CROSS_COMPILE" = "aarch64-w64-mingw" ]; then
    wget https://github.com/mstorsjo/llvm-mingw/releases/download/20241001/llvm-mingw-20241001-msvcrt-ubuntu-20.04-x86_64.tar.xz
    tar -xf llvm-mingw-*.tar.xz
    export PATH="$(realpath "llvm-mingw-*/"):$PATH"
  else
    apt-get \
      --allow-remove-essential --allow-change-held-packages -y \
      "gcc-$CROSS_COMPILE" "g++-$CROSS_COMPILE"
  fi
fi
