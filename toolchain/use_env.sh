#!/bin/bash


# load saved environment variables
export TARGET_C_COMPILER=$(cat /envs/TARGET_C_COMPILER)
export TARGET_CXX_COMPILER=$(cat /envs/TARGET_CXX_COMPILER)
export TARGET_ARCH=$(cat /envs/TARGET_ARCH)
export TARGET_ROOT_PATH=$(cat /envs/TARGET_ROOT_PATH)

# if not on the target env, chroot into the target subsystem
if [ "$TARGET_ROOT_PATH" != "/" ]; then
    export CHROOT="chroot $TARGET_ROOT_PATH"
fi
