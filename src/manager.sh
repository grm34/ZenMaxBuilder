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
            NC="$(tput sgr0)"
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


# Get OS timezone
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


# Get build time
_get_build_time() {
    end_time=$(TZ=$TIMEZONE date +%s)
    diff_time=$((end_time - START_TIME))
    min=$((diff_time / 60))
    sec=$((diff_time % 60))
    export BUILD_TIME=${min}m${sec}s
}


# Get build logs
_get_build_logs() {
    if [[ -f ${DIR}/bashvar ]] && [[ -f $LOG ]]
    then
        # Get user inputs and add them to logfile
        null=$(IFS=$'|'; echo "${EXCLUDED_VARS[*]}")
        (set -o posix; set | grep -v "${null//|/\\|}")> \
            "${DIR}/buildervar"
        printf "\n\n### ZMB SETTINGS ###\n" >> "$LOG"
        diff bashvar buildervar | grep -E \
            "^> [A-Z0-9_]{3,32}=" >> "$LOG" || sleep 0.1
        # Removes color codes from logs
        sed -ri \
            "s/\x1B\[(([0-9]+)(;[0-9]+)*)?[m,K,H,f,J]//g" \
            "$LOG"
    fi
    # Send ERR logs on Telegram
    _send_failed_build_logs
}


# Edit CROSS_COMPILE in Makefile
_edit_makefile_cross_compile() {
    cc=${ccompiler/CROSS_COMPILE=/}
    _check sed -i \
        "s/CROSS_COMPILE.*?=.*/CROSS_COMPILE ?= ${cc}/g" \
        "${KERNEL_DIR}/Makefile"
}


# Get CROSS_COMPILE and edit Makefile
_get_cross_compile() {
    _note "$MSG_NOTE_CC"
    grepcc=$(grep CROSS_COMPILE "${KERNEL_DIR}/Makefile")
    echo "$grepcc" | grep -v "ifneq\|export\|#"
    _ask_for_edit_cross_compile
    case $COMPILER in
        "$PROTON_CLANG_NAME")
            ccompiler=${PROTON_CLANG_OPTIONS[2]}
            ;;
        "$PROTON_GCC_NAME")
            ccompiler=${PROTON_GCC_OPTIONS[3]}
            ;;
        "$EVA_GCC_NAME")
            ccompiler=${EVA_GCC_OPTIONS[3]}
    esac
    if [[ $EDIT_CC == True ]]
    then
        _edit_makefile_cross_compile
    else
        mk=$(grep "CROSS_COMPILE.*?=" "${KERNEL_DIR}/Makefile")
        if [[ -n ${mk##*"${ccompiler/CROSS_COMPILE=/}"*} ]]
        then
            _note "$MSG_WARN_CC"
        fi
    fi
}


# CD to specified DIR
# ===================
#   $1 = location
#   $2 = error msg
# ===================
_cd() {
    cd "$1" || (_error "$2"; _exit)
}


# Ask some information
# ====================
#   $1 = question
#   $2 = type
# ====================
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


# Confirmation prompt
# ===================
#   $1 = question
#   $2 = yes/no
# ===================
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
#   $@ = $1 + $2
#   -------------
#   $1 = question
#   $2 = yes/no
# ======================
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
#   $1 = note
# ==================
_note() {
    echo -e "${YELL}\n[$(TZ=$TIMEZONE date +%T)]"\
            "${CYAN}${1}$NC"
    sleep 1
}


# Display any error
# =================
#   $* = ERR
# =================
_error() {
    echo -e "\n${RED}${MSG_ERROR}: ${NC}${YELLOW}${*}$NC"
}


# Handle command error
# ====================
#   $@ = command
# ====================
_check() {

    # Run command as child, check
    # its output and notify on ERR
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

        # Run again last failed command
        _ask_for_run_again
        if [[ $RUN_AGAIN == True ]]
        then
            if [[ $START_TIME ]]
            then    # Reset start time
                START_TIME=$(TZ=$TIMEZONE date +%s)
            fi
            if [[ -f $LOG ]]
            then    # clear logs
                _terminal_banner > "$LOG"
                _send_make_build_status
            fi
            "$@" & wait $!
        else
            _exit
            break
        fi
    done
}


# Properly EXIT
_exit() {

    # Kill make PID child on interrupt
    if pidof make
    then
        pkill make || sleep 0.1
    fi

    # Remove inputs files
    files=(bashvar buildervar linuxver)
    for file in "${files[@]}"
    do
        if [[ -f $file ]]
        then
            rm -f "${DIR}/$file" || sleep 0.1
        fi
    done

    # Exit with 3s timeout
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

