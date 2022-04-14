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


# Question to get the device codename.
# Validation checks REGEX to prevent invalid string.
# Match "letters" and "numbers" and "-" and "_" only.
# Should be at least "3" characters long and maximum "20".
# Device codename can't start with "_" or "-" characters.
_ask_for_codename() {
    if [[ $CODENAME == default ]]
    then
        _prompt "$MSG_ASK_DEV :"
        read -r CODENAME
        regex="^[a-zA-Z0-9][a-zA-Z0-9_-]{2,20}$"
        until [[ $CODENAME =~ $regex ]]
        do
            _error "$MSG_ERR_DEV ${RED}${CODENAME}"
            _prompt "$MSG_ASK_DEV :"
            read -r CODENAME
        done
    fi
}


# Question to get the kernel location.
# Validation checks the presence of the "configs"
# folder corresponding to the current architecture.
_ask_for_kernel_dir() {
    if [[ $KERNEL_DIR == default ]]
    then
        _prompt "$MSG_ASK_KDIR :"
        read -r -e KERNEL_DIR
        until [[ -d ${KERNEL_DIR}/arch/${ARCH}/configs ]]
        do
            _error "$MSG_ERR_KDIR ${RED}${KERNEL_DIR}"
            _prompt "$MSG_ASK_KDIR :"
            read -r -e KERNEL_DIR
        done
    fi
}


# Prompt to select the defconfig file to use.
# Choices: all defconfig files located in "configs"
# folder corresponding to the current architecture.
# Validation checks are not needed here.
_ask_for_defconfig() {
    PROMPT_TYPE="echo"
    CONF_DIR=${KERNEL_DIR}/arch/${ARCH}/configs
    cd "$CONF_DIR" || (
        _error "$MSG_ERR_DIR ${RED}${CONF_DIR}"
        _exit
    )
    _prompt "$MSG_ASK_DEF :"
    select DEFCONFIG in *_defconfig
    do
        [[ $DEFCONFIG ]] && break
        _error "$MSG_ERR_SELECT"
    done
    cd "$DIR" || (
        _error "$MSG_ERR_DIR ${RED}${DIR}"
        _exit
    )
    export PROMPT_TYPE="default"
}


# Request a "make menuconfig" command.
# Validation checks are not needed here.
_ask_for_menuconfig() {
    _confirm "$MSG_ASK_CONF ?" "[y/N]"
    case $CONFIRM in
        y|Y|yes|Yes|YES)
            MENUCONFIG=True
            ;;
        *)
            export MENUCONFIG=False
    esac
}


# Request to save and use the modified defconfig.
# Otherwise request to continue with original one.
# Validation checks are not needed here.
_ask_for_save_defconfig() {
    _confirm "${MSG_ASK_SAVE_DEF}: $DEFCONFIG ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            SAVE_DEFCONFIG=False
            _confirm "$MSG_ASK_USE_DEF ?"
            case $CONFIRM in
                n|N|no|No|NO)
                    ORIGINAL_DEFCONFIG=False
                    ;;
                *)
                    export ORIGINAL_DEFCONFIG=True
            esac
            ;;
        *)
            export SAVE_DEFCONFIG=True
    esac
}


# Question to get the toolchain to use.
# Choices: Proton-Clang Eva-GCC Proton-GCC
# Validation checks are not needed here.
_ask_for_toolchain() {
    if [[ $COMPILER == default ]]
    then
        PROMPT_TYPE="echo"
        _prompt "$MSG_SELECT_TC :"
        select COMPILER in $PROTON_CLANG_NAME \
            $EVA_GCC_NAME $PROTON_GCC_NAME
        do
            [[ $COMPILER ]] && break
            _error "$MSG_ERR_SELECT"
        done
        export PROMPT_TYPE="default"
    fi
}


# Question to get the number of CPU cores to use.
# Validation checks for a valid number corresponding
# to the amount of available CPU cores (no limits here).
# Otherwise all available CPU cores will be used.
_ask_for_cores() {
    CPU=$(nproc --all)
    _confirm "$MSG_ASK_CPU ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _prompt "$MSG_ASK_CORES :"
            read -r CORES
            until (( 1<=CORES && CORES<=CPU ))
            do
                _error "$MSG_ERR_CORES ${RED}${CORES}"\
                       "${YELL}(${MSG_ERR_TOTAL}: ${CPU})"
                _prompt "$MSG_ASK_CORES :"
                read -r CORES
            done
            ;;
        *)
            export CORES=$CPU
    esac
}


