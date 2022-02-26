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
TIMEZONE=Europe/Paris

# Device codename (e.q. X00TD)
CODENAME=default

# Builder name (displayed in proc/version)
BUILDER=default

# Builder host (displayed in proc/version)
HOST=default

# Default compiler (Proton-Clang | Eva-GCC | Proton-GCC)
DEFAULT_COMPILER=Proton-Clang

# Kernel dir
KERNEL_DIR=default

# Kernel variant
KERNEL_VARIANT=NetHunter

# Link Time Optimization (LTO)
LTO=False

# Toolchains URL
PROTON="https://github.com/kdrag0n/proton-clang.git"
GCC_64="https://github.com/mvaisakh/gcc-arm64.git"
GCC_32="https://github.com/mvaisakh/gcc-arm.git"

# AnyKernel URL
ANYKERNEL="https://github.com/grm34/AnyKernel3-X00TD.git"

# Telegram API configuration
TELEGRAM_ID=""
TELEGRAM_BOT=""
TELEGRAM_TOKEN=""

# Tag
TAG=NetErnels
