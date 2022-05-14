#!/bin/bash
###!/usr/bin/bash
###!/usr/bin/env bash

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

# ABSOLUTE PATH
DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$DIR" || exit $?

# LOCKFILE
exec 201> "$(basename "$0").lock"

# JOB CONTROL
(set -o posix; set)> "${DIR}/bashvar"
set -m -E -o pipefail #-b -v

# USER LANGUAGE
LANGUAGE=${DIR}/lang/${LANG:0:2}.cfg
if [[ -f $LANGUAGE ]]
then # shellcheck source=/dev/null
    source "$LANGUAGE"
else # shellcheck source=/dev/null
    source "${DIR}/lang/en.cfg"
fi

# USER CONFIGURATION
if [[ -f ${DIR}/etc/user.cfg ]]
then # shellcheck source=/dev/null
    source "${DIR}/etc/user.cfg"
else # shellcheck source=/dev/null
    source "${DIR}/etc/settings.cfg"
fi

# SOURCE ALL FUNCTIONS
# shellcheck source=src/manager.sh
source "${DIR}/src/manager.sh"
# shellcheck source=src/requirements.sh
source "${DIR}/src/requirements.sh"
# shellcheck source=src/telegram.sh
source "${DIR}/src/telegram.sh"
# shellcheck source=src/zip.sh
source "${DIR}/src/zip.sh"
# shellcheck source=src/maker.sh
source "${DIR}/src/maker.sh"
# shellcheck source=src/questioner.sh
source "${DIR}/src/questioner.sh"
# shellcheck source=src/options.sh
source "${DIR}/src/options.sh"
# shellcheck source=/dev/null
source "${DIR}/etc/excluded.cfg"

# BAN ALL ('n00bz')
_terminal_colors
if [[ ! -t 0 ]]
then # Terminal mandatory
    _error "$MSG_ERR_TERM"
    _exit
elif [[ $(tput cols) -lt 76 ]] || [[ $(tput lines) -lt 12 ]]
then # Terminal min size
    _error "$MSG_ERR_SIZE"
    _exit
elif [[ $(uname) != Linux ]]
then # Linux mandatory
    _error "$MSG_ERR_LINUX"
    _exit
elif ! flock -n 201
then # Single instance
    _error "$MSG_ERR_DUPE"
    _exit
elif [[ $KERNEL_DIR != default  ]] && \
    [[ ! -f ${KERNEL_DIR}/Makefile ]] && \
    [[ ! -d ${KERNEL_DIR}/arch ]]
then # Bad kernel dir
    _error "$MSG_ERR_KDIR"
    _exit
elif [[ ! $COMPILER =~ ^(default|${PROTON_GCC_NAME}|\
    ${PROTON_CLANG_NAME}|${EVA_GCC_NAME}|${LOS_GCC_NAME}) ]]
then # Bad compiler
    _error "$MSG_ERR_COMPILER"
    _exit
fi

# TRAP INTERRUPT SIGNALS
trap '_error $MSG_ERR_KBOARD; _exit' INT QUIT TSTP CONT

# DATE AND TIME
if [[ $TIMEZONE == default ]]
then _get_user_timezone; fi
DATE=$(TZ=$TIMEZONE date +%Y-%m-%d)
TIME=$(TZ=$TIMEZONE date +%Hh%Mm%Ss)

# TRANSFROM LONG OPTIONS TO SHORT
for opt in "$@"
do
    shift
    case $opt in
        "--help")   set -- "$@" "-h"; break;;
        "--start")  set -- "$@" "-s";;
        "--update") set -- "$@" "-u";;
        "--msg")    set -- "$@" "-m";;
        "--file")   set -- "$@" "-f";;
        "--zip")    set -- "$@" "-z";;
        "--list")   set -- "$@" "-l";;
        "--tag")    set -- "$@" "-t";;
        "--debug")  set -- "$@" "-d";;
        *)          set -- "$@" "$opt"
    esac
done

# HANDLES OPTIONS ARGUMENTS
if [[ $# -eq 0 ]]
then _error "$MSG_ERR_EOPT"; _exit; fi
while getopts ':hsuldt:m:f:z:' option
do
    case $option in
        h)  clear; _terminal_banner; _usage
            rm -f "./bashvar"; exit 0;;
        u)  _install_dependencies; _full_upgrade; _exit;;
        m)  _install_dependencies; _send_msg_option; _exit;;
        f)  _install_dependencies; _send_file_option; _exit;;
        z)  _install_dependencies; _create_zip_option; _exit;;
        l)  _install_dependencies; _list_all_kernels; _exit;;
        t)  _install_dependencies; _get_linux_tag; _exit;;
        s)  _install_dependencies; clear; _terminal_banner;;
        d)  _install_dependencies; clear; _terminal_banner
            export DEBUG_MODE=True;;
        :)  _error "$MSG_ERR_MARG ${RED}-$OPTARG"
            _exit;;
        \?) _error "$MSG_ERR_IOPT ${RED}-$OPTARG"
            _exit
    esac
