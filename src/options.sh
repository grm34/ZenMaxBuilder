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


#####################
### UPDATE OPTION ###
#####################

# Github repository
# =================
# - ALL: checkout and fetch
# - ZMB: check if settings.cfg was updated
# - ZMB: if True warn the user to create new one
# - ZMB: rename etc/user.cfg to etc/old.cfg
# - ALL: reset to origin then pull changes
#   ----------------
#   $1 = repo branch
#
_update_git() {
    git checkout "$1"
    git fetch origin "$1"
    if [[ $1 == zmb ]] && [[ -f ${DIR}/etc/user.cfg ]]
    then
        conf=$(git diff origin/zmb "${DIR}/etc/settings.cfg")
        if [[ -n $conf ]] && [[ -f ${DIR}/etc/user.cfg ]]
        then
            _error WARN "${MSG_CONF}"; echo
            _check mv "${DIR}/etc/user.cfg" "${DIR}/etc/old.cfg"
        fi
    fi
    git reset --hard "origin/$1"
    git pull
}

# Updates everything that needs to be
# ===================================
# - set ZMB and AK3 and TC data
# - upgrade existing stuff...

_full_upgrade() {
    declare -A up_data=(
        [zmb]="${DIR}€${ZMB_BRANCH}€$MSG_UP_ZMB"
        [ak3]="${ANYKERNEL_DIR}€${ANYKERNEL_BRANCH}€$MSG_UP_AK3"
        [t1]="${PROTON_DIR}€${PROTON_BRANCH}€$MSG_UP_CLANG"
        [t2]="${GCC_ARM_DIR}€${GCC_ARM_BRANCH}€$MSG_UP_GCC32"
        [t3]="${GCC_ARM64_DIR}€${GCC_ARM64_BRANCH}€$MSG_UP_GCC64"
        [t4]="${LOS_ARM_DIR}€${LOS_ARM_BRANCH}€$MSG_UP_LOS32"
        [t5]="${LOS_ARM64_DIR}€${LOS_ARM64_BRANCH}€$MSG_UP_LOS64"
    )
    up_list=(zmb ak3 t1 t2 t3 t4 t5)
    for repository in "${up_list[@]}"
    do
        IFS="€"
        repo="${up_data[$repository]}"
        read -ra repo <<< "$repo"
        unset IFS
        if [[ -d ${repo[0]} ]]
        then
            _note "${repo[2]}..."
            _cd "${repo[0]}" "$MSG_ERR_DIR ${RED}${repo[0]}"
            _update_git "${repo[1]}"
            _cd "$DIR" "$MSG_ERR_DIR ${RED}$DIR"
        fi
    done
}


########################
### TELEGRAM OPTIONS ###
########################

# Send message
_send_msg_option() {
    if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]
    then
        _install_dependencies
        _note "${MSG_NOTE_SEND}..."
        _send_msg "${OPTARG//_/-}"
    else _error "$MSG_ERR_API"
    fi
}

# Send file
_send_file_option() {
    if [[ -f $OPTARG ]]
    then
        if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]
        then
            _install_dependencies
            _note "${MSG_NOTE_UPLOAD}: ${OPTARG##*/}..."
            _send_file "$OPTARG"
        else _error "$MSG_ERR_API"
        fi
    else _error "$MSG_ERR_FILE ${RED}$OPTARG"
    fi
}


###########################
### LIST KERNELS OPTION ###
###########################
_list_all_kernels() {
    if [[ -d ${DIR}/out ]] && \
        [[ $(ls -d out/*/ 2>/dev/null) ]]
    then
        _note "${MSG_NOTE_LISTKERNEL}:"
        find out/ -mindepth 1 -maxdepth 1 -type d \
            | cut -f2 -d'/' | cat -n
    else _error "$MSG_ERR_LISTKERNEL"
    fi
}


########################
### LINUX TAG OPTION ###
########################
_get_linux_tag() {
    _note "${MSG_NOTE_LTAG}..."
    ltag=$(git ls-remote --refs --sort='v:refname' --tags \
        "$LINUX_STABLE" | grep "$OPTARG" | tail --lines=1 \
        | cut --delimiter='/' --fields=3)
    if [[ $ltag == ${OPTARG}* ]]
    then _note "${MSG_SUCCESS_LTAG}: ${RED}$ltag"
    else _error "$MSG_ERR_LTAG ${RED}$OPTARG"
    fi
}


##################
### ZIP OPTION ###
##################
_create_zip_option() {
    if [[ -f $OPTARG ]] && [[ ${OPTARG##*/} == *Image* ]]
    then
        _install_dependencies
        _clean_anykernel
        _zip "${OPTARG##*/}-${DATE}-$TIME" "$OPTARG" \
            "${DIR}/builds/default"
        _sign_zip \
            "${DIR}/builds/default/${OPTARG##*/}-${DATE}-$TIME"
        _clean_anykernel
        _note "$MSG_NOTE_ZIPPED !"
    else _error "$MSG_ERR_IMG ${RED}$OPTARG"
    fi
}


###################
### HELP OPTION ###
###################
_usage() {
    echo -e "
${BOLD}Usage:$NC ${GREEN}bash zmb \
${NC}[${YELLOW}OPTION${NC}] [${YELLOW}ARGUMENT${NC}] \
(e.g. ${MAGENTA}bash zmb --start${NC})

  ${BOLD}Options$NC
    -h, --help                      $MSG_HELP_H
    -s, --start                     $MSG_HELP_S
    -u, --update                    $MSG_HELP_U
    -l, --list                      $MSG_HELP_L
    -t, --tag            [v4.19]    $MSG_HELP_T
    -m, --msg          [message]    $MSG_HELP_M
    -f, --file            [file]    $MSG_HELP_F
    -z, --zip     [Image.gz-dtb]    $MSG_HELP_Z
    -d, --debug                     $MSG_HELP_D

${BOLD}${MSG_HELP_INFO}: \
${CYAN}https://kernel-builder.com$NC
"
}

