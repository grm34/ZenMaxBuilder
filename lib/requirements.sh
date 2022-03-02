#!/usr/bin/bash

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


_install_dependencies() {

    # Set the package manager for each Linux distribution
    declare -A PMS=(
        [android]="_ pkg install -y"
        [redhat]="sudo yum install -y"
        [arch]="sudo pacman -S --noconfirm"
        [gentoo]="sudo emerge -1 -y"
        [suse]="sudo zypper install -y"
        [fedora]="sudo dnf install -y"
        [debian]="sudo apt install -y"
    )

    # Get current Linux distribution
    OS=(android redhat arch gentoo suse fedora debian)
    for DIST in "${OS[@]}"; do
        if uname -a | grep -qi "${DIST}"; then
            IFS=" "
            PM=${PMS[${DIST}]}
            read -ra PM <<< "$PM"
            break
        fi
    done

    # Display error if not found
    if [[ ! ${PM[3]} ]]; then
        _error "OS not reconized! You must install dependencies first."

    # Install missing dependencies
    else
        for PACKAGE in "${DEPENDENCIES[@]}"; do
            if ! which "${PACKAGE//llvm/llvm-ar}" &>/dev/null; then
                _note "Package ${PACKAGE} not found! Installing..."
                _check eval \
                    "${PM[0]//_/} ${PM[1]} ${PM[2]} ${PM[3]} ${PACKAGE}"
            fi
        done
    fi
}


_clone_toolchains() {

    _clone_proton() {
        if [[ ! -d ${PROTON_DIR} ]]; then
            _note "Proton-Clang repository not found! Cloning..."
            _check git clone --depth=1 -b \
                "${PROTON_BRANCH}" "${PROTON_URL}" "${PROTON_DIR}"
        fi
    }
    _clone_gcc_arm() {
        if [[ ! -d ${GCC_ARM_DIR} ]]; then
            _note "GCC ARM repository not found! Cloning..."
            _check git clone --depth=1 -b \
                "${GCC_ARM_BRANCH}" "${GCC_ARM_URL}" "${GCC_ARM_DIR}"
        fi
    }
    _clone_gcc_arm64() {
        if [[ ! -d ${GCC_ARM64_DIR} ]]; then
            _note "GCC ARM64 repository not found! Cloning..."
            _check git clone --depth=1 -b \
                "${GCC_ARM64_BRANCH}" "${GCC_ARM64_URL}" "${GCC_ARM64_DIR}"
        fi
    }

    case ${COMPILER} in
        Proton-Clang)
            _clone_proton
            ;;

        Eva-GCC)
            _clone_gcc_arm
            _clone_gcc_arm64
            ;;

        Proton-GCC)
            _clone_proton
            _clone_gcc_arm
            _clone_gcc_arm64
    esac
}


_clone_anykernel() {
    if [[ ! -d ${ANYKERNEL_DIR} ]]; then
        _note "AnyKernel repository not found! Cloning..."
        _check git clone -b \
            "${ANYKERNEL_BRANCH}" "${ANYKERNEL_URL}" "${ANYKERNEL_DIR}"
    fi
}
