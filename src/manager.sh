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


# ZMB banner
_terminal_banner() {
    echo -e "$BOLD
   ┌──────────────────────────────────────────────┐
   │  ╔═╗┌─┐┌┐┌  ╔╦╗┌─┐─┐ ┬  ╔╗ ┬ ┬┬┬  ┌┬┐┌─┐┬─┐  │
   │  ╔═╝├┤ │││  ║║║├─┤┌┴┬┘  ╠╩╗│ │││   ││├┤ ├┬┘  │
   │  ╚═╝└─┘┘└┘  ╩ ╩┴ ┴┴ └─  ╚═╝└─┘┴┴─┘─┴┘└─┘┴└─  │
   │ Android Kernel Builder ∆∆ ZMB Neternels Team │
   └──────────────────────────────────────────────┘"
}


# Shell color codes
_terminal_colors() {
    if [[ -t 1 ]]
    then
        ncolors=$(tput colors)
        if [[ -n $ncolors ]] && [[ $ncolors -ge 8 ]]
        then
            BOLD="$(tput bold)"
            NC="\e[0m"
            RED="$(tput bold setaf 1)"
            GREEN="$(tput bold setaf 2)"
            YELL="$(tput bold setaf 3)"
            YELLOW="$(tput setaf 3)"
            BLUE="$(tput bold setaf 4)"
            MAGENTA="$(tput setaf 5)"
            CYAN="$(tput bold setaf 6)"
        fi
    fi
}


# Operating System timezone
_get_user_timezone() {
    TIMEZONE=$(        # LINUX
        (timedatectl | grep 'Time zone' \
            | xargs | cut -d' ' -f3) 2>/dev/null
    )
    if [[ ! $TIMEZONE ]]
    then
        TIMEZONE=$(    # TERMUX
            (getprop | grep timezone | cut -d' ' -f2 \
                | sed 's/\[//g' | sed 's/\]//g') 2>/dev/null
        )
    fi
}


# Define current build time
_get_build_time() {
    end_time=$(TZ=$TIMEZONE date +%s)
    diff_time=$((end_time - START_TIME))
    min=$((diff_time / 60))
    sec=$((diff_time % 60))
    export BUILD_TIME=${min}m${sec}s
}


# Get build variables
# ===================
# - get user inputs and add them to logfile
# - removes color codes from logfile
# - send logfile on Telegram when the build fail
#
_get_build_logs() {
    if [[ -f ${DIR}/bashvar ]] && [[ -f $LOG ]]
    then
        null=$(IFS=$'|'; echo "${EXCLUDED_VARS[*]}")
        (set -o posix; set | grep -v "${null//|/\\|}")> \
            "${DIR}/buildervar"
        printf "\n\n### ZMB SETTINGS ###\n" >> "$LOG"
        diff bashvar buildervar | grep -E \
            "^> [A-Z0-9_]{3,32}=" >> "$LOG" || sleep 0.1
        _cleanlog
    fi
    _send_failed_build_logs
}


# Remove ANSI escape sequences
_cleanlog() {
    if [[ -f $LOG ]]
    then
        sed -ri "s/\x1b\[[0-9;]*[mGKHF]//g" "$LOG"
    fi
}


# CD to specified DIR
# ===================
#  $1 = location to go
#  $2 = error message
#
_cd() { cd "$1" || (_error "$2"; _exit) }


