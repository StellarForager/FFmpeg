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
if [ -n "$CROSS_COMPILE_PKG_SUFFIX" ]; then
  if [ "$CROSS_COMPILE_PKG_SUFFIX" = "mingw-w64-aarch64" ]; then
    wget https://github.com/mstorsjo/llvm-mingw/releases/download/20241001/llvm-mingw-20241001-msvcrt-ubuntu-20.04-x86_64.tar.xz
    tar -xf llvm-mingw-*.tar.xz
    export PATH="$(realpath "llvm-mingw-*/"):$PATH"
    echo "PATH=$PATH"
  else
    sudo apt-get install \
      --allow-remove-essential --allow-change-held-packages -y \
      "gcc-$CROSS_COMPILE_PKG_SUFFIX" "g++-$CROSS_COMPILE_PKG_SUFFIX"
  fi
fi
