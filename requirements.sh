#!/usr/bin/bash

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


_install_dependencies() {

    # Set the package manager of the current Linux distribution
    declare -A PMS=(
        [aarch64]="_ apt-get install -y"
        [redhat]="sudo yum install -y"
        [arch]="sudo pacman -S --noconfirm"
        [gentoo]="sudo emerge -1 -y"
        [suse]="sudo zypper install -y"
        [fedora]="sudo dnf install -y"
    )
    OS=(aarch64 redhat arch gentoo suse fedora)
    for DIST in "${OS[@]}"; do
        case ${DIST} in "aarch64") ARG="-m";; *) ARG="-v"; esac
        if uname ${ARG} | grep -qi "${DIST}"; then
            IFS=" "
            PM=${PMS[${DIST}]}
            read -ra PM <<< "$PM"
            break
        else
            PM=(sudo apt-get install -y)
        fi
    done

    # Install missing dependencies
    DEPENDENCIES=(wget git zip llvm lld g++ gcc clang)
    for PACKAGE in "${DEPENDENCIES[@]}"; do
        if ! which "${PACKAGE//llvm/llvm-ar}" &>/dev/null; then
            echo -e \
                "\n${RED}${PACKAGE} not found. ${GREEN}Installing...${NC}"
            _check eval "${PM[0]//_/} ${PM[1]} ${PM[3]} ${PM[4]} ${PACKAGE}"
        fi
    done
}


_clone_toolchains() {
    case ${COMPILER} in
        PROTON)
            if [[ ! -d toolchains/proton ]]; then
                _note "Proton repository not found! Cloning..."
                _check git clone --depth=1 "${PROTON}" toolchains/proton
            fi
            ;;

        GCC)
            if [[ ! -d toolchains/gcc32 ]]; then
                _note "GCC arm repository not found! Cloning..."
                _check git clone "${GCC_32}" toolchains/gcc32
            fi
            if [[ ! -d toolchains/gcc64 ]]; then
                _note "GCC arm64 repository not found! Cloning..."
                _check git clone "${GCC_64}" toolchains/gcc64
            fi
            ;;

        PROTONxGCC)
            if [[ ! -d toolchains/proton ]]; then
                _note "Proton repository not found! Cloning..."
                _check git clone --depth=1 "${PROTON}" toolchains/proton
            fi
            if [[ ! -d toolchains/gcc32 ]]; then
                _note "GCC arm repository not found! Cloning..."
                _check git clone --depth=1 "${GCC_32}" toolchains/gcc32
            fi
            if [[ ! -d toolchains/gcc64 ]]; then
                _note "GCC arm64 repository not found! Cloning..."
                _check git clone --depth=1 "${GCC_64}" toolchains/gcc64
            fi
    esac
}


_clone_anykernel() {
    if [[ ! -d AnyKernel ]]; then
        _note "AnyKernel repository not found! Cloning..."
        _check git clone "${ANYKERNEL}" AnyKernel
    fi
}