# Ask some information
# ====================
#  $1 = question to ask
#  $2 = type (1 for arrow)
#
_prompt() {
    lenth=$*
    count=${#lenth}
    echo -ne "\n${YELL}==> ${GREEN}$1"
    echo -ne "${YELL}\n==> "
    for ((char=1; char<=count-2; char++))
    do
        echo -ne "─"
    done
    if [[ $2 == 1 ]]
    then
        echo -ne "\n==> $NC"
    else
        echo -ne "\n$NC"
    fi
}


# Confirmation message
# ====================
#  $1 = question to ask
#  $2 = yes/no (to set default)
#
_confirm_msg() {
    CONFIRM=False
    count=$((${#1} + 6))
    echo -ne "${YELL}\n==> ${GREEN}${1}"\
             "${RED}${2}${YELL}\n==> "
    for ((char=1; char<=count; char++))
    do
        echo -ne "─"
    done
    echo -ne "\n==> $NC"
    read -r CONFIRM
}


# Ask confirmation [y/n]
# ======================
#  $@ = $1 + $2
#  -------------
#  $1 = question
#  $2 = yes/no
#
_confirm() {
    _confirm_msg "$@"
    until [[ -z $CONFIRM ]] || \
        [[ $CONFIRM =~ ^(y|n|Y|N|yes|no|Yes|No|YES|NO) ]]
    do
        _error "$MSG_ERR_CONFIRM"
        _confirm_msg "$@"
    done
}


# Display some notes
# ==================
#  $1 = note to display
#
_note() {
    echo -e "${YELL}\n[$(TZ=$TIMEZONE date +%T)]"\
            "${CYAN}${1}$NC"
    sleep 1
}


# Display error/warning
# =====================
#  $1 = use WARN as $1 to use warning
#  $* = ERROR or WARNING message
#
_error() {
    if [[ $1 == WARN ]]
    then
        echo -e "\n${BLUE}${MSG_WARN}:${NC}${YELLOW}${*/WARN/}$NC"
    else
        echo -e "\n${RED}${MSG_ERROR}: ${NC}${YELLOW}${*}$NC"
    fi
}


# Handle command error
# ====================
# - run command as child
# - check its output code
# - notify function and file on ERR
# - get failed build logs (+TG feedback)
# - ask to run again last failed command
#   -------------------
#   $@ = command to run
#
_check() {
    "$@" & wait $!
    local status=$?
    until [[ $status -eq 0 ]]
    do
        line=${BASH_LINENO[$i+1]}
        func=${FUNCNAME[$i+1]}
        file=${BASH_SOURCE[$i+1]##*/}
        _error "${*} ${RED}${MSG_ERR_LINE}"\
               "${line}:${NC}${YELLOW} ${func}"\
               "${RED}${MSG_ERR_FROM}:"\
               "${NC}${YELLOW}${file##*/}"
        _get_build_logs
        _ask_for_run_again
        if [[ $RUN_AGAIN == True ]]
        then
            if [[ -f $LOG ]]
            then
                _terminal_banner > "$LOG"
            fi
            if [[ $START_TIME ]]
            then
                START_TIME=$(TZ=$TIMEZONE date +%s)
                _send_make_build_status
                "$@" | tee -a "$LOG" & wait $!
            else
                "$@" & wait $!
            fi
        else
            _exit
            break
        fi
    done
}


# Properly exit ZenMaxBuilder
# ===========================
# - kill make PID child on interrupt
# - remove user inputs files
# - exit with 3s timeout
#
_exit() {
    if pidof make
    then
        pkill make || sleep 0.1
    fi

    _cleanlog
    files=(bashvar buildervar linuxver)
    for file in "${files[@]}"
    do
        if [[ -f $file ]]
        then
            rm -f "${DIR}/$file" || sleep 0.1
        fi
    done

    for ((second=3; second>=1; second--))
    do
        echo -ne "\r\033[K${BLUE}${MSG_EXIT}"\
                 "in ${MAGENTA}${second}${BLUE}"\
                 "second(s)...$NC"
        sleep 1
    done
    echo && kill -- $$
}


# Clean AnyKernel folder
_clean_anykernel() {
    _note "${MSG_NOTE_CLEAN_AK3}..."
    for file in "${DIR}/${ANYKERNEL_DIR}"/*
    do
        case $file in
            (*.zip*|*Image*|*-dtb*|*spectrum.rc*)
                rm -f "${file}" || sleep 0.1
        esac
    done
}

