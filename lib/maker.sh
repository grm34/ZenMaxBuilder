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


_export_path() {

    # Link Time Optimization (LTO)
    if [[ ${LTO} == True ]]; then
        export LD=${LTO_LIBRARY}
        export LD_LIBRARY_PATH=${LTO_LIBRARY_DIR}
    fi

    # Set compiler parameters
    case ${COMPILER} in
        Proton-Clang)
            export PATH=${PROTON_CLANG_PATH}:${PATH}
            PARAMETERS=("${PROTON_CLANG_PARAMETERS[@]}")
            ;;
        Eva-GCC)
            export PATH=${EVA_GCC_PATH}:${PATH}
            PARAMETERS=("${EVA_GCC_PARAMETERS[@]}")
            ;;
        Proton-GCC)
            export PATH=${PROTON_GCC_PATH}:${PATH}
            PARAMETERS=("${PROTON_GCC_PARAMETERS[@]}")
    esac
}


_make_clean() {
    _note "Make clean (this could take a while)..."
    unbuffer make -C "${KERNEL_DIR}" clean 2>&1
    _note "Make mrproper (this could take a while)..."
    unbuffer make -C "${KERNEL_DIR}" mrproper 2>&1
    rm -rf "${OUT_DIR}" || sleep 0.1
}


_make_defconfig() {
    _note "Make ${DEFCONFIG} (${LINUX_VERSION})..."
    unbuffer make -C "${KERNEL_DIR}" O="${OUT_DIR}" \
        ARCH="${ARCH}" "${DEFCONFIG}" 2>&1
}


_make_menuconfig() {
    _note "Make menuconfig..."
    make -C "${KERNEL_DIR}" O="${OUT_DIR}" ARCH="${ARCH}" \
        menuconfig "${OUT_DIR}"/.config
}

_save_defconfig() {
    _note "Saving ${DEFCONFIG} in arch/${ARCH}/configs..."
    cp "${KERNEL_DIR}/arch/${ARCH}/configs/${DEFCONFIG}" \
        "${KERNEL_DIR}/arch/${ARCH}/configs/${DEFCONFIG}_save"
    cp "${OUT_DIR}"/.config \
        "${KERNEL_DIR}/arch/${ARCH}/configs/${DEFCONFIG}"
}


_make_build() {
    _note "Starting new build for ${CODENAME} (${LINUX_VERSION})..."

    # Send build status to Telegram
    if [[ ${BUILD_STATUS} == True ]]; then
        MSG="<b>Android Kernel Build Triggered</b> ${STATUS_MSG}"
        _send_msg "${MSG}"
    fi

    # Make kernel BUILD
    unbuffer make -C "${KERNEL_DIR}" \
        -j"${CORES}" O="${OUT_DIR}" "${PARAMETERS[@]}" 2>&1
}
