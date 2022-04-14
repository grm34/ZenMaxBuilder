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


##################
### ZIP OPTION ###
##################


# Create Flashable ZIP
# Sign ZIP with AOSP Keys
_create_zip_option() {
    if [[ -f $OPTARG ]] && [[ ${OPTARG##*/} == Image* ]]
    then
        _clean_anykernel
        _zip "${OPTARG##*/}-${DATE}-${TIME}" "$OPTARG" \
            "${DIR}/builds/default"
        _sign_zip "${OPTARG##*/}-${DATE}-${TIME}"
        _clean_anykernel
    else
        _error "$MSG_ERR_IMG ${RED}${OPTARG}"
    fi
}


#####################
### UPDATE OPTION ###
#####################


# GitHub repository
# =================
#   $1 = branch
# =================
_update_git() {
    git checkout "$1"
    git fetch origin "$1"
    git reset --hard "origin/$1"
    git pull
}


# ZMB: ZenMaxBuilder
# AK3: AnyKernel3
# Toolchains
_full_upgrade() {

    # ZenMaxBuilder
    _note "${MSG_UP_ZMB}..."
    if git diff settings.cfg | grep -q settings.cfg &>/dev/null
    then
        _ask_for_save_config
        if [[ $SAVE_CONFIG == True ]]
        then
            _check cp settings.cfg settings_save.cfg
        fi
    fi
    _update_git "$ZMB_BRANCH"

    # Set AK3 and toolchains parameters
    declare -A TC_DATA=(
        [ak3]="${ANYKERNEL_DIR}€${ANYKERNEL_BRANCH}€$MSG_UP_AK3"
        [t1]="${PROTON_DIR}€${PROTON_BRANCH}€$MSG_UP_CLANG"
        [t2]="${GCC_ARM_DIR}€${GCC_ARM_BRANCH}€$MSG_UP_GCC32"
        [t3]="${GCC_ARM64_DIR}€${GCC_ARM64_BRANCH}€$MSG_UP_GCC64"
    )

    # Update AK3 and toolchains
    TC_LIST=(ak3 t1 t2 t3)
    for repository in "${TC_LIST[@]}"
    do
        IFS="€"
        REPO="${TC_DATA[${repository}]}"
        read -ra REPO <<< "$REPO"
        if [[ -d ${REPO[0]} ]]
        then
            _note "${REPO[2]}..."
            cd "${REPO[0]}" || (
                _error "$MSG_ERR_DIR ${RED}${REPO[0]}"
                _exit
            )
            _update_git "${REPO[1]}"
            cd "$DIR" || (
                _error "$MSG_ERR_DIR ${RED}${DIR}"
                _exit
            )
        fi
    done
}


###########################
### LIST KERNELS OPTION ###
###########################


# Show list of kernels
# List folders in OUT
_list_all_kernels() {
    if [[ -d ${DIR}/out ]] && \
        [[ $(ls -d out/*/ 2>/dev/null) ]]
    then
        _note "${MSG_NOTE_LISTKERNEL}:"
        find out/ -mindepth 1 -maxdepth 1 -type d \
            | cut -f2 -d'/' | cat -n
    else
        _error "$MSG_ERR_LISTKERNEL"
    fi
}


########################
### LINUX TAG OPTION ###
########################


# Get latest linux stable tag
_get_linux_tag() {
    _note "${MSG_NOTE_LTAG}..."
    LTAG=$(git ls-remote --refs --sort='v:refname' --tags \
        "$LINUX_STABLE" | grep "$OPTARG" | tail --lines=1 \
        | cut --delimiter='/' --fields=3)
    if [[ $LTAG == ${OPTARG}* ]]
    then
        _note "${MSG_SUCCESS_LTAG}: ${RED}${LTAG}"
    else
        _error "$MSG_ERR_LTAG ${RED}${OPTARG}"
    fi
}


########################
### TELEGRAM OPTIONS ###
########################


# Send message
_send_msg_option() {
    if [[ $TELEGRAM_CHAT_ID ]] && \
        [[ $TELEGRAM_BOT_TOKEN ]]
    then
        _note "${MSG_NOTE_SEND}..."
        _send_msg "${OPTARG//_/-}"
    else
        _error "$MSG_ERR_API"
    fi
}


# Send file
_send_file_option() {
    if [[ -f $OPTARG ]]
    then
        if [[ $TELEGRAM_CHAT_ID ]] && \
            [[ $TELEGRAM_BOT_TOKEN ]]
        then
            _note "${MSG_NOTE_UPLOAD}: ${OPTARG##*/}..."
            _send_file "$OPTARG"
        else
            _error "$MSG_ERR_API"
        fi
    else
        _error "$MSG_ERR_FILE ${RED}${OPTARG}"
    fi
}

