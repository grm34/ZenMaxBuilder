#!/usr/bin/bash
# shellcheck disable=SC2034

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


_ask_for_kernel_dir() {
    # Question to get the kernel location.
    # Validation checks the presence of the "configs"
    # folder corresponding to the current architecture.

    if [[ ${KERNEL_DIR} == default ]]; then
        QUESTION="Enter kernel path (e.q. /home/user/mykernel) :"
        _prompt "${QUESTION}"; read -r -e KERNEL_DIR
        until [[ -d ${KERNEL_DIR}/arch/${ARCH}/configs ]]; do
            _error "${KERNEL_DIR} invalid kernel directory !"
            _prompt "${QUESTION}"; read -r -e KERNEL_DIR
        done
    fi
}


_ask_for_toolchain() {
    # Question to get the toolchain to use.
    # Validation checks for a number between "1" and "3"
    # which correspond to the number of available toolchains.

    N="[Y/n]"
    _confirm "Do you wish to use compiler: ${DEFAULT_COMPILER} ?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            _note "Select Toolchain compiler :"
            TOOLCHAINS=(Proton-Clang Eva-GCC Proton-GCC)
            _select "${TOOLCHAINS[@]}"; read -r COMPILER
            until (( 1<=COMPILER && COMPILER<=3 )); do
                _error "${COMPILER} invalid ! Enter number 1-3"
                _select "${TOOLCHAINS[@]}"; read -r COMPILER
            done
            COMPILER=${TOOLCHAINS[${COMPILER}-1]}
            ;;
        *)
            COMPILER=${DEFAULT_COMPILER}
    esac
}


_ask_for_codename() {
    # Question to get the device codename.
    # Validation checks REGEX to prevent invalid string.
    # Match "letters" and "numbers" and "-" and "_" only.
    # Should be at least "3" characters long and maximum "20".
    # Device codename can't start with "_" or "-" characters.

    if [[ ${CODENAME} == default ]]; then
        QUESTION="Enter android device codename (e.q. X00TD) :"
        _prompt "${QUESTION}"; read -r CODENAME
        until [[ ${CODENAME} =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]{2,20}$ ]]; do
            _error "${CODENAME} invalid device codename !"
            _prompt "${QUESTION}"; read -r CODENAME
        done
    fi
}


_ask_for_defconfig() {
    # Question to get the defconfig file to use.
    # Validation checks the presence of this file in
    # "configs" folder and verify it ends with "_defconfig".

    cd "${KERNEL_DIR}/arch/${ARCH}/configs" || \
        (_error "${KERNEL_DIR} dir not found !"; _exit)
    QUESTION="Enter defconfig file (e.q. neternels_defconfig) :"
    _prompt "${QUESTION}"; read -r -e DEFCONFIG
    until [[ -f ${DEFCONFIG} ]] && [[ ${DEFCONFIG} == *defconfig ]]; do
            _error "${DEFCONFIG} invalid defconfig file !"
        _prompt "${QUESTION}"; read -r -e DEFCONFIG
    done
    cd "${DIR}" || (_error "${DIR} dir not found !"; _exit)
}


_ask_for_menuconfig() {
    # Request a "make menuconfig" command.
    # Validation checks are not needed here.

    N="[y/N]"
    _confirm "Do you wish to edit kernel with menuconfig ?"
    case ${CONFIRM} in
        y|Y|yes|Yes|YES)
            MENUCONFIG=True
            ;;
        *)
            MENUCONFIG=False
    esac
}


_ask_for_cores() {
    # Question to get the number of CPU cores to use.
    # Validation checks for a valid number corresponding
    # to the amount of available CPU cores (no limits here).
    # Otherwise all available CPU cores will be used.

    N="[Y/n]"
    CPU=$(nproc --all)
    _confirm "Do you wish to use all available CPU Cores ?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            QUESTION="Enter the amount of CPU Cores to use :"
            _prompt "${QUESTION}"; read -r CORES
            until (( 1<=CORES && CORES<=CPU )); do
                _error "${CORES} invalid ! Total cores: ${CPU}"
                _prompt "${QUESTION}"; read -r CORES
            done
            ;;
        *)
            CORES=${CPU}
    esac
}


