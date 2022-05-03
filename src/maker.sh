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


# Set user options (from settings.cfg or user.cfg)
_export_path_and_options() {

    # Link Time Optimization (LTO)
    if [[ $LTO == True ]]
    then
        export LD=$LTO_LIBRARY
        export LD_LIBRARY_PATH=$LTO_LIBRARY_DIR
    fi

    # Get Toolchain Version
    # =====================
    #   $1 = TC lib DIR
    # =====================
    _get_tc_version() {
        _check find "$1" -mindepth 1 \
            -maxdepth 1 -type d | head -n 1
    }

    # Toolchain compiler options
    # Set and export required $PATH
    # Set make options from compiler
    # Get Toolchain version
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


# Save DEFCONFIG [MENUCONFIG]
# When a defconfig file is modified with menuconfig,
# the original will be saved as "example_defconfig_save"
_save_defconfig() {
    _note "$MSG_NOTE_SAVE $DEFCONFIG (arch/${ARCH}/configs)..."
    _check cp \
        "${CONF_DIR}/$DEFCONFIG" \
        "${CONF_DIR}/${DEFCONFIG}_save"
    _check cp "${OUT_DIR}/.config" "${CONF_DIR}/$DEFCONFIG"
}


# Run MAKE [BUILD]
_make_build() {
    _note "${MSG_NOTE_MAKE}: ${KERNEL_NAME}..."

    # Send build status on Telegram
    _send_make_build_status

    # Make new kernel build
    _check unbuffer make -C "$KERNEL_DIR" -j"$CORES" \
        O="$OUT_DIR" "${TC_OPTIONS[@]}" 2>&1
}

