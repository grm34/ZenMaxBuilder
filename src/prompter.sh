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
        _prompt "$MSG_ASK_DEV :" 1
        read -r CODENAME
        regex="^[a-zA-Z0-9][a-zA-Z0-9_-]{2,19}$"
        until [[ $CODENAME =~ $regex ]]
        do
            _error "$MSG_ERR_DEV ${RED}$CODENAME"
            _prompt "$MSG_ASK_DEV :" 1
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
        _prompt "$MSG_ASK_KDIR :" 1
        read -r -e KERNEL_DIR
        until [[ -d ${KERNEL_DIR}/arch/${ARCH}/configs ]]
        do
            _error "$MSG_ERR_KDIR ${RED}$KERNEL_DIR"
            _prompt "$MSG_ASK_KDIR :" 1
            read -r -e KERNEL_DIR
        done
    fi
}


# Prompt to select the defconfig file to use.
# Choices: all defconfig files located in "configs"
# folder corresponding to the current architecture.
# Validation checks are not needed here.
_ask_for_defconfig() {
    folder=${KERNEL_DIR}/arch/${ARCH}/configs
    CONF_DIR=${folder//\/\//\/}
    _cd "$CONF_DIR" "$MSG_ERR_DIR ${RED}$CONF_DIR"
    _prompt "$MSG_ASK_DEF :" 2
    select DEFCONFIG in *_defconfig
    do
        [[ $DEFCONFIG ]] && break
        _error "$MSG_ERR_SELECT"
    done
    _cd "$DIR" "$MSG_ERR_DIR ${RED}$DIR"
}


# Request a "make menuconfig" command.
# Validation checks are not needed here.
_ask_for_menuconfig() {
    _confirm "$MSG_ASK_CONF ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export MENUCONFIG=True
    esac
}


# Request to save MENUCONFIG edited configuration,
# otherwise request to continue with the original one.
# Validation checks REGEX to prevent invalid string.
# Match "letters" and "numbers" and "-" and "_" only.
# Should be at least "3" characters long and maximum "26".
# Defcongig file can't start with "_" or "-" characters.
_ask_for_save_defconfig() {
    _confirm "${MSG_ASK_SAVE_DEF} ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            export SAVE_DEFCONFIG=False
            _confirm "$MSG_ASK_USE_DEF $DEFCONFIG ?" "[Y/n]"
            case $CONFIRM in n|N|no|No|NO)
                export ORIGINAL_DEFCONFIG=False
            esac
            ;;
        *)
            _prompt "$MSG_ASK_DEF_NAME :" 1
            read -r DEFCONFIG
            regex="^[a-zA-Z0-9][a-zA-Z0-9_-]{2,25}$"
            until [[ $DEFCONFIG =~ $regex ]]
            do
                _error "$MSG_ERR_DEF_NAME ${RED}$DEFCONFIG"
                _prompt "$MSG_ASK_DEF_NAME :" 1
                read -r DEFCONFIG
            done
            export DEFCONFIG=${DEFCONFIG}_defconfig
    esac
}


# Question to get the toolchain to use.
# Choices: Proton-Clang Eva-GCC Proton-GCC
# Validation checks are not needed here.
_ask_for_toolchain() {
    if [[ $COMPILER == default ]]
    then
        _prompt "$MSG_SELECT_TC :" 2
        select COMPILER in $PROTON_CLANG_NAME \
            $EVA_GCC_NAME $PROTON_GCC_NAME $LOS_GCC_NAME
        do
            [[ $COMPILER ]] && break
            _error "$MSG_ERR_SELECT"
        done
    fi
}