_ask_for_telegram() {
    # Request the upload of build status on Telegram.
    # Validation checks are not needed here.

    if [[ ${TELEGRAM_CHAT_ID} ]] && [[ ${TELEGRAM_BOT_TOKEN} ]]; then
        N="[y/N]"
        _confirm "Do you wish to send build status on Telegram ?"
        case ${CONFIRM} in
            y|Y|yes|Yes|YES)
                BUILD_STATUS=True
                ;;
            *)
                BUILD_STATUS=False
        esac
    fi
}


_ask_for_make_clean() {
    # Request "make clean" and "make mrproper" commands.
    # Validation checks are not needed here.

    N="[y/N]"
    _confirm "Do you wish to make clean build: ${LINUX_VERSION} ?"
    case ${CONFIRM} in
        y|Y|yes|Yes|YES)
            MAKE_CLEAN=True
            ;;
        *)
            MAKE_CLEAN=False
    esac
}


_ask_for_save_defconfig() {
    # Request to save and use the modified defconfig.
    # Otherwise request to continue with original one.
    # Validation checks are not needed here.

    N="[Y/n]"
    _confirm "Do you wish to save and use: ${DEFCONFIG} ?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            SAVE_DEFCONFIG=False
            _confirm "Do you wish to use original defconfig ?"
            case ${CONFIRM} in
                n|N|no|No|NO)
                    ORIGINAL_DEFCONFIG=False
                    ;;
                *)
                    ORIGINAL_DEFCONFIG=True
            esac
            ;;
        *)
            SAVE_DEFCONFIG=True
    esac
}


_ask_for_new_build() {
    # Request "make" command for kernel build.
    # Validation checks are not needed here.

    N="[Y/n]"
    _confirm "Do you wish to start ${TAG}-${CODENAME}-${LINUX_VERSION} ?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            NEW_BUILD=False
            ;;
        *)
            NEW_BUILD=True
    esac
}


_ask_for_flashable_zip() {
    # Request the creation of flashable zip.
    # Validation checks are not needed here.

    N="[y/N]"
    _confirm "Do you wish to zip ${TAG}-${CODENAME}-${LINUX_VERSION} ?"
    case ${CONFIRM} in
        y|Y|yes|Yes|YES)
            FLASH_ZIP=True
            ;;
        *)
            FLASH_ZIP=False
    esac
}


_ask_for_kernel_image() {
    # Question to get the kernel image to zip.
    # Validation checks the presence of this file in
    # "boot" folder and verify it starts with "Image".

    cd "${DIR}/out/${CODENAME}/arch/${ARCH}/boot" || (_error \
        "${DIR}/out/${CODENAME}/arch/${ARCH}/boot dir not found !"; _exit)
    QUESTION="Enter kernel image to use (e.q. Image.gz-dtb) :"
    _prompt "${QUESTION}"; read -r -e KERNEL_IMG
    until [[ -f ${KERNEL_IMG} ]] && [[ ${KERNEL_IMG} == Image* ]]; do
        _error "${KERNEL_IMG} invalid kernel image !"
        _prompt "${QUESTION}"; read -r -e KERNEL_IMG
    done
    KERNEL_IMG="${DIR}/out/${CODENAME}/arch/${ARCH}/boot/${KERNEL_IMG}"
    cd "${DIR}" || (_error "${DIR} dir not found !"; _exit)
}


_ask_for_install_pkg() {
    # Request the installation of missing packages.
    # Warn the user that when false the script may crash.
    # Validation checks are not needed here.

    N="[Y/n]"
    _confirm "Package ${PACKAGE} not found, do you wish to install ?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            INSTALL_PKG=False
            _error "${PACKAGE} not found ! Compilation may fail."
            ;;
        *)
            INSTALL_PKG=True
    esac
}


_ask_for_clone_toolchain() {
    # Request to clone missing tookchains.
    # Warn the user and exit the script when false.
    # Validation checks are not needed here.

    N="[Y/n]"
    _confirm "Toolchain ${TC} not found, do you wish to clone ?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            CLONE_TC=False
            _error "${TC} dir not found ! Invalid toolchain path."
            _exit
            ;;
        *)
            CLONE_TC=True
    esac
}


_ask_for_clone_anykernel() {
    # Request to clone missing AnyKernel repo.
    # Warn the user and exit the script when false.
    # Validation checks are not needed here.

    N="[Y/n]"
    _confirm "Anykernel not found, do you wish to clone ?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            CLONE_AK=False
            _error "Anykernel dir not found ! Invalid AK3 path."
            _exit
            ;;
        *)
            CLONE_AK=True
    esac
}
