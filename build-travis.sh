#!/usr/bin/env bash

case $TRAVIS_OS_NAME in
    linux)
        ARCH=x86_64 ./build-windows.sh
        ARCH=i686 ./build-windows.sh
        ;;
    osx)
        ARCH=x86_64 ./build-macos.sh
        ;;
esac
