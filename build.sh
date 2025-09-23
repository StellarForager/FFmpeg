#!/usr/bin/env sh

set -e
set -u

jflag=
jval=16
rebuild=0
download_only=0

while getopts 'j:Bd' OPTION
do
  case $OPTION in
  j)
      jflag=1
      jval="$OPTARG"
      ;;
  B)
      rebuild=1
      ;;
  d)
      download_only=1
      ;;
  ?)
      printf "Usage: %s: [-j concurrency_level] (hint: your cores + 20%%) [-B] [-d]\n" $(basename $0) >&2
      exit 2
      ;;
  esac
done
shift $(($OPTIND - 1))

if [ "$jflag" ]
then
  if [ "$jval" ]
  then
    printf "Option -j specified (%d)\n" $jval
  fi
fi

[ "$rebuild" -eq 1 ] && echo "Reconfiguring existing packages..."

cd `dirname $0`
ENV_ROOT=`pwd`
. ./env.source

# check operating system
ARCH=${ARCH:-`uname -m`}
PLATFORM=${PLATFORM:-"unknown"}

[ "$PLATFORM" = "unknown" ] && case `uname -s` in
  'Darwin')
    PLATFORM='darwin'
    ;;
  'Linux')
    PLATFORM='linux'
    ;;
  'CYG'*|'MSYS'*|'MINGW'*)
    PLATFORM='mingw32'
    ;;
esac

echo "$ARCH" | grep -qE 'x86|i386|i686' && is_x86=1 || is_x86=0
echo "$ARCH" | grep -qE 'arm64|aarch64' && is_aarch64=1 || is_aarch64=0
[ $is_x86 -ne 1 ] && echo "Not using nasm on non-x86 PLATFORM..."

if [ "$PLATFORM" = "darwin" ]; then
  if [ $is_x86 -eq 1 ]; then
    export MACOSX_DEPLOYMENT_TARGET="10.9"
  elif [ $is_aarch64 -eq 1 ]; then
    export MACOSX_DEPLOYMENT_TARGET="11.0"
  fi
fi

# CROSS_COMPILE="aarch64-linux-gnu"
CROSS_COMPILE=${CROSS_COMPILE:-""}
if [ "$PLATFORM" = "android" ]; then
  CC="${CROSS_COMPILE}${NDK_API_LEVEL}-clang"
  CXX="${CROSS_COMPILE}${NDK_API_LEVEL}-clang++"
  AR="llvm-ar"
  NM="llvm-nm"
  RANLIB="llvm-ranlib"
  STRIP="llvm-strip"
elif [ -n "$CROSS_COMPILE" ]; then
  CC="${CROSS_COMPILE}-gcc"
  CXX="${CROSS_COMPILE}-g++"
  AR="${CROSS_COMPILE}-ar"
  RANLIB="${CROSS_COMPILE}-ranlib"
  STRIP="${CROSS_COMPILE}-strip"
fi

#if you want a rebuild
rm -rf "$BUILD_DIR" "$TARGET_DIR"
mkdir -p "$BUILD_DIR" "$TARGET_DIR" "$DOWNLOAD_DIR" "$BIN_DIR"

#download and extract package
download(){
  filename="$1"
  if [ ! -z "$2" ];then
    filename="$2"
  fi
  ../download.pl "$DOWNLOAD_DIR" "$1" "$filename" "$3" "$4"
  #disable uncompress
  REPLACE="$rebuild" CACHE_DIR="$DOWNLOAD_DIR" ../fetchurl "http://cache/$filename"
}

echo "#### FFmpeg static build ####"

VER_NASM=${VER_NASM:-"2.16.03"}
VER_FFMPEG=${VER_FFMPEG:-"8.0"}

#this is our working directory
cd $BUILD_DIR

if [ $is_x86 -eq 1 ]; then
  download \
    "nasm-$VER_NASM.tar.bz2" \
    "" \
    "nil" \
    "https://www.nasm.us/pub/nasm/releasebuilds/$VER_NASM/"
