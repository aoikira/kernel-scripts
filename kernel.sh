#!/usr/bin/env bash
# Copyright (C) 2020 Saalim Quadri (iamsaalim)
# SPDX-License-Identifier: GPL-3.0-or-later

# Login to Git
echo -e "machine github.com\n  login $GITHUB_TOKEN" > ~/.netrc

# Set tg var.
function sendTG() {
    curl -s "https://api.telegram.org/bot$BOT_TOKEN/sendmessage" --data "text=${*}&chat_id=-1001218081655&parse_mode=HTML" > /dev/null
}

# Setup arguments
PROJECT_DIR="$HOME"
KERNEL_DIR="$PROJECT_DIR/Yeet"
TOOLCHAIN="$PROJECT_DIR/toolchain"
DEVICE="RMX1971"
BRANCH="b"
CHAT_ID="-1001218081655"

# Create kerneldir
mkdir -p "$PROJECT_DIR/Yeet"

# Clone up the source
git clone https://github.com/aoikira/kranul-kk -b $BRANCH $KERNEL_DIR --depth 1

# Clone toolchain
echo "Cloning toolchains"
git clone --depth=1 https://github.com/kdrag0n/proton-clang $TOOLCHAIN > /dev/null 2>&1

# Set Env
PATH="${TOOLCHAIN}/bin:${PATH}"
export ARCH=arm64
export KBUILD_BUILD_HOST=aikara
export KBUILD_BUILD_USER="DroneCI"

# Build
cd "$KERNEL_DIR"
sendTG "Building kernel for RMX1971"

make O=out ARCH=arm64 RMX1971_defconfig
make -j$(nproc --all) O=out \ ARCH=arm64 \ CC=clang \ CROSS_COMPILE=aarch64-linux-gnu- \ CROSS_COMPILE_ARM32=arm-linux-gnueabi-


if [ ! -e  $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb ]
then
    sendTG "Building kernel for RMX1971 Failed"
    exit 1
fi

sendTG "Building kernel for RMX1971 Completed. Uploading zip"


# Clone Anykernel
git clone https://gitlab.com/AkaruiAikara/AnyKernel3 --depth 1 AnyKernel3
cp $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb AnyKernel3/

now=`date +"%s"`

cd AnyKernel3 && zip -r9 [DONT-FLASH]kernel-RMX1971-"$now".zip * -x README.md [DONT-FLASH]kernel-RMX1971-"$now".zip

ZIP=$(echo *.zip)
curl -F chat_id="-1001218081655" -F document=@"$ZIP" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument"
