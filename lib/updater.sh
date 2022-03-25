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


_full_upgrade() {

    # Neternels Builder
    _note "Updating Neternels Builder..."
    if git diff config.sh | grep -q config.sh &>/dev/null; then
        _ask_for_save_config
        if [[ ${SAVE_CONFIG} == True ]]; then
            _check mv config.sh config_save.sh
        fi
    fi
    git checkout "${NB_BRANCH}"
    git pull origin "${NB_BRANCH}"
    if [[ ! -f config.sh ]]; then
        _check cp config_save.sh config.sh
    fi

    # AnyKernel
    if [[ -d ${ANYKERNEL_DIR} ]]; then
        _note "Updating AnyKernel..."
        cd "${ANYKERNEL_DIR}" || \
            (_error "dir not found ${RED}${ANYKERNEL_DIR}"; _exit)
        git checkout "${ANYKERNEL_BRANCH}"
        git pull origin "${ANYKERNEL_BRANCH}"
        cd "${DIR}" || (_error "dir not found ${RED}${DIR}"; _exit)
    fi

    # Proton-Clang
    if [[ -d ${PROTON_DIR} ]]; then
        _note "Updating Proton Clang..."
        cd "${PROTON_DIR}" || \
            (_error "dir not found ${RED}${PROTON_DIR}"; _exit)
        git checkout "${PROTON_BRANCH}"
        git pull origin "${PROTON_BRANCH}"
        cd "${DIR}" || (_error "dir not found ${RED}${DIR}"; _exit)
    fi

    # GCC-arm64
    if [[ -d ${GCC_ARM64_DIR} ]]; then
        _note "Updating GCC ARM64..."
        cd "${GCC_ARM64_DIR}" || \
            (_error "dir not found ${RED}${GCC_ARM64_DIR}"; _exit)
        git checkout "${GCC_ARM64_BRANCH}"
        git pull origin "${GCC_ARM64_BRANCH}"
        cd "${DIR}" || (_error "dir not found ${RED}${DIR}"; _exit)
    fi

    # GCC-arm32
    if [[ -d ${GCC_ARM_DIR} ]]; then
        _note "Updating GCC ARM..."
        cd "${GCC_ARM_DIR}" || \
            (_error "dir not found ${RED}${GCC_ARM_DIR}"; _exit)
        git checkout "${GCC_ARM_BRANCH}"
        git pull origin "${GCC_ARM_BRANCH}"
        cd "${DIR}" || (_error "dir not found ${RED}${DIR}"; _exit)
    fi
}

