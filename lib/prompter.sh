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


_ask_for_kernel_dir() {
    # Question to get the kernel location.
    # Validation checks the presence of the "configs"
    # folder corresponding to the current architecture.
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


_ask_for_toolchain() {
    # Question to get the toolchain to use.
    # Validation checks are not needed here.
    export N="[Y/n]"
    _confirm "${MSG_ASK_TC}: $DEFAULT_COMPILER ?"
    case $CONFIRM in
        n|N|no|No|NO)
            PROMPT_TYPE="echo"
            _prompt "$MSG_SELECT_TC :"
            select COMPILER in Proton-Clang Eva-GCC Proton-GCC
            do
                test -n "$COMPILER" && break
                _error "$MSG_ERR_SELECT"
            done
            unset $PROMPT_TYPE
            ;;
        *)
            export COMPILER=$DEFAULT_COMPILER
    esac
}


_ask_for_codename() {
    # Question to get the device codename.
    # Validation checks REGEX to prevent invalid string.
    # Match "letters" and "numbers" and "-" and "_" only.
    # Should be at least "3" characters long and maximum "20".
    # Device codename can't start with "_" or "-" characters.
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


_ask_for_defconfig() {
    # Prompt to select the defconfig file to use.
    # Validation checks are not needed here.
    PROMPT_TYPE="echo"
    config="${KERNEL_DIR}/arch/${ARCH}/configs"
    cd "$config" || \
        (_error "$MSG_ERR_DIR ${RED}${config}"; _exit)
    _prompt "$MSG_ASK_DEF :"
    select DEFCONFIG in *_defconfig
    do
        test -n "$DEFCONFIG" && break
        _error "$MSG_ERR_SELECT"
    done
    cd "$DIR" || \
        (_error "$MSG_ERR_DIR ${RED}${DIR}"; _exit)
    unset "$PROMPT_TYPE"
}


_ask_for_menuconfig() {
    # Request a "make menuconfig" command.
    # Validation checks are not needed here.
    export N="[y/N]"
    _confirm "$MSG_ASK_CONF ?"
    case $CONFIRM in
        y|Y|yes|Yes|YES)
            MENUCONFIG=True
            ;;
        *)
            export MENUCONFIG=False
    esac
}


_ask_for_cores() {
    # Question to get the number of CPU cores to use.
    # Validation checks for a valid number corresponding
    # to the amount of available CPU cores (no limits here).
    # Otherwise all available CPU cores will be used.
    export N="[Y/n]"
    CPU=$(nproc --all)
    _confirm "$MSG_ASK_CPU ?"
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
            CORES=$CPU
    esac
}


_ask_for_telegram() {
    # Request the upload of build status on Telegram.
    # Validation checks are not needed here.
    if [[ $TELEGRAM_CHAT_ID ]] && \
            [[ $TELEGRAM_BOT_TOKEN ]]
    then
        export N="[y/N]"
        _confirm "$MSG_ASK_TG ?"
        case $CONFIRM in
            y|Y|yes|Yes|YES)
                BUILD_STATUS=True
                ;;
            *)
                export BUILD_STATUS=False
        esac
    fi
}


_ask_for_make_clean() {
    # Request "make clean" and "make mrproper" commands.
    # Validation checks are not needed here.
    export N="[y/N]"
    _confirm "${MSG_ASK_MCLEAN}: v$LINUX_VERSION ?"
    case $CONFIRM in
        y|Y|yes|Yes|YES)
            MAKE_CLEAN=True
            ;;
        *)
            export MAKE_CLEAN=False
    esac
}


_ask_for_save_defconfig() {
    # Request to save and use the modified defconfig.
    # Otherwise request to continue with original one.
    # Validation checks are not needed here.
    export N="[Y/n]"
    _confirm "${MSG_ASK_SAVE_DEF}: $DEFCONFIG ?"
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


_ask_for_new_build() {
    # Request "make" command for kernel build.
    # Validation checks are not needed here.
    export N="[Y/n]"
    _confirm \
        "$MSG_START ${TAG}-${CODENAME}-${LINUX_VERSION} ?"
    case $CONFIRM in
        n|N|no|No|NO)
            NEW_BUILD=False
            ;;
        *)
            export NEW_BUILD=True
    esac
}


_ask_for_run_again() {
    # Request to run again failed command.
    # Validation checks are not needed here.
    export N="[y/N]"
    _confirm "$MSG_RUN_AGAIN ?"
    case $CONFIRM in
        y|Y|yes|Yes|YES)
            RUN_AGAIN=True
            ;;
        *)
            export RUN_AGAIN=False
    esac
}


_ask_for_flashable_zip() {
    # Request the creation of flashable zip.
    # Validation checks are not needed here.
    export N="[y/N]"
    _confirm \
        "$MSG_ASK_ZIP ${TAG}-${CODENAME}-${LINUX_VERSION} ?"
    case $CONFIRM in
        y|Y|yes|Yes|YES)
            FLASH_ZIP=True
            ;;
        *)
            export FLASH_ZIP=False
    esac
}


_ask_for_kernel_image() {
    # Question to get the kernel image to zip.
    # Validation checks the presence of this file in
    # "boot" folder and verify it starts with "Image".
    boot="${DIR}/out/${CODENAME}/arch/${ARCH}/boot"
    cd "$boot" || \
        (_error "$MSG_ERR_DIR ${RED}${boot}"; _exit)
    _prompt "$MSG_ASK_IMG :"
    read -r -e K_IMG
    until [[ -f $K_IMG ]] && [[ $K_IMG == Image* ]]
    do
        _error "$MSG_ERR_IMG ${RED}${K_IMG}"
        _prompt "$MSG_ASK_IMG"
        read -r -e K_IMG
    done
    K_IMG="${DIR}/out/${CODENAME}/arch/${ARCH}/boot/${K_IMG}"
    cd "$DIR" || (_error "$MSG_ERR_DIR ${RED}${DIR}"; _exit)
}


_ask_for_install_pkg() {
    # Request the installation of missing packages.
    # Warn the user that when false the script may crash.
    # Validation checks are not needed here.
    export N="[Y/n]"
    _confirm "$MSG_ASK_PKG $PACKAGE ?"
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


_ask_for_clone_toolchain() {
    # Request to clone missing tookchains.
    # Warn the user and exit the script when false.
    # Validation checks are not needed here.
    export N="[Y/n]"
    _confirm "$MSG_ASK_CLONE_TC $TC ?"
    case $CONFIRM in
        n|N|no|No|NO)
            CLONE_TC=False
            _error "$MSG_ERR_TCDIR ${RED}${TC}"\
                   "${YELL}${MSG_ERR_SEE_CONF}"
            _exit
            ;;
        *)
            export CLONE_TC=True
    esac
}


_ask_for_clone_anykernel() {
    # Request to clone missing AnyKernel repo.
    # Warn the user and exit the script when false.
    # Validation checks are not needed here.
    export N="[Y/n]"
    _confirm "$MSG_ASK_CLONE_AK3 ?"
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


_ask_for_save_config() {
    # Request to save the modified config.sh before update.
    # Validation checks are not needed here.
    export N="[Y/n]"
    _confirm "$MSG_SAVE_USER_CONFIG ?"
    case $CONFIRM in
        n|N|no|No|NO)
            SAVE_CONFIG=False
            ;;
        *)
            export SAVE_CONFIG=True
    esac
}

