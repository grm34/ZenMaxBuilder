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

# Shell color codes
RED="\e[1;31m"; GREEN="\e[1;32m"; YELL="\e[1;33m"
BLUE="\e[1;34m"; CYAN="\e[1;36m"; BOLD="\e[1;37m"; NC="\e[0m"


# Display script banner
_neternels_builder_banner() {
    echo -e "${BOLD}
   ┌─────────────────────────────────────────────┐
   │ ┏┓╻┏━╸╺┳╸┏━╸┏━┓┏┓╻┏━╸╻  ┏━┓   ╺┳╸┏━╸┏━┓┏┓┏┓ │
   │ ┃┗┫┣╸  ┃ ┣╸ ┣┳┛┃┗┫┣╸ ┃  ┗━┓    ┃ ┣╸ ┣╸┫┃┗┛┃ │
   │ ╹ ╹┗━╸ ╹ ┗━╸╹┗╸╹ ╹┗━╸┗━╸┗━┛    ╹ ┗━╸╹ ╹╹  ╹ │
   └─────────────────────────────────────────────┘"
}


# Help (--help or -h)
_usage() {
    echo -e "
${BOLD}Usage:${NC} bash Neternels-Builder [OPTION] [ARGUMENT]

  ${BOLD}Options${NC}
    -h, --help                     show this message and exit
    -u, --update                   update script and toolchains
    -m, --msg     [message]        send message on Telegram
    -f, --file    [file]           send file on Telegram
    -z, --zip     [Image.gz-dtb]   create flashable zip

${BOLD}More information at: \
${CYAN}http://github.com/grm34/Neternels-Builder${NC}
"
}


# Ask some information
_prompt() {
    LENTH=${*}; COUNT=${#LENTH}
    echo -ne "\n${YELL}==> ${GREEN}${1} ${RED}${2}"
    echo -ne "${YELL}\n==> "
    for (( CHAR=1; CHAR<=COUNT; CHAR++ )); do
        echo -ne "-"
    done
    echo -ne "\n==> ${NC}"
}


# Ask confirmation (Yes/No)
_confirm() {
    CONFIRM=False; COUNT=$(( ${#1} + 6 ))
    until [[ ${CONFIRM} =~ ^(y|n|Y|N|yes|no|Yes|No|YES|NO) ]] \
            || [[ ${CONFIRM} == "" ]]; do
        echo -ne \
            "${YELL}\n==> ${GREEN}${1} ${RED}${N}${YELL}\n==> "
        for (( CHAR=1; CHAR<=COUNT; CHAR++ )); do
            echo -ne "-"
        done
        echo -ne "\n==> ${NC}"
        read -r CONFIRM
    done
}


# Select an option
_select() {
    COUNT=0
    echo -ne "${YELL}\n==> "
    for ENTRY in "${@}"; do
        echo -ne "${GREEN}${ENTRY} ${RED}[$(( ++COUNT ))] ${NC}"
    done
    LENTH=${*}; NUMBER=$(( ${#*} * 4 ))
    COUNT=$(( ${#LENTH} + NUMBER + 1 ))
    echo -ne "${YELL}\n==> "
    for (( CHAR=1; CHAR<=COUNT; CHAR++ )); do
        echo -ne "-"
    done
    echo -ne "\n==> ${NC}"
}


# Display some notes
_note() {
    echo -e "${YELL}\n[$(date +%T)] ${CYAN}${1}${NC}"
    sleep 1
}


# Display ERR
_error() {
    echo -e "\n${RED}Error: ${YELL}${*}${NC}"
}


# Handle ERR
_check() {
    "${@}" & wait ${!}
    local STATUS=$?
    until [[ ${STATUS} -eq 0 ]]; do
        LINE="${BASH_LINENO[$i+1]}"
        FUNC="${FUNCNAME[$i+1]}"
        FILE="${BASH_SOURCE[$i+1]##*/}"
        _error "${*} | Line ${LINE}: ${FUNC} From: ${FILE##*/}"
        _ask_for_run_again
        if [[ ${RUN_AGAIN} == True ]]; then
            "${@}" & wait ${!}
        else
            break
            _exit
        fi
    done
}


# Properly EXIT
_exit() {

    # Kill make child on interrupt
    if pidof make; then
        pkill make || sleep 0.1
    fi

    # Get user inputs and add them to logfile
    if [[ -f ${DIR}/bashvar ]] && [[ -f ${LOG} ]]; then
        set | grep -v "${EXCLUDE_VARS}" > buildervar
        printf "\n### USER INPUT LOGS ###\n" >> "${LOG}"
        diff bashvar buildervar | grep -E \
            "^> [A-Z_]{3,26}=" >> "${LOG}" || sleep 0.1
    fi

    # On error send logs on Telegram
    _send_failed_build_logs

    # Remove inputs files
    FILES=(bashvar buildervar linuxver "${LOG##*/}")
    for FILE in "${FILES[@]}"; do
        if [[ -f ${DIR}/${FILE} ]]; then
            rm "${DIR}/${FILE}" || sleep 0.1
        fi
    done

    # Exit with 3s timeout
    for (( SECOND=3; SECOND>=1; SECOND-- )); do
        echo -ne \
        "\r\033[K${BLUE}Exiting script in ${SECOND}s...${NC}"
        sleep 1
    done
    echo -e \
       "\n${RED}<| Neternels Team @ Development is Life |>${NC}"
    kill -- ${$}
}


# Clean AnyKernel Folder
_clean_anykernel() {
    _note "Cleaning AnyKernel repository..."
    UNWANTED=(*.zip Image* *-dtb init.spectrum.rc)
    for UW in "${UNWANTED[@]}"; do
        rm -f "${ANYKERNEL_DIR}/${UW}" || sleep 0.1
    done
}
