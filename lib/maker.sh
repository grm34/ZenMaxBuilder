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


_make_clean() {
    _confirm "Do you wish to make clean build: ${LINUX_VERSION} ?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            _clean_anykernel
            ;;
        *)
            _note "Make clean (this could take a while)..."
            _check make -C "${KERNEL_DIR}" clean
            _note "Make mrproper (this could take a while)..."
            _check make -C "${KERNEL_DIR}" mrproper
            _check rm -rf "${OUT_DIR}"
            _clean_anykernel
    esac
}


_make_defconfig() {
    _note "Make ${DEFCONFIG} (${LINUX_VERSION})..."

    # Send build status to Telegram
    if [[ ${BUILD_STATUS} == True ]]; then
        _send_msg "<b>${CODENAME}-${LINUX_VERSION}</b> | \
<code>New build started by ${BUILDER} with ${COMPILER}</code>"
    fi

    # Make defconfig
    _check make -C "${KERNEL_DIR}" O="${OUT_DIR}" ARCH=arm64 "${DEFCONFIG}"
}


_make_menuconfig() {
    _note "Make menuconfig..."

    # Send build status to Telegram
    if [[ ${BUILD_STATUS} == True ]]; then
        _send_msg "<b>${CODENAME}-${LINUX_VERSION}</b> | \
<code>Started menuconfig</code>"
    fi

    # Make Menuconfig
    _check make -C "${KERNEL_DIR}" O="${OUT_DIR}" ARCH=arm64 \
        menuconfig "${OUT_DIR}"/.config

    # Save new defconfig
    _confirm "Do you wish to save and use: ${DEFCONFIG} ?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            _confirm "Do you wish to continue with original defconfig ?"
            case ${CONFIRM} in
                n|N|no|No|NO)
                    _note "Cancel ${TAG}-${CODENAME}-${LINUX_VERSION}..."
                    _exit
                    ;;
                *)
                    return
            esac
            ;;
        *)
            _note "Saving ${DEFCONFIG} in arch/arm64/configs..."
            _check cp \
                "${KERNEL_DIR}"/arch/arm64/configs/"${DEFCONFIG}" \
                "${KERNEL_DIR}"/arch/arm64/configs/"${DEFCONFIG}"_save
            _check cp "${OUT_DIR}"/.config \
                "${KERNEL_DIR}"/arch/arm64/configs/"${DEFCONFIG}"
    esac
}


_make_build() {
    _note "Starting new build for ${CODENAME} (${LINUX_VERSION})..."

    # Send build status to Telegram
    if [[ ${BUILD_STATUS} == True ]]; then
        _send_msg "<b>${CODENAME}-${LINUX_VERSION}</b> | \
<code>Started compiling kernel</code>"
    fi

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

    # Make kernel BUILD
    _check make -C \
        "${KERNEL_DIR}" -j"${CORES}" O="${OUT_DIR}" "${PARAMETERS[@]}"
}
