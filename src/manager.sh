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


# Display script banner
_terminal_banner() {
    echo -e "$BOLD
   ┌──────────────────────────────────────────────┐
   │  ╔═╗┌─┐┌┐┌  ╔╦╗┌─┐─┐ ┬  ╔╗ ┬ ┬┬┬  ┌┬┐┌─┐┬─┐  │
   │  ╔═╝├┤ │││  ║║║├─┤┌┴┬┘  ╠╩╗│ │││   ││├┤ ├┬┘  │
   │  ╚═╝└─┘┘└┘  ╩ ╩┴ ┴┴ └─  ╚═╝└─┘┴┴─┘─┴┘└─┘┴└─  │
   │ Android Kernel Builder ∆∆ ZMB Neternels Team │
   └──────────────────────────────────────────────┘"
}


# Help (--help or -h)
_usage() {
    echo -e "
${BOLD}Usage:$NC ${GREEN}bash zmb \
${NC}[${YELLOW}OPTION${NC}] [${YELLOW}ARGUMENT${NC}] \
(e.q. ${MAGENTA}bash zmb --start${NC})

  ${BOLD}Options$NC
    -h, --help                      $MSG_HELP_H
    -s, --start                     $MSG_HELP_S
    -u, --update                    $MSG_HELP_U
    -l, --list                      $MSG_HELP_L
    -t, --tag            [v4.19]    $MSG_HELP_T
    -m, --msg          [message]    $MSG_HELP_M
    -f, --file            [file]    $MSG_HELP_F
    -z, --zip     [Image.gz-dtb]    $MSG_HELP_Z

${BOLD}${MSG_HELP_INFO}: \
${CYAN}https://kernel-builder.com$NC
"
}


# Ask some information
_prompt() {
    LENTH=$*
    COUNT=${#LENTH}
    echo -ne "\n${YELL}==> ${GREEN}$1 ${RED}$2"
    echo -ne "${YELL}\n==> "
    for (( CHAR=1; CHAR<=COUNT; CHAR++ ))
    do
        echo -ne "─"
    done
    if [[ ! $PROMPT_TYPE ]]
    then
        echo -ne "\n==> $NC"
    else
        echo -ne "\n$NC"
    fi
}


# Confirmation prompt
_confirm_msg() {
    CONFIRM=False
    COUNT=$(( ${#1} + 6 ))
    echo -ne "${YELL}\n==> ${GREEN}${1}"\
             "${RED}${N}${YELL}\n==> "
    for (( CHAR=1; CHAR<=COUNT; CHAR++ ))
    do
        echo -ne "─"
    done
    echo -ne "\n==> $NC"
    read -r CONFIRM
}


# Ask confirmation (Yes/No)
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
_note() {
    echo -e "${YELL}\n[$(date +%T)] ${CYAN}${1}${NC}"
    sleep 1
}


# Display ERR
_error() {
    echo -e "\n${RED}${MSG_ERROR}: ${NC}${YELLOW}${*}${NC}"
}


# Handle ERR
_check() {

    # Run command as child, check
    # its output and notify on ERR
    "$@" & wait $!
    local STATUS=$?
    until [[ $STATUS -eq 0 ]]
    do
        LINE=${BASH_LINENO[$i+1]}
        FUNC=${FUNCNAME[$i+1]}
        FILE=${BASH_SOURCE[$i+1]##*/}
        _error "${*} ${RED}${MSG_ERR_LINE}"\
               "${LINE}:${NC}${YELLOW} ${FUNC}"\
               "${RED}${MSG_ERR_FROM}:"\
               "${NC}${YELLOW}${FILE##*/}"

        # Run again last failed command
        _ask_for_run_again
        if [[ $RUN_AGAIN == True ]]
        then
            if [[ -n $START_TIME ]]
            then    # Reset start time
                START_TIME=$(TZ=$TIMEZONE date +%s)
            fi
            if [[ -f $LOG ]]
            then    # clear logs
                _terminal_banner > "$LOG"
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

    # Get user inputs and add them to logfile
    if [[ -f ${DIR}/bashvar ]] && [[ -f $LOG ]]
    then
        set | grep -v "$EXCLUDE_VARS" > buildervar
        printf "\n### USER INPUT LOGS ###\n" >> "$LOG"
        diff bashvar buildervar | grep -E \
            "^> [A-Z_]{3,26}=" >> "$LOG" || sleep 0.1
    fi

    # Send ERR logs on Telegram
    _send_failed_build_logs

    # Remove inputs files
    FILES=(bashvar buildervar linuxver "${LOG##*/}")
    for FILE in "${FILES[@]}"
    do
        if [[ -f ${DIR}/${FILE} ]]
        then
            rm "${DIR}/${FILE}" || sleep 0.1
        fi
    done

    # Exit with 3s timeout
    for (( SECOND=3; SECOND>=1; SECOND-- ))
    do
        echo -ne "\r\033[K${BLUE}${MSG_EXIT}"\
                 "in ${SECOND}s...$NC"
        sleep 1
    done
    echo && kill -- $$
}


# Clean AnyKernel folder
_clean_anykernel() {
    _note "${MSG_NOTE_CLEAN_AK3}..."
    UNWANTED=(*.zip Image* *-dtb init.spectrum.rc)
    for UW in "${UNWANTED[@]}"
    do
        rm -f "${ANYKERNEL_DIR}/${UW}" || sleep 0.1
    done
}


# Show list of kernels
_list_all_kernels() {
    if [[ -d ${DIR}/out ]] && [[ -n $(ls -d out/*/) ]]
    then
        _note "$MSG_NOTE_LISTKERNEL :"
        find out/ -mindepth 1 -maxdepth 1 -type d \
            | cut -f2 -d'/' | cat -n
    else
        _error "$MSG_ERR_LISTKERNEL"
    fi
}


# Get latest linux stable tag
_get_linux_tag() {
    _note "${MSG_NOTE_LTAG}..."
    LTAG=$(git ls-remote --refs --sort='v:refname' --tags \
        "$LINUX_STABLE" | grep "$OPTARG" | tail --lines=1 \
        | cut --delimiter='/' --fields=3)
    if [[ $LTAG == ${OPTARG}* ]]
    then
        _note "$MSG_SUCCESS_LTAG : ${RED}${LTAG}"
    else
        _error "$MSG_ERR_LTAG ${RED}${OPTARG}"
    fi
}

