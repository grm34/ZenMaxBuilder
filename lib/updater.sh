#!/usr/bin/bash

#    Copyright (c) 2021 darkmaster @grm34 Neternels Team
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


_full_upgrade() {

    # Neternels Builder
    _note "Updating Neternels Builder..."
    cd "${DIR}" || (_error "${DIR} not found!"; _exit)
    git pull origin main

    # AnyKernel
    TEMP=${DIR}/AnyKernel
    if [[ -d ${TEMP} ]]; then
        _note "Updating AnyKernel..."
        cd "${TEMP}" || (_error "${TEMP} not found!"; _exit)
        git pull origin main
    fi

    # Proton-Clang
    TEMP=${DIR}/toolchains/proton
    if [[ -d ${TEMP} ]]; then
        _note "Updating Proton-Clang..."
        cd "${TEMP}" || (_error "${TEMP} not found!"; _exit)
        git pull origin master
    fi

    # GCC-arm64
    TEMP=${DIR}/toolchains/gcc64
    if [[ -d ${TEMP} ]]; then
        _note "Updating GCC-arm64..."
        cd "${TEMP}" || (_error "${TEMP} not found!"; _exit)
        git pull origin gcc-master
    fi

    # GCC-arm32
    TEMP=${DIR}/toolchains/gcc32
    if [[ -d ${TEMP} ]]; then
        _note "Updating GCC-arm..."
        cd "${TEMP}" || (_error "${TEMP} not found!"; _exit)
        git pull origin gcc-master
    fi
}