done
if [[ $OPTIND -eq 1 ]]
then _error "$MSG_ERR_IOPT ${RED}$1"; _exit; fi
shift $(( OPTIND - 1 ))


#######################
### START NEW BUILD ###
#######################
_note "$MSG_NOTE_START $DATE"
_ask_for_codename

# CREATE DEVICE FOLDERS
folders=(builds logs toolchains out)
for folder in "${folders[@]}"
do
    if [[ ! -d ${DIR}/${folder}/$CODENAME ]] && \
        [[ $folder != toolchains ]]
    then
        _check mkdir -p "${DIR}/${folder}/$CODENAME"
    elif [[ ! -d ${DIR}/$folder ]]
    then
        _check mkdir "${DIR}/$folder"
    fi
done

# EXPORT WORKING FOLDERS
export OUT_DIR=${DIR}/out/$CODENAME
export BUILD_DIR=${DIR}/builds/$CODENAME
export PROTON_DIR=${DIR}/toolchains/$PROTON_DIR
export GCC_ARM64_DIR=${DIR}/toolchains/$GCC_ARM64_DIR
export GCC_ARM_DIR=${DIR}/toolchains/$GCC_ARM_DIR
export LOS_ARM64_DIR=${DIR}/toolchains/$LOS_ARM64_DIR
export LOS_ARM_DIR=${DIR}/toolchains/$LOS_ARM_DIR

# ASK QUESTIONS TO THE USER
_ask_for_kernel_dir
_ask_for_defconfig
_ask_for_menuconfig
_ask_for_toolchain
_ask_for_cores

# CLONE AK3 AND REQUIRED TOOLCHAINS
_clone_toolchains
_clone_anykernel

# MAKE KERNEL VERSION
_export_path_and_options
_handle_makefile_cross_compile
_note "${MSG_NOTE_LINUXVER}..."
make -C "$KERNEL_DIR" kernelversion \
    | grep -v make > linuxver & wait $!
LINUX_VERSION=$(cat linuxver)
KERNEL_NAME=${TAG}-${CODENAME}-$LINUX_VERSION

# MAKE CLEAN
_ask_for_make_clean
if [[ $MAKE_CLEAN == True ]]
then _make_clean; _make_mrproper; rm -rf "$OUT_DIR"
fi

# MAKE DEFCONFIG
_make_defconfig
if [[ $MENUCONFIG == True ]]
then
    _make_menuconfig
    _ask_for_save_defconfig
    if [[ $SAVE_DEFCONFIG != False ]]
    then _save_defconfig
    else
        if [[ $ORIGINAL_DEFCONFIG == False ]]
        then
            _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."
            _exit
        fi
    fi
fi

# MAKE KERNEL
_ask_for_new_build
if [[ $NEW_BUILD == False ]]
then _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."; _exit
else
    _ask_for_telegram
    START_TIME=$(TZ=$TIMEZONE date +%s)
    LOG=${DIR}/logs/${CODENAME}/${KERNEL_NAME}_${DATE}_${TIME}.log
    _terminal_banner > "$LOG"
    _make_build | tee -a "$LOG"
fi

# CHECK FOR SUCCESSFUL BUILD
_get_build_time
BOOT_DIR="${DIR}/out/${CODENAME}/arch/${ARCH}/boot"
# shellcheck disable=SC2012
most_recent_file=$(ls -Art "$BOOT_DIR" 2>/dev/null | tail -n 1)
ftime=$(stat -c %Z "${BOOT_DIR}/${most_recent_file}" 2>/dev/null)
if [[ ! -d $BOOT_DIR ]] || [[ -z $(ls -A "$BOOT_DIR") ]] || \
    [[ $ftime < $START_TIME ]]
then _error "$MSG_ERR_MAKE"; _exit; fi

# RETURN BUILD STATUS
_note "$MSG_NOTE_SUCCESS $BUILD_TIME !"
_send_success_build_status

# CREATE FLASHABLE SIGNED ZIP
_ask_for_flashable_zip
if [[ $FLASH_ZIP == True ]]
then
    _ask_for_kernel_image
    _zip "${KERNEL_NAME}-$DATE" "$K_IMG" \
        "$BUILD_DIR" | tee -a "$LOG"
    _sign_zip "${BUILD_DIR}/${KERNEL_NAME}-$DATE" \
        | tee -a "$LOG"
    _note "$MSG_NOTE_ZIPPED !"
fi

# UPLOAD THE BUILD AND EXIT
_upload_signed_build
_clean_anykernel
_exit

