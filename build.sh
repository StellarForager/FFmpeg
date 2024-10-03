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
OS=`uname -s`
ARCH=${ARCH:-`uname -m`}
PLATFORM=${PLATFORM:-"unknown"}

[ "$PLATFORM" = "unknown" ] && case $OS in
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
[ $is_x86 -ne 1 ] && echo "Not using yasm or nasm on non-x86 PLATFORM..."

# CROSS_COMPILE="aarch64-linux-gnu"
CROSS_COMPILE=${CROSS_COMPILE:-""}
[ -n "$CROSS_COMPILE" ] &&
  CC="${CROSS_COMPILE}-gcc" \
  CXX="${CROSS_COMPILE}-g++" \
  AR="${CROSS_COMPILE}-ar" \
  RANLIB="${CROSS_COMPILE}-ranlib" \
  STRIP="${CROSS_COMPILE}-strip"

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

VER_YASM=${VER_YASM:-"1.3.0"}
VER_NASM=${VER_NASM:-"2.16.03"}
VER_OPENSSL=${VER_OPENSSL:-"3.3.2"}
VER_FDKAAC=${VER_FDKAAC:-"0.1.6"}
VER_FFMPEG=${VER_FFMPEG:-"7.1"}

#this is our working directory
cd $BUILD_DIR

if [ $is_x86 -eq 1 ]; then
  case "$PLATFORM" in
    'darwin')
      download \
        "yasm-$VER_YASM.tar.gz" \
        "" \
        "nil" \
        "http://www.tortall.net/projects/yasm/releases/"
      ;;
    'linux'|'mingw32')
      download \
        "nasm-$VER_NASM.tar.bz2" \
        "" \
        "nil" \
        "https://www.nasm.us/pub/nasm/releasebuilds/$VER_NASM/"
      ;;
  esac
fi

# download \
#   "openssl-$VER_OPENSSL.tar.gz" \
#   "" \
#   "nil" \
#   "https://github.com/openssl/openssl/archive/"

download \
  "x264-stable.tar.gz" \
  "" \
  "nil" \
  "https://code.videolan.org/videolan/x264/-/archive/stable/"

# download \
#   "fdk-aac-free-$VER_FDKAAC.tar.gz" \
#   "fdk-aac.tar.gz" \
#   "nil" \
#   "https://github.com/Pairman/Xdcheckin-FFmpeg/releases/download/0.0.0/"

download \
  "ffmpeg-$VER_FFMPEG.tar.xz" \
  "" \
  "nil" \
  "https://ffmpeg.org/releases/"

[ $download_only -eq 1 ] && exit 0

TARGET_DIR_SED=$(echo $TARGET_DIR | awk '{gsub(/\//, "\\/"); print}')

