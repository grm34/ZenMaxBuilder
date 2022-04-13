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

# Create ZMB lock
exec 201> "$(basename "$0").lock"

# Get absolute path
DIRNAME=$(dirname "$0")
DIR=${PWD}/${DIRNAME}
cd "$DIR" || exit $?

# Bash job control
(set -o posix; set)> "${DIR}/bashvar"
set -m -E -o pipefail #-b -v

# App Language
LANGUAGE=${DIR}/lang/${LANG:0:2}.cfg
if [[ -f $LANGUAGE ]]
then
    # shellcheck source=/dev/null
    source "$LANGUAGE"
else
    # shellcheck source=/dev/null
    source "${DIR}/lang/en.cfg"
fi

# shellcheck source=/dev/null
source "${DIR}/zmb.cfg"
# shellcheck source=src/manager.sh
source "${DIR}/src/manager.sh"
# shellcheck source=src/requirements.sh
source "${DIR}/src/requirements.sh"
# shellcheck source=src/telegram.sh
source "${DIR}/src/telegram.sh"
# shellcheck source=src/flasher.sh
source "${DIR}/src/flasher.sh"
# shellcheck source=src/maker.sh
source "${DIR}/src/maker.sh"
# shellcheck source=src/prompter.sh
source "${DIR}/src/prompter.sh"
# shellcheck source=src/options.sh
source "${DIR}/src/options.sh"
# shellcheck source=/dev/null
source "${DIR}/etc/excluded.cfg"

# Ban all ('n00bz')
if [[ ! -t 0 ]]
then    # Terminal mandatory
    _error "$MSG_ERR_TERM"
    _exit
elif [[ $(uname) != Linux ]]
then    # Linux mandatory
    _error "$MSG_ERR_LINUX"
    _exit
elif ! flock -n 201
then    # Single instance
    _error "$MSG_ERR_DUPE"
    _exit
elif [[ $KERNEL_DIR != default  ]] && \
    [[ ! -f ${KERNEL_DIR}/Makefile ]] && \
    [[ ! -d ${KERNEL_DIR}/arch ]]
then    # Bad kernel dir
    _error "$MSG_ERR_KDIR"
    _exit
fi

# Set Date & Time
if [[ $TIMEZONE == default ]]
then
    _get_user_timezone
fi
DATE=$(TZ=$TIMEZONE date +%Y-%m-%d)
TIME=$(TZ=$TIMEZONE date +%Hh%Mm%Ss)

# Transform long opts to short
for OPT in "$@"
do
    shift
    case $OPT in
        "--help") set -- "$@" "-h"; break;;
        "--start") set -- "$@" "-s";;
        "--update") set -- "$@" "-u";;
        "--msg") set -- "$@" "-m";;
        "--file") set -- "$@" "-f";;
        "--zip") set -- "$@" "-z";;
        "--list") set -- "$@" "-l";;
        "--tag") set -- "$@" "-t";;
        *) set -- "$@" "$OPT"
    esac
done

# Handle app opts
if [[ $# -eq 0 ]]
then
    _error "$MSG_ERR_EOPT"
    _exit
fi
while getopts ':hsult:m:f:z:' OPTION
do
    case $OPTION in
        h)  _terminal_banner; _usage
            rm "./bashvar" || sleep 0.1; exit 0;;
        u)  _full_upgrade; _exit;;
        m)  _send_msg_option; _exit;;
        f)  _send_file_option; _exit;;
        z)  _create_zip_option; _exit;;
        l)  _list_all_kernels; _exit;;
        t)  _get_linux_tag; _exit;;
        s)  _terminal_banner;;
        :)  _error "$MSG_ERR_MARG ${RED}-${OPTARG}"
            _exit;;
        \?) _error "$MSG_ERR_IOPT ${RED}-${OPTARG}"
            _exit
    esac
done
if [[ $OPTIND -eq 1 ]]
then
    _error "$MSG_ERR_IOPT ${RED}$1"
    _exit
fi

# Remove opts from positional parameters
shift $(( OPTIND - 1 ))

# Trap interrupt signals
trap '_error $MSG_ERR_KBOARD; _exit' INT QUIT TSTP CONT


#######################
### Start new build ###
#######################
_note "$MSG_NOTE_START $DATE"

# Get device codename
_ask_for_codename