# Request to edit Makefile CROSS_COMPILE.
# Validation checks are not needed here.
_ask_for_edit_cross_compile() {
    _confirm "$MSG_ASK_CC $COMPILER ?" "[Y/n]"
    case $CONFIRM in n|N|no|No|NO)
        export EDIT_CC=False
    esac
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
            _prompt "$MSG_ASK_CORES :" 1
            read -r CORES
            until (( 1<=CORES && CORES<=CPU ))
            do
                _error "$MSG_ERR_CORES ${RED}${CORES}"\
                       "${YELL}(${MSG_ERR_TOTAL}: ${CPU})"
                _prompt "$MSG_ASK_CORES :" 1
                read -r CORES
            done
            ;;
        *) export CORES=$CPU
    esac
}


# Request "make clean" and "make mrproper" commands.
# Validation checks are not needed here.
_ask_for_make_clean() {
    _confirm "${MSG_ASK_MCLEAN}: v$LINUX_VERSION ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export MAKE_CLEAN=True
    esac
}


# Request "make" command for kernel build.
# Validation checks are not needed here.
_ask_for_new_build() {
    _confirm \
        "$MSG_START ${TAG}-${CODENAME}-$LINUX_VERSION ?" \
        "[Y/n]"
    case $CONFIRM in n|N|no|No|NO)
        export NEW_BUILD=False
    esac
}


# Request the upload of build status on Telegram.
# Validation checks are not needed here.
_ask_for_telegram() {
    if [[ $TELEGRAM_CHAT_ID ]] && \
        [[ $TELEGRAM_BOT_TOKEN ]]
    then
        _confirm "$MSG_ASK_TG ?" "[y/N]"
        case $CONFIRM in y|Y|yes|Yes|YES)
            export BUILD_STATUS=True
        esac
    fi
}


# Request the creation of flashable zip.
# Validation checks are not needed here.
_ask_for_flashable_zip() {
    _confirm \
        "$MSG_ASK_ZIP ${TAG}-${CODENAME}-$LINUX_VERSION ?" \
        "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export FLASH_ZIP=True
    esac
}


# Question to get the kernel image to zip.
# Validation checks the presence of this file in
# "boot" folder and verify it starts with "Image".
_ask_for_kernel_image() {
    _cd "$BOOT_DIR" "$MSG_ERR_DIR ${RED}$BOOT_DIR"
    _prompt "$MSG_ASK_IMG :" 1
    read -r -e K_IMG
    until [[ -f $K_IMG ]] && [[ $K_IMG == Image* ]]
    do
        _error "$MSG_ERR_IMG ${RED}$K_IMG"
        _prompt "$MSG_ASK_IMG" 1
        read -r -e K_IMG
    done
    K_IMG=${BOOT_DIR}/$K_IMG
    _cd "$DIR" "$MSG_ERR_DIR ${RED}$DIR"
}


# Request to run again failed command.
# Validation checks are not needed here.
_ask_for_run_again() {
    RUN_AGAIN=False
    _confirm "$MSG_RUN_AGAIN ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export RUN_AGAIN=True
    esac
}


# Request the installation of missing packages.
# Warn the user that when false the script may crash.
# Validation checks are not needed here.
_ask_for_install_pkg() {
    _confirm "$MSG_ASK_PKG $1 ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _error WARN "$MSG_ERR_DEP ${RED}${PACKAGE}"\
                        "${YELL}$MSG_ERR_MFAIL"
            ;;
        *) export INSTALL_PKG=True
    esac
}


# Request to clone missing tookchains.
# Warn the user and exit the script when false.
# Validation checks are not needed here.
_ask_for_clone_toolchain() {
    _confirm "$MSG_ASK_CLONE_TC $1 ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _error "$MSG_ERR_TCDIR ${RED}$1"\
                   "${YELL}$MSG_ERR_SEE_CONF"
            _exit
            ;;
        *) export CLONE_TC=True
    esac
}


# Request to clone missing AnyKernel repo.
# Warn the user and exit the script when false.
# Validation checks are not needed here.
_ask_for_clone_anykernel() {
    _confirm "$MSG_ASK_CLONE_AK3 ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _error "$MSG_ERR_PATH ${RED}AnyKernel"\
                   "${YELL}$MSG_ERR_SEE_CONF"
            _exit
            ;;
        *) export CLONE_AK=True
    esac
}

