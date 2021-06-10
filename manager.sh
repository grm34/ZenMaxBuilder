#!/usr/bin/bash

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

# Shell color codes
RED="\e[1;31m"; GREEN="\e[1;32m"; YELLOW="\e[1;33m"
BLUE="\e[1;34m"; CYAN="\e[1;36m"; BOLD="\e[1;37m"; NC="\e[0m"


# Display script banner
_banner() {
    echo -e "${BOLD}
   ┌─────────────────────────────────────────────┐
   │ ┏┓╻┏━╸╺┳╸┏━╸┏━┓┏┓╻┏━╸╻  ┏━┓   ╺┳╸┏━╸┏━┓┏┓┏┓ │
   │ ┃┗┫┣╸  ┃ ┣╸ ┣┳┛┃┗┫┣╸ ┃  ┗━┓    ┃ ┣╸ ┣╸┫┃┗┛┃ │
   │ ╹ ╹┗━╸ ╹ ┗━╸╹┗╸╹ ╹┗━╸┗━╸┗━┛    ╹ ┗━╸╹ ╹╹  ╹ │
   └─────────────────────────────────────────────┘"
}


# Ask some information
_prompt() {
    LENTH=${*}; COUNT=${#LENTH}
    echo -ne "\n${YELLOW}==> ${GREEN}${1} ${RED}${2}"
    echo -ne "${YELLOW}\n==> "
    for (( CHAR=1; CHAR<=COUNT; CHAR++ )); do echo -ne "-"; done
    echo -ne "\n==> ${NC}"
}


# Ask confirmation (Yes/No)
_confirm() {
    CONFIRM=True; COUNT=$(( ${#1} + 6 ))
    until [[ ${CONFIRM} =~ ^(y|n|Y|N|yes|no|Yes|No|YES|NO) ]] || \
            [[ ${CONFIRM} == "" ]]; do
        echo -ne "${YELLOW}\n==> ${GREEN}${1} ${RED}[Y/n]${YELLOW}\n==> "
        for (( CHAR=1; CHAR<=COUNT; CHAR++ )); do echo -ne "-"; done
        echo -ne "\n==> ${NC}"
        read -r CONFIRM
    done
}


# Select an option
_select() {
    COUNT=0
    echo -ne "${YELLOW}\n==> "
    for ENTRY in "${@}"; do
        echo -ne "${GREEN}${ENTRY} ${RED}[$(( ++COUNT ))] ${NC}"
    done
    LENTH=${*}; NUMBER=$(( ${#*} * 4 ))
    COUNT=$(( ${#LENTH} + NUMBER + 1 ))
    echo -ne "${YELLOW}\n==> "
    for (( CHAR=1; CHAR<=COUNT; CHAR++ )); do echo -ne "-"; done
    echo -ne "\n==> ${NC}"
}


# Display some notes
_note() {
    echo -e "${YELLOW}\n[$(date +%T)] ${CYAN}${1}${NC}"; sleep 1
}


# Display error
_error() {
    echo -e "\n${RED}Error: ${YELLOW}${*}${NC}"
}


# Check command status and exit on error
_check() {
    "${@}"; local STATUS=$?
    if [[ ${STATUS} -ne 0 ]]; then
        _error "${@}"
        _exit
    fi
    return "${STATUS}"
}


# Exit with 5s timeout
_exit() {
    if [[ ${BUILD_STATUS} == True ]] && [[ ${START_TIME} ]] && \
            [[ ! $BUILD_TIME ]]; then
        END_TIME=$(TZ=${TIMEZONE} date +%s)
        BUILD_TIME=$((END_TIME - START_TIME))
        _send_msg "<b>${CODENAME}-${LINUX_VERSION}</b> | \
Build failed to compile after $((BUILD_TIME / 60)) minutes \
and $((BUILD_TIME % 60)) seconds</code>"
        _send_build \
"${LOG}" "<b>${CODENAME}-${LINUX_VERSION} build logs</b>"
    fi
    _clean_anykernel
    for (( SECOND=5; SECOND>=1; SECOND-- )); do
        echo -ne "\r\033[K${BLUE}Exit building script in ${SECOND}s...${NC}"
        sleep 1
    done
    echo && kill -9 $$
}


# Clean AnyKernel Folder
_clean_anykernel() {
    _note "Cleaning AnyKernel folder..."
    UNWANTED=(Image.gz-dtb init.spectrum.rc)
    for UW in "${UNWANTED[@]}"; do
        rm -f "${DIR}"/AnyKernel/"${UW}"
    done
    if [[ ! -f ${DIR}/AnyKernel/NetErnels-\
${CODENAME}-${LINUX_VERSION}-${DATE}-signed.zip ]]; then
        rm -f "${DIR}"/AnyKernel/*.zip
    fi
    if [[ -f ${DIR}/AnyKernel/anykernel-real.sh ]]; then
        rm -f "${DIR}"/AnyKernel/anykernel.sh
    fi
}


# Download show progress bar only
_wget() {
    wget -O "${1}" --quiet --show-progress "${2}"
}


# Say goodbye
_goodbye_msg() {
    echo -e "\n${GREEN}<<< Neternels Team @ Development is Life >>>${NC}"
}
