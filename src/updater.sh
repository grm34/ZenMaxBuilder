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


# Reset then pull git repository
_update_git() {
    git checkout "$1"
    git fetch
    git reset --hard HEAD
    git merge origin "$1"
    git pull
}


# [UPDATE] ZMB AK3 Toolchains
_full_upgrade() {

    # ZenMaxBuilder
    _note "${MSG_UP_ZMB}..."
    if git diff config.sh | grep -q config.sh &>/dev/null
    then
        _ask_for_save_config
        if [[ $SAVE_CONFIG == True ]]
        then
            _check cp config.sh config_save.sh
        fi
    fi
    _update_git "$ZMB_BRANCH"

    # Declare AK3 and toolchains
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

