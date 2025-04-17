#!/usr/bin/env sh

uname -m | grep -qE 'x86|i386|i686' && is_x86=1 || is_x86=0

if [ `uname -s` = "Darwin" ]; then
  brew install wget
elif grep -qE 'debian|ubuntu' /etc/os-release; then
  sudo apt update
  sudo apt-get \
    --allow-remove-essential -y install \
    autoconf automake build-essential curl gawk libtool pkg-config tar
  if [ "$CROSS_COMPILE_PKG_SUFFIX" = "mingw-w64-aarch64" ] && [ $is_x86 -eq 1 ]; then
    wget https://github.com/mstorsjo/llvm-mingw/releases/download/20250417/llvm-mingw-20250417-msvcrt-ubuntu-20.04-x86_64.tar.xz
    tar -xf llvm-mingw-*.tar.xz
    export PATH="$(realpath "llvm-mingw-*/"):$PATH"
  elif [ -n "$CROSS_COMPILE_PKG_SUFFIX" ]; then
    sudo apt-get install \
      --allow-remove-essential --allow-change-held-packages -y \
      "gcc-$CROSS_COMPILE_PKG_SUFFIX" "g++-$CROSS_COMPILE_PKG_SUFFIX"
  fi
elif grep -qE 'fedora' /etc/os-release; then
  sudo dnf -y groupinstall "Development Tools"
  sudo dnf -y install \
    autoconf automake curl gawk glibc-devel glibc-static \
    libtool pkgconf-pkg-config tar
fi
