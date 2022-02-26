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
        Proton-Clang)
            if [[ ! -d ${DIR}/toolchains/proton ]]; then
                _note "Proton repository not found! Cloning..."
                _check \
                    git clone --depth=1 "${PROTON}" "${DIR}"/toolchains/proton
            fi
            ;;

        Eva-GCC)
            if [[ ! -d ${DIR}/toolchains/gcc32 ]]; then
                _note "GCC arm repository not found! Cloning..."
                _check git clone "${GCC_32}" "${DIR}"/toolchains/gcc32
            fi
            if [[ ! -d ${DIR}/toolchains/gcc64 ]]; then
                _note "GCC arm64 repository not found! Cloning..."
                _check git clone "${GCC_64}" "${DIR}"/toolchains/gcc64
            fi
            ;;

        Proton-GCC)
            if [[ ! -d ${DIR}/toolchains/proton ]]; then
                _note "Proton repository not found! Cloning..."
                _check \
                    git clone --depth=1 "${PROTON}" "${DIR}"/toolchains/proton
            fi
            if [[ ! -d ${DIR}/toolchains/gcc32 ]]; then
                _note "GCC arm repository not found! Cloning..."
                _check \
                    git clone --depth=1 "${GCC_32}" "${DIR}"/toolchains/gcc32
            fi
            if [[ ! -d ${DIR}/toolchains/gcc64 ]]; then
                _note "GCC arm64 repository not found! Cloning..."
                _check \
                    git clone --depth=1 "${GCC_64}" "${DIR}"/toolchains/gcc64
            fi
    esac
}


_clone_anykernel() {
    if [[ ! -d ${DIR}/AnyKernel ]]; then
        _note "AnyKernel repository not found! Cloning..."
        _check git clone "${ANYKERNEL}" "${DIR}"/AnyKernel
    fi
}
