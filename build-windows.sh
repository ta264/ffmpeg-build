#!/usr/bin/env bash

set -eu

cd $(dirname $0)
BASE_DIR=$(pwd)

: ${ARCH?}

source common.sh

## Build zlib
if [ ! -e $ZLIB_TARBALL ]
then
	wget $ZLIB_TARBALL_URL
fi

ZLIB_TARGET=zlib-$ZLIB_VERSION-windows-$ARCH
ZLIB_DIR=$(mktemp -d -p $(pwd) build.XXXXXXXX)
trap 'rm -rf $ZLIB_DIR' EXIT

cd $ZLIB_DIR
tar --strip-components=1 -xf $BASE_DIR/$ZLIB_TARBALL
./configure --prefix=$BASE_DIR/$ZLIB_TARGET --static
make AR=/usr/bin/x86_64-w64-mingw32-ar CC=/usr/bin/x86_64-w64-mingw32-gcc LD=/usr/bin/x86_64-w64-mingw32-ld ARFLAGS=rcs
make install

cd $BASE_DIR
rm -r $ZLIB_DIR

export CPPFLAGS="-I$BASE_DIR/$ZLIB_TARGET/include"
export LDFLAGS="-L$BASE_DIR/$ZLIB_TARGET/lib"

## Build PNG
if [ ! -e $PNG_TARBALL ]
then
	wget $PNG_TARBALL_URL
fi

PNG_TARGET=libpng-$PNG_VERSION-windows-$ARCH
PNG_DIR=$(mktemp -d -p $(pwd) build.XXXXXXXX)
trap 'rm -rf $PNG_DIR' EXIT

cd $PNG_DIR
tar --strip-components=1 -xf $BASE_DIR/$PNG_TARBALL
./configure --host=$ARCH-w64-mingw32 --prefix=$BASE_DIR/$PNG_TARGET --disable-shared --enable-static
make
make install

cd $BASE_DIR
rm -r $PNG_DIR

export CPPFLAGS="$CPPFLAGS -I$BASE_DIR/$PNG_TARGET/include"
export LDFLAGS="$LDFLAGS -L$BASE_DIR/$PNG_TARGET/lib"

## Build Lame
if [ ! -e $LAME_TARBALL ]
then
	wget $LAME_TARBALL_URL
fi

LAME_TARGET=lame-$LAME_VERSION-windows-$ARCH
LAME_DIR=$(mktemp -d -p $(pwd) build.XXXXXXXX)
trap 'rm -rf $LAME_DIR' EXIT

cd $LAME_DIR
tar --strip-components=1 -xf $BASE_DIR/$LAME_TARBALL
./configure --host=$ARCH-w64-mingw32 --prefix=$BASE_DIR/$LAME_TARGET --disable-shared --enable-static
make
make install

cd $BASE_DIR
rm -r $LAME_DIR

export CPPFLAGS="$CPPFLAGS -I$BASE_DIR/$LAME_TARGET/include"
export LDFLAGS="$LDFLAGS -L$BASE_DIR/$LAME_TARGET/lib"

## Build FFmpeg
if [ ! -e $FFMPEG_TARBALL ]
then
	wget $FFMPEG_TARBALL_URL
fi

TARGET=ffmpeg-$FFMPEG_VERSION-audio-windows-$ARCH

BUILD_DIR=$(mktemp -d -p $(pwd) build.XXXXXXXX)
trap 'rm -rf $BUILD_DIR' EXIT

cd $BUILD_DIR
tar --strip-components=1 -xf $BASE_DIR/$FFMPEG_TARBALL

FFMPEG_CONFIGURE_FLAGS+=(
    --prefix=$BASE_DIR/$TARGET
    --extra-cflags='-static -static-libgcc -static-libstdc++'
    --target-os=mingw32
    --arch=$ARCH
    --cross-prefix=$ARCH-w64-mingw32-
)

./configure "${FFMPEG_CONFIGURE_FLAGS[@]}"
make
make install

chown $(stat -c '%u:%g' $BASE_DIR) -R $BASE_DIR/$TARGET

cd $BASE_DIR
export OS=windows
./build-chromaprint.sh
