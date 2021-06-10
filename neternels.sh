#!/usr/bin/bash
# shellcheck disable=SC1091
set > /tmp/old_vars.log

#    Copyright (c) 2021 darkmaster @grm34 Neternels Team
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

# Load modules
source manager.sh
source requirements.sh
source secret.sh
source telegram.sh
source user.sh
source flasher.sh
source maker.sh
source prompter.sh

# Build date
DATE=$(TZ=${TIMEZONE} date +%Y-%m-%d)

# Script dir
DIR=${PWD}

# Start
_banner
_note "Starting new kernel build on ${DATE} (...)"

# Ban all n00bz
trap '_error keyboard interrupt!; _exit' 1 2 3 6
if [[ $(uname) != Linux ]]; then
    _error "run this script on Linux!"
    _exit
elif [[ ! -f ${DIR}/user.sh ]] || [[ ! -f ${DIR}/maker.sh ]]; then
    _error "run this script from Neternels-Builder folder!"
    _exit
fi

# Create missing folders
FOLDERS=(builds logs toolchains)
for FOLDER in "${FOLDERS[@]}"; do
    if [[ ! -d ${DIR}/${FOLDER} ]]; then
        mkdir "${DIR}"/"${FOLDER}"
    fi
done

# Get user configuration
_ask_for_kernel_dir
_ask_for_toolchain
_ask_for_codename
_ask_for_defconfig
_ask_for_menuconfig
_ask_for_cores
_ask_for_telegram

# Set logs
TIME=$(TZ=${TIMEZONE} date +%H-%M-%S)
LOG=${DIR}/logs/${CODENAME}_${DATE}_${TIME}.log
printf "Neternels Team @ Development is Life\n" > "${LOG}"

# Install and clone requirements
_install_dependencies | tee -a "${LOG}"
_clone_toolchains | tee -a "${LOG}"
_clone_anykernel | tee -a "${LOG}"

# Set builder (displayed in proc/version)
if [[ ${BUILDER} == default ]]; then BUILDER=$(whoami); fi
if [[ ${HOST} == default ]]; then BUILDER=$(uname -n); fi
export KBUILD_BUILD_USER=${BUILDER}
export KBUILD_BUILD_HOST=${HOST}

# Set out folder
OUT_DIR=${DIR}/out/${CODENAME}
mkdir -p "${OUT_DIR}"

# Make version, clean, defconfig, menuconfig
_note "Make kernel version..."
LINUX_VERSION=$(make -C "${KERNEL_DIR}" kernelversion | grep -v make)
_make_clean_build | tee -a "${LOG}"
_make_defconfig | tee -a "${LOG}"
if [[ ${MENUCONFIG} == True ]]; then _make_menuconfig; fi

# Make new build
_confirm "Do you wish to start NetErnels-${CODENAME}-${LINUX_VERSION}"
case ${CONFIRM} in
    n|N|no|No|NO)
        _error "aborted by user!"
        _exit
        ;;
    *)
        START_TIME=$(TZ=${TIMEZONE} date +%s)
        _make_build | tee -a "${LOG}"
        sleep 5
esac

# Send build status to Terminal
END_TIME=$(TZ=${TIMEZONE} date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
_note "Successfully compiled NetErnels-${CODENAME}-${LINUX_VERSION} \
after $((BUILD_TIME / 60)) minutes and $((BUILD_TIME % 60)) seconds"

# Send build status to Telegram
if [[ ${BUILD_STATUS} == True ]]; then
    _send_msg "<b>${CODENAME}-${LINUX_VERSION}</b> | \
<code>Kernel Successfully Compiled after $((BUILD_TIME / 60)) minutes and \
$((BUILD_TIME % 60)) seconds</code>"
fi

# Create and sign flashable zip
_create_flashable_zip | tee -a "${LOG}"
_sign_flashable_zip | tee -a "${LOG}"

# Upload build on Telegram
if [[ ${BUILD_STATUS} == True ]]; then
    _note "Uploading build on Telegram..."

    MD5=$(md5sum "${DIR}/builds/NetErnels-${CODENAME}-${LINUX_VERSION}-\
${DATE}-signed.zip" | cut -d' ' -f1)

    _send_build "builds/NetErnels-${CODENAME}-${LINUX_VERSION}-${DATE}\
-signed.zip" "<b>${CODENAME}-${LINUX_VERSION}</b> | \
<b>MD5 Checksum</b>: <code>${MD5}</code>"
fi

# Get clean inputs logs
set | grep -v "RED=\|GREEN=\|YELLOW=\|BLUE=\|CYAN=\|BOLD=\|NC=\|\
TELEGRAM_ID=\|TELEGRAM_TOKEN=\|TELEGRAM_BOT\|API=\|CONFIRM\|COUNT=\|\
LENTH=\|NUMBER=\|BASH_ARGC=\|BASH_REMATCH=\|CHAR=\|COLUMNS=\|LINES=\|\
PIPESTATUS=\|TIME=" > /tmp/new_vars.log
printf "\n### USER INPUT LOGS ###\n" >> "${LOG}"
diff /tmp/old_vars.log /tmp/new_vars.log | grep -E \
    "^> [A-Z_]{3,18}=" >> "${LOG}"

# Say goodbye and exit
_clean_anykernel && _goodbye_msg && _exit