# Create device folders
FOLDERS=(builds logs toolchains out)
for FOLDER in "${FOLDERS[@]}"
do
    if [[ ! -d ${DIR}/${FOLDER}/${CODENAME} ]] && \
        [[ $FOLDER != toolchains ]]
    then
        _check mkdir -p "${DIR}/${FOLDER}/${CODENAME}"
    elif [[ ! -d ${DIR}/${FOLDER} ]]
    then
        _check mkdir "${DIR}/${FOLDER}"
    fi
done

# Export working folders
export OUT_DIR=${DIR}/out/${CODENAME}
export BUILD_DIR=${DIR}/builds/${CODENAME}

# Get user configuration
_ask_for_kernel_dir
_ask_for_defconfig
_ask_for_menuconfig
_ask_for_toolchain
_ask_for_cores

# Install and clone requirements
_install_dependencies
_clone_toolchains
_clone_anykernel

# Export target variables
if [[ $BUILDER == default ]]; then BUILDER=$(whoami); fi
if [[ $HOST == default ]]; then HOST=$(uname -n); fi
if [[ $LLVM == True ]]; then export LLVM=1; fi
export KBUILD_BUILD_USER=$BUILDER
export KBUILD_BUILD_HOST=$HOST
export PLATFORM_VERSION=$PLATFORM_VERSION
export ANDROID_MAJOR_RELEASE=$ANDROID_MAJOR_RELEASE

# Export TC path and options
_export_path_and_options

# Make kernel version
_note "${MSG_NOTE_LINUXVER}..."
make -C "$KERNEL_DIR" kernelversion \
    | grep -v make > linuxver & wait $!
LINUX_VERSION=$(cat linuxver)
KERNEL_NAME=${TAG}-${CODENAME}-${LINUX_VERSION}

# Make clean
_ask_for_make_clean
_clean_anykernel
if [[ $MAKE_CLEAN == True ]]
then
    _make_clean
    _make_mrproper
    rm -rf "$OUT_DIR" || sleep 0.1
fi

# Make defconfig
_make_defconfig

# Make menuconfig
if [[ $MENUCONFIG == True ]]
then
    _make_menuconfig
    _ask_for_save_defconfig
    if [[ $SAVE_DEFCONFIG == True ]]
    then
        _save_defconfig
    else
        if [[ $ORIGINAL_DEFCONFIG == False ]]
        then
            _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."
            _exit
        fi
    fi
fi

# Make new build
_ask_for_new_build
if [[ $NEW_BUILD == False ]]
then
    _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."
    _exit
else
    # TG build status
    _ask_for_telegram
    _set_html_status_msg

    # Build logs
    START_TIME=$(TZ=$TIMEZONE date +%s)
    LOG=${DIR}/logs/${CODENAME}/${KERNEL_NAME}_${DATE}_${TIME}.log
    _terminal_banner > "$LOG"

    # Make kernel
    _make_build | tee -a "$LOG"
fi

# Get build time
END_TIME=$(TZ=$TIMEZONE date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
M=$((BUILD_TIME / 60))
S=$((BUILD_TIME % 60))

# Check if make success
BOOT_DIR=${DIR}/out/${CODENAME}/arch/${ARCH}/boot
most_recent_file=$(find "$BOOT_DIR" -mindepth 1 \
    -maxdepth 1 -type f -mtime -1 2>/dev/null | head -n 1)
file_time=$(stat -c %Z "$most_recent_file" 2>/dev/null)
if [[ ! -d $BOOT_DIR ]] || [[ $file_time < $START_TIME ]]
then
    _error "$MSG_ERR_MAKE"
    _exit
fi

# Display build status
_note "$MSG_NOTE_SUCCESS ${M}m${S}s !"
_send_success_build_status

# Create flashable zip
_ask_for_flashable_zip
if [[ $FLASH_ZIP == True ]]
then
    _ask_for_kernel_image
    _zip "${KERNEL_NAME}-${DATE}" "$K_IMG" \
        "$BUILD_DIR" | tee -a "$LOG"
    _sign_zip "${BUILD_DIR}/${KERNEL_NAME}-${DATE}" \
        | tee -a "$LOG"
    _note "$MSG_NOTE_ZIPPED !"
fi

# Upload build and exit
_upload_signed_build
_clean_anykernel
_exit

