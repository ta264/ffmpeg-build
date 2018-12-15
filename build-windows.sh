#!/usr/bin/env bash

set -eu

cd $(dirname $0)
BASE_DIR=$(pwd)

source common.sh

if [ ! -e $LAME_TARBALL ]
then
	curl -L $LAME_TARBALL_URL > $LAME_TARBALL
fi

LAME_DIR=$(mktemp -d -p $(pwd) build.XXXXXXXX)
trap 'rm -rf $LAME_DIR' EXIT

: ${ARCH?}

cd $LAME_DIR
tar --strip-components=1 -xf $BASE_DIR/lame.tar.gz
./configure --host=$ARCH-w64-mingw32 --prefix=/usr/$ARCH-w64-mingw32/ --disable-shared --enable-static
make
make install 

cd $BASE_DIR
rm -r $LAME_DIR

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
