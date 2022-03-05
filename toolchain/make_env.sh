#!/bin/bash


# map the Docker arch args to the correct uname and target root path
if [ "$TARGETARCH" = "arm64" ]; then
    TARGET_ARCH="aarch64"

    if [ "$BUILDARCH" = "amd64" ]; then
        TARGET_ROOT_PATH="/mnt/aarch64"
    else
        TARGET_ROOT_PATH="/"
    fi
elif [ "$TARGETARCH" = "amd64" ]; then
    TARGET_ARCH="x86-64"

    if [ "$BUILDARCH" = "arm64" ]; then
        TARGET_ROOT_PATH="/mnt/amd64"
    else
        TARGET_ROOT_PATH="/"
    fi
fi

# if we're building for a different arch, create a different arch chroot
if [ "$TARGET_ROOT_PATH" != "/" ]; then
    mkdir -p $TARGET_ROOT_PATH
    apt-get install -y --no-install-recommends debootstrap
    debootstrap --arch $TARGETARCH \
        --variant buildd \
        --include file,python3-dev,python-is-python3 \
        bullseye \
        $TARGET_ROOT_PATH \
        http://deb.debian.org/debian

    cp $TARGET_ROOT_PATH/bin/true $TARGET_ROOT_PATH/usr/bin/ischroot

    # move shared objects for target arch
    mv /toolchain/$TARGET_ARCH/ld-linux-$TARGET_ARCH.so.1 /lib/ld-linux-$TARGET_ARCH.so.1
    mv /toolchain/$TARGET_ARCH/libc.so.6 /lib/libc.so.6
fi

# install our cross compilers
apt-get install -y --no-install-recommends \
    gcc-$TARGET_ARCH-linux-gnu g++-$TARGET_ARCH-linux-gnu
rm -rf /var/lib/apt/lists/*

# export our env variables for use in other intermediate stages
mkdir /envs
echo -n $(which $TARGET_ARCH-linux-gnu-gcc) > /envs/TARGET_C_COMPILER
echo -n $(which $TARGET_ARCH-linux-gnu-g++) > /envs/TARGET_CXX_COMPILER
echo -n $TARGET_ARCH > /envs/TARGET_ARCH
echo -n $TARGET_ROOT_PATH > /envs/TARGET_ROOT_PATH
