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


# Handle Makefile CROSS_COMPILE and CC
# ====================================
# - display them on TERM so user can check before
# - ask to add them in Makefile (corresponding current TC)
# - edit them in the current kernel Makefile
# - display them on TERM so user can check the edit
# - warn the user when they seems not correctly set
#
_handle_makefile_cross_compile() {
    _note "$MSG_NOTE_CC"
    _display_cross_compile
    _ask_for_edit_cross_compile
    if [[ $EDIT_CC != False ]]
    then
        _edit_cross_compile
        _note "$MSG_NOTE_CC"
        _display_cross_compile
    else
        mk=$(grep "^CROSS_COMPILE.*?=" "${KERNEL_DIR}/Makefile")
        if [[ -n ${mk##*"${cross/CROSS_COMPILE=/}"*} ]]
        then _error WARN "$MSG_WARN_CC"
        fi
    fi
}


# Get CROSS_COMPILE and CC
_display_cross_compile() {
    sed -n "/^CROSS_COMPILE.*?=/{p;q;}" "${KERNEL_DIR}/Makefile"
    sed -n "/^CC.*=/{p;q;}" "${KERNEL_DIR}/Makefile"
}


# Edit CROSS_COMPILE and CC
_edit_cross_compile() {
    _check sed -i \
        "0,/^CROSS_COMPILE.*?=.*/s//CROSS_COMPILE ?= ${cross}/" \
        "${KERNEL_DIR}/Makefile"
    _check sed -i "0,/^CC.*=.*/s//CC = ${cc}/" \
        "${KERNEL_DIR}/Makefile"
}


# Get toolchain version
# =====================
#  $1 = toolchain lib DIR
#
_get_tc_version() {
    _check find "$1" -mindepth 1 \
        -maxdepth 1 -type d | head -n 1
}


# Set compiler build options
# ==========================
# - export target variables (CFG)
# - set Link Time Optimization (LTO)
# - set and export required $PATH
# - define make flags and options
# - get current toolchain version
#
_export_path_and_options() {
    if [[ $BUILDER == default ]]; then BUILDER=$(whoami); fi
    if [[ $HOST == default ]]; then HOST=$(uname -n); fi
    export KBUILD_BUILD_USER=$BUILDER
    export KBUILD_BUILD_HOST=$HOST

    if [[ $LTO == True ]]
    then
        export LD=$LTO_LIBRARY
        export LD_LIBRARY_PATH=$LTO_LIBRARY_DIR
    fi
    case $COMPILER in
        "$PROTON_CLANG_NAME")
            export PATH=${PROTON_CLANG_PATH}:$PATH
            TC_OPTIONS=("${PROTON_CLANG_OPTIONS[@]}")
            TCVER=$(_get_tc_version "$PROTON_VERSION")
            cross=${PROTON_CLANG_OPTIONS[1]/CROSS_COMPILE=/}
            cc=${PROTON_CLANG_OPTIONS[3]/CC=/}
            ;;
        "$EVA_GCC_NAME")
            export PATH=${EVA_GCC_PATH}:$PATH
            TC_OPTIONS=("${EVA_GCC_OPTIONS[@]}")
            TCVER=$(_get_tc_version "$GCC_ARM64_VERSION")
            cross=${EVA_GCC_OPTIONS[1]/CROSS_COMPILE=/}
            cc=${EVA_GCC_OPTIONS[3]/CC=/}
            ;;
        "$LOS_GCC_NAME")
            export PATH=${LOS_GCC_PATH}:$PATH
            TC_OPTIONS=("${LOS_GCC_OPTIONS[@]}")
            TCVER=$(_get_tc_version "$LOS_ARM64_VERSION")
            cross=${LOS_GCC_OPTIONS[1]/CROSS_COMPILE=/}
            cc=${LOS_GCC_OPTIONS[3]/CC=/}
            ;;
        "$PROTON_GCC_NAME")
            export PATH=${PROTON_GCC_PATH}:$PATH
            TC_OPTIONS=("${PROTON_GCC_OPTIONS[@]}")
            clangver=$(_get_tc_version "$PROTON_VERSION")
            gccver=$(_get_tc_version "$GCC_ARM64_VERSION")
            export TCVER="${clangver##*/}-${gccver##*/}"
            cross=${PROTON_GCC_OPTIONS[1]/CROSS_COMPILE=/}
            cc=${PROTON_GCC_OPTIONS[3]/CC=/}
    esac
}


# Run MAKE CLEAN
_make_clean() {
    _note "$MSG_NOTE_MAKE_CLEAN [${LINUX_VERSION}]..."
    _check unbuffer make -C "$KERNEL_DIR" clean 2>&1
}


# Run MAKE MRPROPER
_make_mrproper() {
    _note "$MSG_NOTE_MRPROPER [${LINUX_VERSION}]..."
    _check unbuffer make -C "$KERNEL_DIR" mrproper 2>&1
}


# Run MAKE DEFCONFIG
_make_defconfig() {
    _note "$MSG_NOTE_DEFCONFIG $DEFCONFIG [${LINUX_VERSION}]..."
    _check unbuffer make -C "$KERNEL_DIR" \
        O="$OUT_DIR" ARCH="$ARCH" "$DEFCONFIG" 2>&1
}


# Run MAKE MENUCONFIG
_make_menuconfig() {
    _note "$MSG_NOTE_MENUCONFIG $DEFCONFIG [${LINUX_VERSION}]..."
    make -C "$KERNEL_DIR" O="$OUT_DIR" \
        ARCH="$ARCH" menuconfig "${OUT_DIR}/.config"
}


# Save DEFCONFIG from MENUCONFIG
# ==============================
# When a existing defconfig file is modified with menuconfig,
# the original defconfig will be saved as "example_defconfig_old"
#
_save_defconfig() {
    _note "$MSG_NOTE_SAVE $DEFCONFIG (arch/${ARCH}/configs)..."
    if [[ -f "${CONF_DIR}/$DEFCONFIG" ]]
    then
        _check cp \
            "${CONF_DIR}/$DEFCONFIG" \
            "${CONF_DIR}/${DEFCONFIG}_old"
    fi
    _check cp "${OUT_DIR}/.config" "${CONF_DIR}/$DEFCONFIG"
}


# Run MAKE BUILD
# ==============
# - send build status on Telegram
# - make new kernel build
#
_make_build() {
    _note "${MSG_NOTE_MAKE}: ${KERNEL_NAME}..."
    _send_make_build_status
    cc="${TC_OPTIONS[3]} -I$KERNEL_DIR"
    cflags="${TC_OPTIONS[*]/${TC_OPTIONS[3]}}"
    _check unbuffer make -C "$KERNEL_DIR" -j"$CORES" \
        O="$OUT_DIR" "$cc" ARCH="$ARCH" "${cflags/  / }" 2>&1
}

