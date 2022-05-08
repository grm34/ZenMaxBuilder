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


# Handle Makefile CROSS_COMPILE
# =============================
# - grep CROSS_COMPILE variables from Makefile
# - display them on TERM so user can check before
# - ask to set CROSS_COMPILE corresponding current TC
# - edit Makefile CROSS_COMPILE (append compiler)
# - warn the user when CC seems not correctly set
#
_get_cross_compile() {
    _note "$MSG_NOTE_CC"
    grepcc=$(grep CROSS_COMPILE "${KERNEL_DIR}/Makefile")
    echo "$grepcc" | grep -v "ifneq\|export\|#"
    _ask_for_edit_cross_compile
    case $COMPILER in
        "$PROTON_CLANG_NAME")
            ccompiler=${PROTON_CLANG_OPTIONS[1]}
            ;;
        "$PROTON_GCC_NAME")
            ccompiler=${PROTON_GCC_OPTIONS[1]}
            ;;
        "$EVA_GCC_NAME")
            ccompiler=${EVA_GCC_OPTIONS[1]}
            ;;
        "$LOS_GCC_NAME")
            ccompiler=${LOS_GCC_OPTIONS[1]}
    esac
    if [[ $EDIT_CC == True ]]
    then _edit_makefile_cross_compile
    else
        mk=$(grep "CROSS_COMPILE.*?=" "${KERNEL_DIR}/Makefile")
        if [[ -n ${mk##*"${ccompiler/CROSS_COMPILE=/}"*} ]]
        then _error WARN "$MSG_WARN_CC"
        fi
    fi
}


# Edit Makefile CROSS_COMPILE
_edit_makefile_cross_compile() {
    cc=${ccompiler/CROSS_COMPILE=/}
    _check sed -i \
        "s/CROSS_COMPILE.*?=.*/CROSS_COMPILE ?= ${cc}/g" \
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
    if [[ $LLVM == True ]]; then export LLVM=1; fi
    export KBUILD_BUILD_USER=$BUILDER
    export KBUILD_BUILD_HOST=$HOST
    export PLATFORM_VERSION=$PLATFORM_VERSION
    export ANDROID_MAJOR_VERSION=$ANDROID_MAJOR_VERSION

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
            ;;
        "$EVA_GCC_NAME")
            export PATH=${EVA_GCC_PATH}:$PATH
            TC_OPTIONS=("${EVA_GCC_OPTIONS[@]}")
            TCVER=$(_get_tc_version "$GCC_ARM64_VERSION")
            ;;
        "$LOS_GCC_NAME")
            export PATH=${LOS_GCC_PATH}:$PATH
            TC_OPTIONS=("${LOS_GCC_OPTIONS[@]}")
            TCVER=$(_get_tc_version "$LOS_ARM64_VERSION")
            ;;
        "$PROTON_GCC_NAME")
            export PATH=${PROTON_GCC_PATH}:$PATH
            TC_OPTIONS=("${PROTON_GCC_OPTIONS[@]}")
            clangver=$(_get_tc_version "$PROTON_VERSION")
            gccver=$(_get_tc_version "$GCC_ARM64_VERSION")
            export TCVER="${clangver##*/}-${gccver##*/}"
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
    _note "$MSG_NOTE_MENUCONFIG [${LINUX_VERSION}]..."
    make -C "$KERNEL_DIR" O="$OUT_DIR" \
        ARCH="$ARCH" menuconfig "${OUT_DIR}/.config"
}


# Save DEFCONFIG from MENUCONFIG
# ==============================
# When a defconfig file is modified with menuconfig,
# the original will be saved as "example_defconfig_save"
#
_save_defconfig() {
    _note "$MSG_NOTE_SAVE $DEFCONFIG (arch/${ARCH}/configs)..."
    _check cp \
        "${CONF_DIR}/$DEFCONFIG" \
        "${CONF_DIR}/${DEFCONFIG}_save"
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
    _check unbuffer make -C "$KERNEL_DIR" -j"$CORES" \
        O="$OUT_DIR" ARCH="$ARCH" "${TC_OPTIONS[@]}" 2>&1
}

