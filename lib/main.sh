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

# Date & Time
DATE=$(TZ=${TIMEZONE} date +%Y-%m-%d)
TIME=$(TZ=${TIMEZONE} date +%Hh%Mm%Ss)

# Get absolute path
DIRNAME=$(dirname "${0}")
DIR=${PWD}/${DIRNAME}

# Bash job control
set > "${DIR}/bashvar"
set -m -E -o pipefail #-b -v

# App Language
LANGUAGE="${DIR}/lang/${LANG:0:2}.sh"
if test -f "${LANGUAGE}"
then
    # shellcheck source=/dev/null
    source "${LANGUAGE}"
else
    # shellcheck source=/dev/null
    source "${DIR}/lang/en.sh"
fi

# shellcheck source=config.sh
source "${DIR}/config.sh"
# shellcheck source=lib/manager.sh
source "${DIR}/lib/manager.sh"
# shellcheck source=lib/requirements.sh
source "${DIR}/lib/requirements.sh"
# shellcheck source=lib/telegram.sh
source "${DIR}/lib/telegram.sh"
# shellcheck source=lib/flasher.sh
source "${DIR}/lib/flasher.sh"
# shellcheck source=lib/maker.sh
source "${DIR}/lib/maker.sh"
# shellcheck source=lib/prompter.sh
source "${DIR}/lib/prompter.sh"
# shellcheck source=lib/updater.sh
source "${DIR}/lib/updater.sh"

# Ban all ('n00bz')
if [[ $(uname) != Linux ]]
then
    _error "${MSG_ERR_LINUX}"
    _exit
elif [[ ! -f ${PWD}/config.sh ]] || [[ ! -d ${PWD}/lib ]]
then
    _error "${MSG_ERR_PWD}"
    _exit
elif [[ $KERNEL_DIR != default  ]] && \
        [[ ! -f $KERNEL_DIR/Makefile ]]
then
    _error "${MSG_ERR_KDIR}"
    _exit
fi

# Transform long opts to short
for OPT in "${@}"
do
    shift
    case ${OPT} in
        "--help") set -- "${@}" "-h"; break;;
        "--start") set -- "${@}" "-s";;
        "--update") set -- "${@}" "-u";;
        "--msg") set -- "${@}" "-m";;
        "--file") set -- "${@}" "-f";;
        "--zip") set -- "${@}" "-z";;
        "--list") set -- "${@}" "-l";;
        "--tag") set -- "${@}" "-t";;
        *) set -- "${@}" "${OPT}"
    esac
done

# Handle app opts
if [[ ${#} -eq 0 ]]
then
    _error "${MSG_ERR_EOPT}"
    _exit
fi
while getopts ':hsult:m:f:z:' OPTION
do
    case ${OPTION} in
        h)  _neternels_builder_banner; _usage
            _check rm "./bashvar"; exit 0;;
        u)  _full_upgrade; _exit;;
        m)  _send_msg_option; _exit;;
        f)  _send_file_option; _exit;;
        z)  _create_zip_option; _exit;;
        l)  _list_all_kernels; _exit;;
        t)  _get_linux_tag; _exit;;
        s)  _neternels_builder_banner;;
        :)  _error "${MSG_ERR_MARG} ${RED}-${OPTARG}"
            _exit;;
        \?) _error "${MSG_ERR_IOPT} ${RED}-${OPTARG}"
            _exit
    esac
done
if [[ ${OPTIND} -eq 1 ]]
then
    _error "${MSG_ERR_IOPT} ${RED}${1}"
    _exit
fi

# Remove opts from positional parameters
shift $(( OPTIND - 1 ))

# Trap interrupt signals
trap '_error ${MSG_ERR_KBOARD}; _exit' INT QUIT TSTP CONT


#######################
### Start new build ###
#######################
_note "${MSG_NOTE_START} ${DATE}"

# Get device codename
_ask_for_codename

# Create device folders
FOLDERS=(builds logs toolchains out)
for FOLDER in "${FOLDERS[@]}"
do
    if [[ ! -d ${DIR}/${FOLDER}/${CODENAME} ]] && \
            [[ ${FOLDER} != toolchains ]]
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
if [[ ${BUILDER} == default ]]; then BUILDER=$(whoami); fi
if [[ ${HOST} == default ]]; then HOST=$(uname -n); fi
if [[ ${LLVM} == True ]]; then export LLVM=1; fi
export KBUILD_BUILD_USER=${BUILDER}
export KBUILD_BUILD_HOST=${HOST}
export PLATFORM_VERSION=${PLATFORM_VERSION}
export ANDROID_MAJOR_RELEASE=${ANDROID_MAJOR_RELEASE}

# Export TC path and options
_export_path_and_options

# Make kernel version
_note "${MSG_NOTE_LINUXVER}..."
make -C "${KERNEL_DIR}" kernelversion \
    | grep -v make > linuxver & wait ${!}
LINUX_VERSION=$(cat linuxver)
KERNEL_NAME=${TAG}-${CODENAME}-${LINUX_VERSION}

# Make clean
_ask_for_make_clean
_clean_anykernel
if [[ ${MAKE_CLEAN} == True ]]
then
    _make_clean
    _make_mrproper
    _check rm -rf "${OUT_DIR}"
fi

# Make defconfig
_make_defconfig

# Make menuconfig
if [[ ${MENUCONFIG} == True ]]
then
    _make_menuconfig
    _ask_for_save_defconfig
    if [[ ${SAVE_DEFCONFIG} == True ]]
    then
        _save_defconfig
    else
        if [[ ${ORIGINAL_DEFCONFIG} == False ]]
        then
            _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."
            _exit
        fi
    fi
fi

# Make new build
_ask_for_new_build
if [[ ${NEW_BUILD} == False ]]
then
    _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."
    _exit
else
    # TG build status
    _ask_for_telegram
    _set_html_status_msg

    # Build logs
    START_TIME=$(TZ=${TIMEZONE} date +%s)
    LOG=${DIR}/logs/${CODENAME}/${KERNEL_NAME}_${DATE}_${TIME}.log

    # Make kernel
    _make_build | tee -a "${LOG}"
fi

# Get build time
END_TIME=$(TZ=${TIMEZONE} date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
M=$((BUILD_TIME / 60))
S=$((BUILD_TIME % 60))

# Display build status
_note "${MSG_NOTE_SUCCESS} ${M}m${S}s"
_send_success_build_status

# Create flashable zip
_ask_for_flashable_zip
if [[ ${FLASH_ZIP} == True ]]
then
    _ask_for_kernel_image
    _create_flashable_zip | tee -a "${LOG}"
    _sign_flashable_zip | tee -a "${LOG}"
fi

# Upload build and exit
_upload_signed_build
_clean_anykernel
_exit