if [ $is_x86 -eq 1 ]; then
  case "$PLATFORM" in
    'darwin')
      echo "*** Building yasm ***"
      cd $BUILD_DIR/yasm*
      ;;
    'linux'|'mingw32')
      echo "*** Building nasm ***"
      cd $BUILD_DIR/nasm*
      ;;
  esac
  [ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
  [ ! -f config.status ] && \
  ./configure --prefix=$TARGET_DIR --bindir=$BIN_DIR
  make -j $jval
  make install
fi

# echo "*** Building OpenSSL ***"
# cd $BUILD_DIR/openssl*
# [ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
#   PATH="$BIN_DIR:$PATH" CFLAGS="-Os -fPIC" CXXFLAGS="-Os -fPIC" LDFLAGS="-Wl,-s" ./Configure \
#   $([ "$PLATFORM" = "darwin" ] && echo "darwin64-$ARCH-cc") \
#   $([ ! "$PLATFORM" = "darwin" ] && echo "$PLATFORM-$ARCH") \
#   $([ -n "$CROSS_COMPILE" ] && echo "--cross-compile-prefix=$CROSS_COMPILE") \
#   --prefix=$TARGET_DIR --libdir=lib \
#   no-shared no-dso no-ssl3 no-psk no-tests \
#   no-md2 no-md4 no-rc2 no-rc4 no-rc5 no-idea \
#   no-whirlpool no-seed no-deprecated no-err \
#   no-comp no-srp no-weak-ssl-ciphers
# PATH="$BIN_DIR:$PATH" CFLAGS="-Os -fPIC" CXXFLAGS="-Os -fPIC" LDFLAGS="-Wl,-s" make -j $jval
# make install_sw

echo "*** Building x264 ***"
cd $BUILD_DIR/x264*
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
[ ! -f config.status ] && \
  PATH="$BIN_DIR:$PATH" CFLAGS="-Os" CXXFLAGS="-Os" LDFLAGS="-Wl,-s" ./configure \
  $([ -n "$CROSS_COMPILE" ] && echo "--host=${CROSS_COMPILE}") \
  $([ -n "$CROSS_COMPILE" ] && echo "--cross-prefix=${CROSS_COMPILE}-") \
  --prefix=$TARGET_DIR --enable-static --enable-strip --enable-pic --disable-opencl \
  $([ "$PLATFORM" = "mingw32" ] && echo " --disable-win32thread")
PATH="$BIN_DIR:$PATH" make -j $jval
make install

# echo "*** Building fdk-aac-free ***"
# cd $BUILD_DIR/fdk-aac*
# [ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
# autoreconf -fiv
# [ ! -f config.status ] && \
#   CFLAGS="-Os" CXXFLAGS="-Os" LDFLAGS="-Wl,-s" ./configure \
#   $([ -n "$CROSS_COMPILE" ] && echo "--host=${CROSS_COMPILE}") \
#   --prefix=$TARGET_DIR --disable-shared --enable-static --with-pic 
# make -j $jval
# make install

echo "*** Building FFmpeg ***"
cd $BUILD_DIR/ffmpeg*
# patch -p1 < "$ENV_ROOT/0000-ffmpeg-fdk-acc-free.patch"
[ $rebuild -eq 1 -a -f Makefile ] && make distclean || true
[ ! -f config.status ] && \
  PATH="$BIN_DIR:$PATH" \
  PKG_CONFIG_PATH="$TARGET_DIR/lib/pkgconfig:$TARGET_DIR/lib64/pkgconfig$([ "$PLATFORM" = "darwin" ] && \
  echo ":/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/local/Cellar/openssl@3/${VER_OPENSSL}_1/lib/pkgconfig")" \
  ./configure \
  --arch="$ARCH" \
  --target-os="$PLATFORM" \
  $([ "$PLATFORM" = "darwin" ] && echo "--cc=/usr/bin/clang") \
  $([ -n "$CROSS_COMPILE" ] && echo "--cross-prefix=${CROSS_COMPILE}-") \
  $([ -n "$CROSS_COMPILE" ] && echo "--enable-cross-compile") \
  $([ -n "$CROSS_COMPILE" ] && echo "--pkg-config=pkg-config") \
  --prefix="$TARGET_DIR" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$TARGET_DIR/include -Os" \
  --extra-cxxflags="-I$TARGET_DIR/include -Os" \
  --extra-ldflags="-L$TARGET_DIR/lib -Wl,-s $([ "$PLATFORM" = "mingw32" ] && echo "-static")" \
  --extra-libs="$([ "$PLATFORM" = "linux" ] && echo "-lpthread -lm")" \
  --extra-ldexeflags="$([ "$PLATFORM" = "linux" ] && echo "-static")$([ "$PLATFORM" = "darwin" ] && echo "-Bstatic")" \
  --bindir="$BIN_DIR" \
  --disable-everything \
  --disable-manpages \
  --disable-doc \
  $([ "$PLATFORM" = "mingw32" ] && echo " --disable-w32threads") \
  $([ "$PLATFORM" = "mingw32" ] && echo " --disable-autodetect") \
  --enable-pic \
  --enable-static \
  --enable-gpl \
  --enable-version3 \
  --enable-libx264 \
  --enable-demuxer=hls \
  --enable-demuxer=rtsp \
  --enable-demuxer=h264 \
  --enable-decoder=h264 \
  --enable-parser=h264 \
  --enable-encoder=mjpeg \
  --enable-muxer=image2 \
  --enable-protocol=pipe \
  --enable-protocol=tcp \
  --enable-protocol=http
#   --enable-openssl \
#   --enable-libfdk-aac \
#   --enable-decoder=aac \
#   --enable-parser=aac \
#   --enable-muxer=mp4 \
#   --enable-protocol=file \
#   --enable-protocol=udp \
#   --enable-protocol=https \
#   --enable-protocol=rtmp \
#   --enable-protocol=rtmps
PATH="$BIN_DIR:$PATH" make -j $jval

hash -r
cd "$ENV_ROOT"