fi

download \
  "ffmpeg-$VER_FFMPEG.tar.xz" \
  "" \
  "nil" \
  "https://ffmpeg.org/releases/"

[ $download_only -eq 1 ] && exit 0

TARGET_DIR_SED=$(echo $TARGET_DIR | awk '{gsub(/\//, "\\/"); print}')

if [ $is_x86 -eq 1 ]; then
  echo "*** Building nasm ***"
  cd $BUILD_DIR/nasm*
  [ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
  [ ! -f config.status ] && ./configure --prefix=$TARGET_DIR --bindir=$BIN_DIR
  make -j $jval
  make install
fi

echo "*** Building FFmpeg ***"
cd $BUILD_DIR/ffmpeg*

export PATH="$BIN_DIR:$PATH" 
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
[ ! -f config.status ] && \
  PATH="$BIN_DIR:$PATH" \
  ./configure \
  --arch="$ARCH" \
  --target-os="$PLATFORM" \
  $([ "$PLATFORM" = "darwin" ] && echo "--cc=/usr/bin/clang") \
  $([ "$PLATFORM" = "android" ] && echo "--cc=$CC") \
  $([ "$PLATFORM" = "android" ] && echo "--cxx=$CXX") \
  $([ "$PLATFORM" = "android" ] && echo "--ar=$AR") \
  $([ "$PLATFORM" = "android" ] && echo "--nm=$NM") \
  $([ "$PLATFORM" = "android" ] && echo "--strip=$STRIP") \
  $([ "$PLATFORM" = "android" ] && echo "--ranlib=$RANLIB") \
  $([ -n "$CROSS_COMPILE" ] && echo "--cross-prefix=${CROSS_COMPILE}-") \
  $([ -n "$CROSS_COMPILE" ] && echo "--enable-cross-compile") \
  $([ "$PLATFORM" = "android" ] && echo "--sysroot=$(dirname "$(dirname $(which $CC))")/sysroot") \
  $([ -n "$CROSS_COMPILE" ] && [ "$PLATFORM" != "android" ] && echo "--pkg-config=pkg-config") \
  --prefix="$TARGET_DIR" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$TARGET_DIR/include -Os -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables" \
  --extra-cxxflags="-I$TARGET_DIR/include -Os -ffunction-sections -fdata-sections -fno-asynchronous-unwind-tables -fno-unwind-tables" \
  --extra-ldflags="-L$TARGET_DIR/lib -Wl,-s $([ "$PLATFORM" = "darwin" ] && echo "-dead_strip") $([ "$PLATFORM" != "darwin" ] && echo "-Wl,--build-id=none -Wl,--gc-sections -Wl,--as-needed") $([ "$PLATFORM" = "mingw32" ] && echo "-static")" \
  --extra-libs="$([ "$PLATFORM" = "linux" ] && echo "-lpthread -lm")" \
  --extra-ldexeflags="$([ "$PLATFORM" = "linux" ] && echo "-static")$([ "$PLATFORM" = "darwin" ] && echo "-Bstatic")" \
  --bindir="$BIN_DIR" \
  $([ "$ARCH" = "riscv64" ] && echo "--disable-asm") \
  --disable-manpages \
  --disable-doc \
  --disable-everything \
  --disable-autodetect \
  --disable-network \
  $([ "$PLATFORM" = "mingw32" ] && echo "--disable-w32threads") \
  --enable-static \
  --enable-small \
  --enable-gpl \
  --enable-version3 \
  --enable-demuxer=mpegts \
  --enable-demuxer=h264 \
  --enable-decoder=h264 \
  --enable-parser=h264 \
  --enable-encoder=mjpeg \
  --enable-muxer=image2 \
  --enable-protocol=pipe
PATH="$BIN_DIR:$PATH" make -j $jval

hash -r
cd "$ENV_ROOT"
