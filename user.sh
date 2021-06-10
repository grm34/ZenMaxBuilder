#!/usr/bin/bash
# shellcheck disable=SC2034

#   Copyright 2021 Neternels-Builder by darkmaster @grm34 Neternels Team
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# TimeZone (used to set build date)
TIMEZONE=Europe/Paris

# Device codename (e.q. X00TD)
CODENAME=default

# Builder name (displayed in proc/version)
BUILDER=default

# Builder host (displayed in proc/version)
HOST=default

# Default compiler
DEFAULT_COMPILER=PROTON

# Kernel dir
KERNEL_DIR=default

# Kernel variant
KERNEL_VARIANT=NetHunter

# Link Time Optimization (LTO)
LTO=False

# Toolchains URL
PROTON="https://github.com/kdrag0n/proton-clang"
GCC_64="https://github.com/mvaisakh/gcc-arm64"
GCC_32="https://github.com/mvaisakh/gcc-arm"

# AnyKernel URL
ANYKERNEL="https://github.com/grm34/AnyKernel3-X00TD.git"
