#!/usr/bin/bash
# shellcheck disable=SC1091
set > /tmp/old_vars.log

#   Copyright 2021 Neternels-Builder by darkmaster @grm34 Neternels Team
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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

# Make
_note "Make kernel version..."
LINUX_VERSION=$(make -C "${KERNEL_DIR}" kernelversion | grep -v make)
_make_clean_build | tee -a "${LOG}"
_make_defconfig | tee -a "${LOG}"
_make_menuconfig
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

# Build status
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

# Flashable zip
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

# Exit
_clean_anykernel && _goodbye_msg && _exit
