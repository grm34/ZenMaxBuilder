#!/usr/bin/bash
# shellcheck disable=SC2034

#    Copyright (c) 2022 @grm34 Neternels Team
#
#    Permission is hereby granted, free of charge, to any person
#    obtaining a copy of this software and associated documentation
#    files (the "Software"), to deal in the Software without restriction,
#    including without limitation the rights to use, copy, modify, merge,
#    publish, distribute, sublicense, and/or sell copies of the Software,
#    and to permit persons to whom the Software is furnished to do so,
#    subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be
#    included in all copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# TimeZone (used to set build date)
TIMEZONE="Europe/Paris"

# Device codename (e.q. X00TD)
CODENAME="G780F"

# Builder name (displayed in proc/version)
BUILDER=default

# Builder host (displayed in proc/version)
HOST=default

# Default compiler (Proton-Clang | Eva-GCC | Proton-GCC)
DEFAULT_COMPILER="Eva-GCC"

# Kernel dir
KERNEL_DIR="../android_kernel_samsung_G780F"

# Kernel variant
KERNEL_VARIANT=Nethunter

# Tag
TAG=Nethunter

# Link Time Optimization (LTO)
LTO=False
LTO_PATH="toolchains/proton/lib"

# AnyKernel URL
ANYKERNEL="https://github.com/grm34/AnyKernel3.git"

# Toolchains URL
PROTON="https://github.com/kdrag0n/proton-clang.git"
GCC_64="https://github.com/mvaisakh/gcc-arm64.git"
GCC_32="https://github.com/mvaisakh/gcc-arm.git"

# Proton-Clang config
PROTON_CLANG_PATH="toolchains/proton/bin:/usr/bin"
PROTON_CLANG_PARAMETERS="ARCH=arm64\
 SUBARCH=arm64\
 CROSS_COMPILE=aarch64-linux-gnu-\
 CROSS_COMPILE_COMPAT=arm-linux-gnueabi-\
 CC=clang\
 AR=llvm-ar\
 NM=llvm-nm\
 OBJCOPY=llvm-objcopy\
 OBJDUMP=llvm-objdump\
 STRIP=llvm-strip\
"

# Eva-GCC config
EVA_GCC_PATH="toolchains/gcc32/bin:toolchains/gcc64/bin:../../usr/bin"
EVA_GCC_PARAMETERS="ARCH=arm64\
 SUBARCH=arm64\
 CROSS_COMPILE_ARM32=arm-eabi-\
 CROSS_COMPILE=aarch64-elf-\
 AR=aarch64-elf-ar\
 OBJDUMP=aarch64-elf-objdump\
 STRIP=aarch64-elf-strip\
"

# Proton-GCC config
PROTON_GCC_PATH="toolchains/proton/bin:toolchains/gcc64/bin:toolchains/gcc32/bin:/usr/bin"
PROTON_GCC_PARAMETERS="ARCH=arm64\
 SUBARCH=arm64\
 CC=clang\
 CROSS_COMPILE=aarch64-linux-gnu-\
 CROSS_COMPILE_ARM32=arm-linux-gnueabi-\
 AR=llvm-ar\
 AS=llvm-as\
 NM=llvm-nm\
 STRIP=llvm-strip\
 OBJCOPY=llvm-objcopy\
 OBJDUMP=llvm-objdump\
 OBJSIZE=llvm-size\
 READELF=llvm-readelf\
 HOSTCC=clang\
 HOSTCXX=clang++\
 HOSTAR=llvm-ar\
 CLANG_TRIPLE=aarch64-linux-gnu-\
"

# Telegram API configuration
TELEGRAM_ID=""
TELEGRAM_BOT=""
TELEGRAM_TOKEN=""
