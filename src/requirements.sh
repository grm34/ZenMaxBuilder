#!/usr/bin/bash

# Copyright (c) 2021-2022 @grm34 Neternels Team
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# Find oud and install requirements
_install_dependencies() {

    # Set the package manager for each Linux distribution
    declare -A PMS=(
        [apt]="sudo apt install -y"
        [pkg]="_ pkg install -y"
        [pacman]="sudo pacman -S --noconfirm"
        [yum]="sudo yum install -y"
        [emerge]="sudo emerge -1 -y"
        [zypper]="sudo zypper install -y"
        [dnf]="sudo dnf install -y"
    )

    # Get current package manager command
    OS=(pacman yum emerge zypper dnf pkg apt)
    for PKG in "${OS[@]}"
    do
        if which "$PKG" &>/dev/null
        then
            IFS=" "
            PM="${PMS[${PKG}]}"
            read -ra PM <<< "$PM"
            break
        fi
    done

    # Install missing dependencies
    if [[ ${PM[3]} ]]
    then
        for PACKAGE in "${DEPENDENCIES[@]}"
        do
            if ! which "${PACKAGE/llvm/llvm-ar}" &>/dev/null
            then
                _ask_for_install_pkg
                if [[ $INSTALL_PKG == True ]]
                then
                    eval "${PM[0]/_/}" "${PM[1]}" \
                         "${PM[2]}" "${PM[3]}" "$PACKAGE"
                fi
            fi
        done
    else
        _error "$MSG_ERR_OS"
    fi
}


# Clone missing toolchains repos
_clone_toolchains() {

    # Github Clone command
    # ====================
    #   $1 = repo branch
    #   $2 = repo url
    #   $3 = repo folder
    # ====================
    _clone_tc() {
        if [[ ! -d $3 ]]
        then
            _ask_for_clone_toolchain "${3##*/}"
            if [[ $CLONE_TC == True ]]
            then
                git clone --depth=1 -b "$1" "$2" "$3"
            fi
        fi
    }

    # Proton-Clang
    case $COMPILER in
        Proton-Clang|Proton-GCC)
            _clone_tc \
                "$PROTON_BRANCH" \
                "$PROTON_URL" \
                "$PROTON_DIR"
    esac

    # GCC ARM32
    case $COMPILER in
        Eva-GCC|Proton-GCC)
            _clone_tc \
                "$GCC_ARM_BRANCH" \
                "$GCC_ARM_URL" \
                "$GCC_ARM_DIR"
    esac

    # GCC ARM64
    case $COMPILER in
        Eva-GCC|Proton-GCC)
            _clone_tc \
                "$GCC_ARM64_BRANCH" \
                "$GCC_ARM64_URL" \
                "$GCC_ARM64_DIR"
    esac
}


# Clone missing AK3 repo
_clone_anykernel() {
    if [[ ! -d $ANYKERNEL_DIR ]]
    then
        _ask_for_clone_anykernel
        if [[ $CLONE_AK == True ]]
        then
            git clone -b \
                "$ANYKERNEL_BRANCH" \
                "$ANYKERNEL_URL" \
                "$ANYKERNEL_DIR"
        fi
    fi
}

