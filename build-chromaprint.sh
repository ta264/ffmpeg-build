#!/usr/bin/env bash

: ${OS?}
: ${ARCH?}

set -eux

cd $(dirname $0)
BASE_DIR=$(pwd)

source common.sh

if [ ! -e $CHROMAPRINT_TARBALL ]
then
	wget $CHROMAPRINT_TARBALL_URL
fi

TMP_BUILD_DIR=$BASE_DIR/$(mktemp -d build.XXXXXXXX)
trap 'rm -rf $TMP_BUILD_DIR' EXIT

cd $TMP_BUILD_DIR
tar --strip-components=1 -xf $BASE_DIR/$CHROMAPRINT_TARBALL

export FFMPEG_DIR=$BASE_DIR/ffmpeg-$FFMPEG_VERSION-audio-$OS-$ARCH

CMAKE_ARGS=(
    -DCMAKE_INSTALL_PREFIX=$BASE_DIR/chromaprint-$OS-$ARCH
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_TOOLS=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_SHARED_LIBS=ON
)

STRIP=strip

case $OS in
windows)
    perl -pe "s!{EXTRA_PATHS}!$FFMPEG_DIR!g" package/toolchain-mingw.cmake.in | perl -pe "s!{ARCH}!$ARCH!g" >toolchain.cmake
    CMAKE_ARGS+=(
        -DCMAKE_TOOLCHAIN_FILE=$TMP_BUILD_DIR/toolchain.cmake
    )
    ;;
macos)
    ;;
linux)
    case $ARCH in
    i686)
        CMAKE_ARGS+=(
            -DCMAKE_C_FLAGS='-m32'
            -DCMAKE_CXX_FLAGS='-m32'
        )
        ;;
    x86_64|armhf)
        ;;
    *)
        echo "unsupported architecture ($ARCH)"
        exit 1
    esac
    ;;
*)
    echo "unsupported OS ($OS)"
    exit 1
    ;;
esac

cmake "${CMAKE_ARGS[@]}" $TMP_BUILD_DIR

make VERBOSE=1
make install VERBOSE=1

case $OS in
windows)
    zip -r $BASE_DIR/chromaprint-$OS-$ARCH.zip $BASE_DIR/chromaprint-$OS-$ARCH
    ;;
*)
    tar -zcvf $BASE_DIR/chromaprint-$OS-$ARCH.tar.gz $BASE_DIR/chromaprint-$OS-$ARCH
    ;;
esac