# Request "make clean" and "make mrproper" commands.
# Validation checks are not needed here.
_ask_for_make_clean() {
    _confirm "${MSG_ASK_MCLEAN}: v$LINUX_VERSION ?" "[y/N]"
    case $CONFIRM in
        y|Y|yes|Yes|YES)
            MAKE_CLEAN=True
            ;;
        *)
            export MAKE_CLEAN=False
    esac
}


# Request "make" command for kernel build.
# Validation checks are not needed here.
_ask_for_new_build() {
    _confirm \
        "$MSG_START ${TAG}-${CODENAME}-${LINUX_VERSION} ?" \
        "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            NEW_BUILD=False
            ;;
        *)
            export NEW_BUILD=True
    esac
}


# Request the upload of build status on Telegram.
# Validation checks are not needed here.
_ask_for_telegram() {
    if [[ $TELEGRAM_CHAT_ID ]] && \
        [[ $TELEGRAM_BOT_TOKEN ]]
    then
        _confirm "$MSG_ASK_TG ?" "[y/N]"
        case $CONFIRM in
            y|Y|yes|Yes|YES)
                BUILD_STATUS=True
                ;;
            *)
                export BUILD_STATUS=False
        esac
    fi
}


# Request the creation of flashable zip.
# Validation checks are not needed here.
_ask_for_flashable_zip() {
    _confirm \
        "$MSG_ASK_ZIP ${TAG}-${CODENAME}-${LINUX_VERSION} ?" \
        "[y/N]"
    case $CONFIRM in
        y|Y|yes|Yes|YES)
            FLASH_ZIP=True
            ;;
        *)
            export FLASH_ZIP=False
    esac
}


# Question to get the kernel image to zip.
# Validation checks the presence of this file in
# "boot" folder and verify it starts with "Image".
_ask_for_kernel_image() {
    cd "$BOOT_DIR" || (
        _error "$MSG_ERR_DIR ${RED}${BOOT_DIR}"
        _exit
    )
    _prompt "$MSG_ASK_IMG :"
    read -r -e K_IMG
    until [[ -f $K_IMG ]] && [[ $K_IMG == Image* ]]
    do
        _error "$MSG_ERR_IMG ${RED}${K_IMG}"
        _prompt "$MSG_ASK_IMG"
        read -r -e K_IMG
    done
    K_IMG=${BOOT_DIR}/${K_IMG}
    cd "$DIR" || (
        _error "$MSG_ERR_DIR ${RED}${DIR}"
        _exit
    )
}


# Request to run again failed command.
# Validation checks are not needed here.
_ask_for_run_again() {
    _confirm "$MSG_RUN_AGAIN ?" "[y/N]"
    case $CONFIRM in
        y|Y|yes|Yes|YES)
            RUN_AGAIN=True
            ;;
        *)
            export RUN_AGAIN=False
    esac
}


# Request the installation of missing packages.
# Warn the user that when false the script may crash.
# Validation checks are not needed here.
_ask_for_install_pkg() {
    _confirm "$MSG_ASK_PKG $PACKAGE ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            INSTALL_PKG=False
            _error "$MSG_ERR_DEP ${RED}${PACKAGE}"\
                   "${YELL}${MSG_ERR_MFAIL}"
            ;;
        *)
            export INSTALL_PKG=True
    esac
}


# Request to clone missing tookchains.
# Warn the user and exit the script when false.
# Validation checks are not needed here.
_ask_for_clone_toolchain() {
    _confirm "$MSG_ASK_CLONE_TC $1 ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            CLONE_TC=False
            _error "$MSG_ERR_TCDIR ${RED}$1"\
                   "${YELL}${MSG_ERR_SEE_CONF}"
            _exit
            ;;
        *)
            export CLONE_TC=True
    esac
}


# Request to clone missing AnyKernel repo.
# Warn the user and exit the script when false.
# Validation checks are not needed here.
_ask_for_clone_anykernel() {
    _confirm "$MSG_ASK_CLONE_AK3 ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            CLONE_AK=False
            _error "$MSG_ERR_PATH ${RED}AnyKernel"\
                   "${YELL}${MSG_ERR_SEE_CONF}"
            _exit
            ;;
        *)
            export CLONE_AK=True
    esac
}

