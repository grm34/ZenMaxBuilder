#!/usr/bin/env bash

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

### ZMB STRUCTURE ###
# ==================
#
# - MANAGER: all the functions for the global management.    (96)
# - REQUIREMENTS: the missing dependencies installation.    (348)
# - OPTIONS: all the functions for command-line options.    (465)
# - QUESTIONER: all the asked questions to the user.        (628)
# - MAKER: all the functions related to the make process.   (883)
# - ZIP: all the functions for the signed ZIP creation.    (1079)
# - TELEGRAM: all the functions for Telegram feedback.     (1175)
# - MAIN: run the ZenMaxBuilder (ZMB) main process.        (1289)
# - START OPTION: start new android kernel compilation.    (1351)


# BAN ALL ('n00bz')
if [[ ${BASH_SOURCE[0]} != "$0" ]]
then
    echo >&2 "ERROR: ZenMaxBuilder cannot be sourced"
    return 1
elif [[ ! -t 0 ]]
then
    echo >&2 "ERROR: run ZenMaxBuilder from a terminal"
    return 1
elif [[ $(tput cols) -lt 76 ]] || [[ $(tput lines) -lt 12 ]]
then
    echo >&2 "ERROR: terminal window is too small (min 76x12)"
    return 1
elif [[ $(uname) != Linux ]]
then
    echo >&2 "ERROR: run ZenMaxBuilder on Linux"
    return 1
fi

# ABSOLUTE PATH
DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
if ! cd "$DIR"
then
    echo >&2 "ERROR: ZenMaxBuilder directory not found"
    return 1
fi

# LOCKFILE
exec 201> "$(basename "$0").lock"
if ! flock -n 201
then
    echo >&2 "ERROR: ZenMaxBuilder is already running"
    return 1
fi

# JOB CONTROL
(set -o posix; set)> "${DIR}/bashvar"
set -m -E -o pipefail #-b -v

# USER LANGUAGE
LANGUAGE=${DIR}/lang/${LANG:0:2}.cfg
if [[ -f $LANGUAGE ]]
then # shellcheck source=/dev/null
    source "$LANGUAGE"
else # shellcheck source=/dev/null
    source "${DIR}/lang/en.cfg"
fi

# USER CONFIGURATION
if [[ -f ${DIR}/etc/user.cfg ]]
then # shellcheck source=/dev/null
    source "${DIR}/etc/user.cfg"
else # shellcheck source=/dev/null
    source "${DIR}/etc/settings.cfg"
fi


#################################################################
### MANAGER | ALL THE FUNCTIONS FOR THE GLOBAL MANAGEMENT...
#################################################################

# BANNER
_terminal_banner() {
    echo -e "$BOLD
   ┌──────────────────────────────────────────────┐
   │  ╔═╗┌─┐┌┐┌  ╔╦╗┌─┐─┐ ┬  ╔╗ ┬ ┬┬┬  ┌┬┐┌─┐┬─┐  │
   │  ╔═╝├┤ │││  ║║║├─┤┌┴┬┘  ╠╩╗│ │││   ││├┤ ├┬┘  │
   │  ╚═╝└─┘┘└┘  ╩ ╩┴ ┴┴ └─  ╚═╝└─┘┴┴─┘─┴┘└─┘┴└─  │
   │ Android Kernel Builder ∆∆ ZMB Neternels Team │
   └──────────────────────────────────────────────┘"
}

# SHELL COLORS
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

# OPERATING SYSTEM TIMEZONE
_get_user_timezone() {
    TIMEZONE=$(        # Linux
        (timedatectl | grep 'Time zone' \
            | xargs | cut -d' ' -f3) 2>/dev/null
    )
    if [[ ! $TIMEZONE ]]
    then
        TIMEZONE=$(    # Termux
            (getprop | grep timezone | cut -d' ' -f2 \
                | sed 's/\[//g' | sed 's/\]//g') 2>/dev/null
        )
    fi
}

# GET CURRENT BUILD TIME
_get_build_time() {
    end_time=$(TZ=$TIMEZONE date +%s)
    diff_time=$((end_time - START_TIME))
    min=$((diff_time / 60))
    sec=$((diff_time % 60))
    export BUILD_TIME=${min}m${sec}s
}

# HANDLES BUILD LOGS
# ==================
# - get user inputs and add them to logfile
# - remove color codes from logfile
# - remove ANSI sequences from logfile
# - send logfile on Telegram when the build fail
#
_get_build_logs() {
    if [[ -f $LOG ]]
    then
        # shellcheck source=/dev/null
        source "${DIR}/etc/excluded.cfg"
        null=$(IFS=$'|'; echo "${EXCLUDED_VARS[*]}")
        unset IFS
        (set -o posix; set | grep -v "${null//|/\\|}")> \
            "${DIR}/buildervar"
        printf "\n\n### ZMB SETTINGS ###\n" >> "$LOG"
        diff bashvar buildervar | grep -E \
            "^> [A-Z0-9_]{3,32}=" >> "$LOG" || sleep 0.1
        sed -ri "s/\x1b\[[0-9;]*[mGKHF]//g" "$LOG"
        _send_failed_build_logs
    fi
}

# MOVE to specified DIRECTORY
# ===========================
#  $1 = location to go
#  $2 = error message
#
_cd() { cd "$1" || (_error "$2"; _exit) }

# ASK SOME INFORMATION
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
    do echo -ne "─"
    done
    if [[ $2 == 1 ]]
    then echo -ne "\n==> $NC"
    else echo -ne "\n$NC"
    fi
}

# CONFIRMATION MESSAGE
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
    do echo -ne "─"
    done
    echo -ne "\n==> $NC"
    read -r CONFIRM
}

# ASK CONFIRMATION [y/n]
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

# DISPLAY SOME NOTES
# ==================
#  $1 = note to display
#
_note() {
    echo -e "${YELL}\n[$(TZ=$TIMEZONE date +%T)] ${CYAN}${1}$NC"
    sleep 1
}

# DISPLAY WARNING or ERROR
# ========================
#  $1 = use WARN as $1 to use warning
#  $* = ERROR or WARNING message
#
_error() {
    if [[ $1 == WARN ]]
    then echo -e "\n${BLUE}${MSG_WARN}:${NC}${YELLOW}${*/WARN/}$NC"
    else echo -e "\n${RED}${MSG_ERROR}: ${NC}${YELLOW}${*}$NC"
    fi
}

# HANDLES SHELL COMMANDS
# ======================
# - DEBUG MODE: display command
# - run command as child
# - check its output code
# - notify function and file on ERR
# - get failed build logs (+TG feedback)
# - ask to run again last failed command
#   -------------------
#   $@ = command to run
#
_check() {
    if [[ $DEBUG_MODE == True ]]
    then echo -e "\n${BLUE}Command: ${NC}${YELLOW}${*}$NC"
    fi
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
            then _terminal_banner > "$LOG"
            fi
            if [[ $START_TIME ]]
            then
                START_TIME=$(TZ=$TIMEZONE date +%s)
                _send_start_build_status
                "$@" | tee -a "$LOG" & wait $!
            else "$@" & wait $!
            fi
        else
            _exit
            break
        fi
    done
}

# PROPERLY EXIT THE SCRIPT
# ========================
# - kill make PID child on interrupt
# - get current build logs
# - remove user input files
# - remove empty device folders
# - exit with 3s timeout
#
_exit() {
    if pidof make
    then pkill make || sleep 0.1
    fi

    _get_build_logs
    input_files=(bashvar buildervar linuxver)
    for file in "${input_files[@]}"
    do
        if [[ -f $file ]]
        then _check rm -f "${DIR}/$file"
        fi
    done
    device_folders=(out builds logs)
    for folder in "${device_folders[@]}"
    do
        if [[ -d ${DIR}/${folder}/$CODENAME ]] && \
            [[ -z $(ls -A "${DIR}/${folder}/$CODENAME") ]]
        then _check rm -rf "${DIR}/${folder}/$CODENAME"
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


#################################################################
### REQUIREMENTS | THE MISSING DEPENDENCIES INSTALLATION...
#################################################################

# HANDLES DEPENDENCIES INSTALLATION
# =================================
# - set the package manager for each Linux distribution
# - get the install command of the current OS package manager
# - GCC will not be installed on TERMUX (not fully supported)
# - install missing dependencies
#
_install_dependencies() {
    if [[ $AUTO_DEPENDENCIES == True ]]
    then
        declare -A pms=(\
            [apt]="sudo apt install -y"
            [pkg]="_ pkg install -y"
            [pacman]="sudo pacman -S --noconfirm"
            [yum]="sudo yum install -y"
            [emerge]="sudo emerge -1 -y"
            [zypper]="sudo zypper install -y"
            [dnf]="sudo dnf install -y"
        )
        pm_list=(pacman yum emerge zypper dnf pkg apt)
        for manager in "${pm_list[@]}"
        do
            if which "$manager" &>/dev/null
            then
                IFS=" "
                pm="${pms[$manager]}"
                read -ra pm <<< "$pm"
                unset IFS
                break
            fi
        done
        if [[ ${pm[3]} ]]
        then
            for DEP in "${DEPENDENCIES[@]}"
            do
                if [[ ${pm[0]} == _ ]] && [[ $DEP == gcc ]]
                then continue
                else
                    if [[ $DEP == llvm ]]; then DEP=llvm-ar; fi
                    if [[ $DEP == binutils ]]; then DEP=ld; fi
                    if ! which "${DEP}" &>/dev/null
                    then
                        if [[ $DEP == llvm-ar ]]; then DEP=llvm; fi
                        if [[ $DEP == ld ]]; then DEP=binutils; fi
                        _ask_for_install_pkg "$DEP"
                        if [[ $INSTALL_PKG == True ]]
                        then
                            eval "${pm[0]/_}" "${pm[1]}" \
                                 "${pm[2]}" "${pm[3]}" "$DEP"
                        fi
                    fi
                fi
            done
        else _error "$MSG_ERR_OS"
        fi
    fi
}

# GIT CLONE TOOLCHAIN
# ===================
#  $1 = repo branch
#  $2 = repo url
#  $3 = repo folder
#
_clone_tc() {
    if [[ ! -d $3 ]]
    then
        _ask_for_clone_toolchain "${3##*/}"
        if [[ $CLONE_TC == True ]]
        then git clone --depth=1 -b "$1" "$2" "$3"
        fi
    fi
}

# CLONE SELECTED TOOLCHAIN COMPILER
_clone_toolchains() {
    case $COMPILER in

        # Proton-Clang or Proton-GCC
        "$PROTON_CLANG_NAME"|"$PROTON_GCC_NAME")
            _clone_tc "$PROTON_BRANCH" \
                "$PROTON_URL" "$PROTON_DIR"
            ;;
        # Eva-GCC or Proton-GCC
        "$EVA_GCC_NAME"|"$PROTON_GCC_NAME")
            _clone_tc "$GCC_ARM_BRANCH" \
                "$GCC_ARM_URL" "$GCC_ARM_DIR"
            _clone_tc "$GCC_ARM64_BRANCH" \
                "$GCC_ARM64_URL" "$GCC_ARM64_DIR"
            ;;
        # Lineage-GCC
        "$LOS_GCC_NAME")
            _clone_tc "$LOS_ARM_BRANCH" \
                "$LOS_ARM_URL" "$LOS_ARM_DIR"
            _clone_tc "$LOS_ARM64_BRANCH" \
                "$LOS_ARM64_URL" "$LOS_ARM64_DIR"
    esac
}

# CLONE ANYKERNEL REPOSITORY
_clone_anykernel() {
    if [[ ! -d $ANYKERNEL_DIR ]]
    then
        _ask_for_clone_anykernel
        if [[ $CLONE_AK == True ]]
        then
            git clone -b "$ANYKERNEL_BRANCH" \
                "$ANYKERNEL_URL" "$ANYKERNEL_DIR"
        fi
    fi
}


#################################################################
### OPTIONS - ALL THE FUNCTIONS FOR COMMAND-LINE OPTIONS...
#################################################################

### UPDATE OPTION ###
#####################

# UPDATE GIT REPOSITORY
# =====================
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

# UPDATES EVERYTHING THAT NEEDS TO BE
# ===================================
# - set ZMB and AK3 and TC data
# - upgrade existing stuff...

_full_upgrade() {
    tcp=${DIR}/toolchains
    declare -A up_data=(
        [zmb]="${DIR}€${ZMB_BRANCH}€$MSG_UP_ZMB"
        [ak3]="${DIR}/${ANYKERNEL_DIR}€${ANYKERNEL_BRANCH}€$MSG_UP_AK3"
        [t1]="${tcp}/${PROTON_DIR}€${PROTON_BRANCH}€$MSG_UP_CLANG"
        [t2]="${tcp}/${GCC_ARM_DIR}€${GCC_ARM_BRANCH}€$MSG_UP_GCC32"
        [t3]="${tcp}/${GCC_ARM64_DIR}€${GCC_ARM64_BRANCH}€$MSG_UP_GCC64"
        [t4]="${tcp}/${LOS_ARM_DIR}€${LOS_ARM_BRANCH}€$MSG_UP_LOS32"
        [t5]="${tcp}/${LOS_ARM64_DIR}€${LOS_ARM64_BRANCH}€$MSG_UP_LOS64"
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

### TELEGRAM OPTIONS ###
########################

# SEND MESSAGE
_send_msg_option() {
    if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]
    then
        _install_dependencies
        _note "${MSG_NOTE_SEND}..."
        _send_msg "${OPTARG//_/-}"
    else _error "$MSG_ERR_API"
    fi
}

# SEND FILE
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


#################################################################
### QUESTIONER - ALL THE ASKED QUESTIONS TO THE USER...
#################################################################

# QUESTION TO GET THE DEVICE CODENAME
# Validation checks REGEX to prevent invalid string.
# Match "letters" and "numbers" and "-" and "_" only.
# Should be at least "3" characters long and maximum "20".
# Device codename can't start with "_" or "-" characters.
_ask_for_codename() {
    if [[ $CODENAME == default ]]
    then
        _prompt "$MSG_ASK_DEV :" 1
        read -r CODENAME
        regex="^[a-zA-Z0-9][a-zA-Z0-9_-]{2,19}$"
        until [[ $CODENAME =~ $regex ]]
        do
            _error "$MSG_ERR_DEV ${RED}$CODENAME"
            _prompt "$MSG_ASK_DEV :" 1
            read -r CODENAME
        done
    fi
}

# QUESTION TO GET THE KERNEL LOCATION
# Validation checks the presence of the "configs"
# folder corresponding to the current architecture.
_ask_for_kernel_dir() {
    if [[ $KERNEL_DIR == default ]]
    then
        _prompt "$MSG_ASK_KDIR :" 1
        read -r -e KERNEL_DIR
        until [[ -d ${KERNEL_DIR}/arch/${ARCH}/configs ]]
        do
            _error "$MSG_ERR_KDIR ${RED}$KERNEL_DIR"
            _prompt "$MSG_ASK_KDIR :" 1
            read -r -e KERNEL_DIR
        done
        KERNEL_DIR=$(realpath "$KERNEL_DIR")
    fi
}

# PROMPT TO SELECT THE DEFCONFIG FILE TO USE
# Choices: all defconfig files located in "configs"
# folder corresponding to the current architecture.
# Validation checks are not needed here.
_ask_for_defconfig() {
    CONF_DIR="${KERNEL_DIR}/arch/${ARCH}/configs"
    _cd "$CONF_DIR" "$MSG_ERR_DIR ${RED}$CONF_DIR"
    _prompt "$MSG_ASK_DEF :" 2
    select DEFCONFIG in *_defconfig
    do
        [[ $DEFCONFIG ]] && break
        _error "$MSG_ERR_SELECT"
    done
    _cd "$DIR" "$MSG_ERR_DIR ${RED}$DIR"
}

# CONFIRMATION TO RUN <make menuconfig> COMMAND
# Validation checks are not needed here.
_ask_for_menuconfig() {
    _confirm "$MSG_ASK_CONF ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export MENUCONFIG=True
    esac
}

# CONFIRMATION TO SAVE NEW DEFCONFIG
# otherwise request to continue with the original one.
# Validation checks REGEX to prevent invalid string.
# Match "letters" and "numbers" and "-" and "_" only.
# Should be at least "3" characters long and maximum "26".
# Defconfig file can't start with "_" or "-" characters.
_ask_for_save_defconfig() {
    _confirm "${MSG_ASK_SAVE_DEF} ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            export SAVE_DEFCONFIG=False
            _confirm "${MSG_ASK_USE_DEF}: $DEFCONFIG ?" "[Y/n]"
            case $CONFIRM in n|N|no|No|NO)
                export ORIGINAL_DEFCONFIG=False
            esac
            ;;
        *)
            _prompt "$MSG_ASK_DEF_NAME :" 1
            read -r DEFCONFIG
            regex="^[a-zA-Z0-9][a-zA-Z0-9_-]{2,25}$"
            until [[ $DEFCONFIG =~ $regex ]]
            do
                _error "$MSG_ERR_DEF_NAME ${RED}$DEFCONFIG"
                _prompt "$MSG_ASK_DEF_NAME :" 1
                read -r DEFCONFIG
            done
            export DEFCONFIG=${DEFCONFIG}_defconfig
    esac
}

# QUESTION TO GET THE TOOLCHAIN TO USE
# Choices: Proton-Clang Eva-GCC Proton-GCC
# Validation checks are not needed here.
_ask_for_toolchain() {
    if [[ $COMPILER == default ]]
    then
        _prompt "$MSG_SELECT_TC :" 2
        select COMPILER in $PROTON_CLANG_NAME \
            $EVA_GCC_NAME $PROTON_GCC_NAME $LOS_GCC_NAME
        do
            [[ $COMPILER ]] && break
            _error "$MSG_ERR_SELECT"
        done
    fi
}

# CONFIRMATION TO EDIT Makefile CROSS_COMPILE
# Validation checks are not needed here.
_ask_for_edit_cross_compile() {
    _confirm "$MSG_ASK_CC $COMPILER ?" "[Y/n]"
    case $CONFIRM in n|N|no|No|NO)
        export EDIT_CC=False
    esac
}

# QUESTION TO GET THE NUMBER OF CPU CORES TO USE
# Validation checks for a valid number corresponding
# to the amount of available CPU cores (no limits here).
# Otherwise all available CPU cores will be used.
_ask_for_cores() {
    CPU=$(nproc --all)
    _confirm "$MSG_ASK_CPU ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _prompt "$MSG_ASK_CORES :" 1
            read -r CORES
            until (( 1<=CORES && CORES<=CPU ))
            do
                _error "$MSG_ERR_CORES ${RED}${CORES}"\
                       "${YELL}(${MSG_ERR_TOTAL}: ${CPU})"
                _prompt "$MSG_ASK_CORES :" 1
                read -r CORES
            done
            ;;
        *) export CORES=$CPU
    esac
}

# CONFIRMATION TO RUN  <make clean> AND <make mrproprer> COMMANDS
# Validation checks are not needed here.
_ask_for_make_clean() {
    _confirm "${MSG_ASK_MCLEAN}: v$LINUX_VERSION ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export MAKE_CLEAN=True
    esac
}

# CONFIRMATION TO MAKE A NEW BUILD
# Validation checks are not needed here.
_ask_for_new_build() {
    _confirm \
        "$MSG_START ${TAG}-${CODENAME}-$LINUX_VERSION ?" "[Y/n]"
    case $CONFIRM in n|N|no|No|NO)
        export NEW_BUILD=False
    esac
}

# CONFIRMATION TO SEND BUILD STATUS ON TELEGRAM
# Validation checks are not needed here.
_ask_for_telegram() {
    if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]
    then
        _confirm "$MSG_ASK_TG ?" "[y/N]"
        case $CONFIRM in y|Y|yes|Yes|YES)
            export BUILD_STATUS=True
        esac
    fi
}

# CONFIRMATION TO CREATE FLASHABLE ZIP
# Validation checks are not needed here.
_ask_for_flashable_zip() {
    _confirm \
        "$MSG_ASK_ZIP ${TAG}-${CODENAME}-$LINUX_VERSION ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export FLASH_ZIP=True
    esac
}

# QUESTION TO GET THE KERNEL IMAGE TO ZIP
# Validation checks the presence of this file in
# "boot" folder and verify it starts with "Image".
_ask_for_kernel_image() {
    _cd "$BOOT_DIR" "$MSG_ERR_DIR ${RED}$BOOT_DIR"
    _prompt "$MSG_ASK_IMG :" 1
    read -r -e K_IMG
    until [[ -f $K_IMG ]] && [[ $K_IMG == *Image* ]]
    do
        _error "$MSG_ERR_IMG ${RED}$K_IMG"
        _prompt "$MSG_ASK_IMG" 1
        read -r -e K_IMG
    done
    K_IMG=$(realpath "$K_IMG")
    _cd "$DIR" "$MSG_ERR_DIR ${RED}$DIR"
}

# CONFIRMATION TO RUN AGAIN LAST FAILED COMMAND
# Validation checks are not needed here.
_ask_for_run_again() {
    RUN_AGAIN=False
    _confirm "$MSG_RUN_AGAIN ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export RUN_AGAIN=True
    esac
}

# CONFIRMATION TO INSTALL MISSING PACKAGE
# Warn the user that when false the script may crash.
# Validation checks are not needed here.
_ask_for_install_pkg() {
    _confirm "${MSG_ASK_PKG}: $1 ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _error WARN "${MSG_WARN_DEP}: ${RED}${DEP}"; sleep 2
            ;;
        *) export INSTALL_PKG=True
    esac
}

# CONFIRMATION TO CLONE MISSING TOOLCHAIN
# Warn the user and exit the script when false.
# Validation checks are not needed here.
_ask_for_clone_toolchain() {
    _confirm "${MSG_ASK_CLONE_TC}: $1 ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _error "${MSG_ERR_CLONE}: ${RED}$1"
            _exit
            ;;
        *) export CLONE_TC=True
    esac
}

# CONFIRMATION TO CLONE MISSING ANYKERNEL
# Warn the user and exit the script when false.
# Validation checks are not needed here.
_ask_for_clone_anykernel() {
    _confirm "${MSG_ASK_CLONE_AK3}: AK3 ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _error "${MSG_ERR_CLONE}: ${RED}AnyKernel"
            _exit
            ;;
        *) export CLONE_AK=True
    esac
}


#################################################################
### MAKER - ALL THE FUNCTIONS RELATED TO THE MAKE PROCESS...
#################################################################

# SET COMPILER BUILD OPTIONS
# ==========================
# - export target variables (CFG)
# - append toolchains to the $PATH, export and verify
# - get current toolchain compiler options
# - get and export toolchain compiler version
# - get CROSS_COMPILE and CC (to handle Makefile)
# - set Link Time Optimization (LTO)
# - DEBUG MODE: display $PATH
#
_export_path_and_options() {
    if [[ $BUILDER == default ]]; then BUILDER=$(whoami); fi
    if [[ $HOST == default ]]; then HOST=$(uname -n); fi
    export KBUILD_BUILD_USER=$BUILDER
    export KBUILD_BUILD_HOST=$HOST
    export PLATFORM_VERSION ANDROID_MAJOR_VERSION
    case $COMPILER in
        "$PROTON_CLANG_NAME")
            export PATH=${PROTON_DIR}/bin:$PATH
            _check_toolchain_path "$PROTON_DIR"
            TC_OPTIONS=("${PROTON_CLANG_OPTIONS[@]}")
            _get_tc_version "$PROTON_VERSION"
            export TCVER=${tc_version##*/}
            cross=${PROTON_CLANG_OPTIONS[1]/CROSS_COMPILE=}
            ccross=${PROTON_CLANG_OPTIONS[3]/CC=}
            ;;
        "$EVA_GCC_NAME")
            export PATH=${GCC_ARM64_DIR}/bin:${GCC_ARM_DIR}/bin:$PATH
            _check_toolchain_path "$GCC_ARM64_DIR" "$GCC_ARM_DIR"
            TC_OPTIONS=("${EVA_GCC_OPTIONS[@]}")
            _get_tc_version "$GCC_ARM64_VERSION"
            export TCVER=${tc_version##*/}
            cross=${EVA_GCC_OPTIONS[1]/CROSS_COMPILE=}
            ccross=${EVA_GCC_OPTIONS[3]/CC=}
            ;;
        "$LOS_GCC_NAME")
            export PATH=${LOS_ARM64_DIR}/bin:${LOS_ARM_DIR}/bin:$PATH
            _check_toolchain_path "$LOS_ARM64_DIR" "$LOS_ARM_DIR"
            TC_OPTIONS=("${LOS_GCC_OPTIONS[@]}")
            _get_tc_version "$LOS_ARM64_VERSION"
            export TCVER=${tc_version##*/}
            cross=${LOS_GCC_OPTIONS[1]/CROSS_COMPILE=}
            ccross=${LOS_GCC_OPTIONS[3]/CC=}
            ;;
        "$PROTON_GCC_NAME")
            eva_path=${GCC_ARM64_DIR}/bin:${GCC_ARM_DIR}/bin
            export PATH=${PROTON_DIR}/bin:${eva_path}:$PATH
            _check_toolchain_path "$PROTON_DIR" "$GCC_ARM_DIR" \
                "$GCC_ARM64_DIR"
            TC_OPTIONS=("${PROTON_GCC_OPTIONS[@]}")
            _get_tc_version "$PROTON_VERSION"; v1=$tc_version
            _get_tc_version "$GCC_ARM64_VERSION"; v2=$tc_version
            export TCVER="${v1##*/} ${v2##*/}"
            cross=${PROTON_GCC_OPTIONS[1]/CROSS_COMPILE=}
            ccross=${PROTON_GCC_OPTIONS[3]/CC=}
    esac
    if [[ $LTO == True ]]
    then
        export LD_LIBRARY_PATH=${PROTON_DIR}/lib
        TC_OPTIONS[6]="LD=$LTO_LIBRARY"
    fi
    if [[ $DEBUG_MODE == True ]]
    then echo -e "\n${BLUE}PATH: ${NC}${YELLOW}${PATH}$NC"
    fi
}

# ENSURE $PATH HAS BEEN CORRECTLY SET
# ===================================
#  $? = toolchain DIR
#
_check_toolchain_path() {
    for toolchain_path in "$@"
    do
        if [[ $PATH != *${toolchain_path}/bin* ]]
        then _error "$MSG_ERR_PATH"; echo "$PATH"; _exit
        fi
    done
}

# GET TOOLCHAIN VERSION
# =====================
#  $1 = toolchain lib DIR
#
_get_tc_version() {
    tc_version=$(find "${DIR}/toolchains/$1" \
        -mindepth 1 -maxdepth 1 -type d | head -n 1)
}

# GET CROSS_COMPILE and CC FROM MAKEFILE
_get_and_display_cross_compile() {
    r1=("^CROSS_COMPILE\s.*?=.*" "CROSS_COMPILE\ ?=\ ${cross}")
    r2=("^CC\s.*=.*" "CC\ =\ ${ccross}\ -I${KERNEL_DIR}")
    c1=$(sed -n "/${r1[0]}/{p;}" "${KERNEL_DIR}/Makefile")
    c2=$(sed -n "/${r2[0]}/{p;}" "${KERNEL_DIR}/Makefile")
    if [[ -z $c1 ]]
    then _error "$MSG_ERR_CC"; _exit
    else echo "$c1"; echo "$c2"
    fi
}

# HANDLES Makefile CROSS_COMPILE and CC
# =====================================
# - display them on TERM so user can check before
# - ask to modify them in the kernel Makefile
# - edit the kernel Makefile (SED) while True
# - warn the user when they not seems correctly set
# - DEBUG MODE: display edited Makefile values
#
_handle_makefile_cross_compile() {
    _note "$MSG_NOTE_CC"
    _get_and_display_cross_compile
    _ask_for_edit_cross_compile
    if [[ $EDIT_CC != False ]]
    then
        _check sed -i "s|${r1[0]}|${r1[1]}|g" "${KERNEL_DIR}/Makefile"
        _check sed -i "s|${r2[0]}|${r2[1]}|g" "${KERNEL_DIR}/Makefile"
    fi
    mk=$(grep "${r1[0]}" "${KERNEL_DIR}/Makefile")
    if [[ -n ${mk##*"${cross/CROSS_COMPILE=/}"*} ]]
    then _error WARN "$MSG_WARN_CC"
    fi
    if [[ $DEBUG_MODE == True ]] && [[ $EDIT_CC != False ]]
    then
        echo -e "\n${BLUE}${MSG_DEBUG_CC}:$NC"
        _get_and_display_cross_compile
    fi
}

# RUN MAKE CLEAN
_make_clean() {
    _note "$MSG_NOTE_MAKE_CLEAN [${LINUX_VERSION}]..."
    _check unbuffer make -C "$KERNEL_DIR" clean 2>&1
}

# RUN MAKE MRPROPER
_make_mrproper() {
    _note "$MSG_NOTE_MRPROPER [${LINUX_VERSION}]..."
    _check unbuffer make -C "$KERNEL_DIR" mrproper 2>&1
}


# RUN MAKE DEFCONFIG
_make_defconfig() {
    _note "$MSG_NOTE_DEFCONFIG $DEFCONFIG [${LINUX_VERSION}]..."
    _check unbuffer make -C "$KERNEL_DIR" \
        O="$OUT_DIR" ARCH="$ARCH" "$DEFCONFIG" 2>&1
}

# RUN MAKE MENUCONFIG
_make_menuconfig() {
    _note "$MSG_NOTE_MENUCONFIG $DEFCONFIG [${LINUX_VERSION}]..."
    make -C "$KERNEL_DIR" O="$OUT_DIR" \
        ARCH="$ARCH" menuconfig "${OUT_DIR}/.config"
}

# SAVE DEFCONFIG from MENUCONFIG
# ==============================
# When an existing defconfig file is modified with menuconfig,
# the original defconfig will be saved as "example_defconfig_old"
#
_save_defconfig() {
    _note "$MSG_NOTE_SAVE $DEFCONFIG (arch/${ARCH}/configs)..."
    if [[ -f "${CONF_DIR}/$DEFCONFIG" ]]
    then
        _check cp \
            "${CONF_DIR}/$DEFCONFIG" \
            "${CONF_DIR}/${DEFCONFIG}_old"
    fi
    _check cp "${OUT_DIR}/.config" "${CONF_DIR}/$DEFCONFIG"
}

# RUN MAKE BUILD
# ==============
# - set Telegram HTML message
# - send build status on Telegram
# - CLANG: CROSS_COMPILE_ARM32 -> CROSS_COMPILE_COMPAT (linux > v4.2)
# - make new android kernel build
#
_make_build() {
    _note "${MSG_NOTE_MAKE}: ${KERNEL_NAME}..."
    _set_html_status_msg
    _send_start_build_status
    linuxversion="${LINUX_VERSION//.}"
    if [[ $(echo "${linuxversion:0:2} > 42" | bc) == 1 ]] && \
        [[ ${TC_OPTIONS[3]} == clang ]]
    then cflags=${cflags/CROSS_COMPILE_ARM32/CROSS_COMPILE_COMPAT}
    fi
    _check unbuffer make -C "$KERNEL_DIR" -j"$CORES" \
        O="$OUT_DIR" ARCH="$ARCH" "${TC_OPTIONS[*]}" 2>&1
}


#################################################################
### ZIP - ALL THE FUNCTIONS FOR THE SIGNED ZIP CREATION...
#################################################################

# FLASHABLE ZIP CREATION
# ======================
# - send status on Telegram
# - move image to AK3 folder
# - set AK3 configuration
# - create Flashable ZIP
# - move ZIP to builds folder
#   ----------------
#   $1 = kernel name
#   $2 = kernel image
#   $3 = build folder
#
_zip() {
    _note "$MSG_NOTE_ZIP ${1}.zip..."
    _send_zip_creation_status
    _check cp "$2" "$ANYKERNEL_DIR"
    _cd "$ANYKERNEL_DIR" "$MSG_ERR_DIR ${RED}AnyKernel"
    if [[ $START_TIME ]]; then _set_ak3_conf; fi

    _check unbuffer zip -r9 "${1}.zip" \
        ./* -x .git README.md ./*placeholder 2>&1

    if [[ ! -d $3 ]]; then _check mkdir "$3"; fi
    _check mv "${1}.zip" "$3"
    _cd "$DIR" "$MSG_ERR_DIR ${RED}$DIR"
}

# ZIP SIGNING with AOSP Keys
# ==========================
# - send signing status on Telegram
# - sign ZIP with AOSP Keys (JAVA)
#   ----------------
#   $1 = kernel name
#
_sign_zip() {
    if which java &>/dev/null
    then
        _note "${MSG_NOTE_SIGN}..."
        _send_zip_signing_status
        _check unbuffer java -jar \
            "${DIR}/bin/zipsigner-3.0-dexed.jar" \
            "${1}.zip" "${1}-signed.zip" 2>&1
    else _error WARN "$MSG_WARN_JAVA"
    fi
}

# ANYKERNEL CONFIGURATION
# =======================
# - edit anykernel.sh (SED)
# - edit init.spectrum.rc (SED)
#
_set_ak3_conf() {

    # init.spectrum.rc
    if [[ -f ${KERNEL_DIR}/$SPECTRUM ]]
    then
        _check cp -af \
            "${KERNEL_DIR}/$SPECTRUM" \
            init.spectrum.rc
        kn=$KERNEL_NAME
        _check sed -i \
            "s/*.spectrum.kernel.*/*.spectrum.kernel ${kn}/g" \
            init.spectrum.rc
    fi

    # anykernel.sh
    strings=(
        "s/kernel.string=.*/kernel.string=${TAG}-${CODENAME}/g"
        "s/kernel.for=.*/kernel.for=${KERNEL_VARIANT}/g"
        "s/kernel.compiler=.*/kernel.compiler=${COMPILER}/g"
        "s/kernel.made=.*/kernel.made=${BUILDER}/g"
        "s/kernel.version=.*/kernel.version=${LINUX_VERSION}/g"
        "s/message.word=.*/message.word=ZenMaxBuilder/g"
        "s/build.date=.*/build.date=${DATE}/g"
        "s/device.name1=.*/device.name1=${CODENAME}/g")
    for string in "${strings[@]}"
    do _check sed -i "$string" anykernel.sh
    done
}

# CLEAN ANYKERNEL REPOSITORY
_clean_anykernel() {
    _note "${MSG_NOTE_CLEAN_AK3}..."
    for file in "${DIR}/${ANYKERNEL_DIR}"/*
    do
        case $file in (*.zip*|*Image*|*-dtb*|*spectrum.rc*)
            rm -f "${file}" || sleep 0.1
        esac
    done
}


#################################################################
### TELEGRAM - ALL THE FUNCTIONS FOR TELEGRAM FEEDBACK...
#################################################################

### TELEGRAM API ###
####################

api="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN"

# SEND MESSAGE (POST)
# ===================
#  $1 = message
#
_send_msg() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${api}/sendMessage" \
        -d "parse_mode=html" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$1" \
        | tee /dev/null
}

# SEND FILE (POST)
# ================
#  $1 = file
#  $2 = caption
#
_send_file() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${api}/sendDocument" \
        -F "document=@$1" \
        -F "caption=$2" \
        -F "chat_id=$TELEGRAM_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        | tee /dev/null
}

### KERNEL BUILD STATUS ###
###########################

# START BUILD STATUS
_send_start_build_status() {
    if [[ $BUILD_STATUS == True ]]
    then _send_msg "${STATUS_MSG//_/-}"
    fi
}

# SUCCESS BUILD STATUS
_send_success_build_status() {
    if [[ $BUILD_STATUS == True ]]
    then
        msg="$MSG_NOTE_SUCCESS $BUILD_TIME"
        _send_msg "${KERNEL_NAME//_/-} | $msg"
    fi
}

# ZIP CREATION STATUS
_send_zip_creation_status() {
    if [[ $BUILD_STATUS == True ]]
    then _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_ZIP"
    fi
}

# ZIP SIGNING STATUS
_send_zip_signing_status() {
    if [[ $BUILD_STATUS == True ]]
    then _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_SIGN"
    fi
}

# FAIL BUILD STATUS WITH LOGFILE
_send_failed_build_logs() {
    if [[ $START_TIME ]] && [[ $BUILD_STATUS == True ]] && \
        { [[ ! $BUILD_TIME ]] || [[ $RUN_AGAIN == True ]]; }
    then
        _get_build_time
        _send_file "$LOG" \
            "v${LINUX_VERSION//_/-} | $MSG_TG_FAILED $BUILD_TIME"
    fi
}

# UPLOAD THE KERNEL
_upload_signed_build() {
    if [[ $BUILD_STATUS == True ]] && [[ $FLASH_ZIP == True ]]
    then
        file=${BUILD_DIR}/${KERNEL_NAME}-${DATE}-signed.zip
        _note "${MSG_NOTE_UPLOAD}: ${file##*/}..."
        MD5=$(md5sum "$file" | cut -d' ' -f1)
        caption="${MSG_TG_CAPTION}: $BUILD_TIME"
        _send_file \
            "$file" "$caption | MD5 Checksum: ${MD5//_/-}"
    fi
}

# HTML START BUILD STATUS MESSAGE
_set_html_status_msg() {
    if [[ -z $PLATFORM_VERSION ]]
    then android_version="AOSP Unified"
    else android_version="AOSP $PLATFORM_VERSION"
    fi
    export STATUS_MSG="

<b>${MSG_TG_HTML[0]} :</b>  <code>${CODENAME}</code>
<b>${MSG_TG_HTML[1]} :</b>  <code>v${LINUX_VERSION}</code>
<b>${MSG_TG_HTML[2]} :</b>  <code>${KERNEL_VARIANT}</code>
<b>${MSG_TG_HTML[3]} :</b>  <code>${BUILDER}</code>
<b>${MSG_TG_HTML[4]} :</b>  <code>${CORES} Core(s)</code>
<b>${MSG_TG_HTML[5]} :</b>  <code>${COMPILER} ${TCVER}</code>
<b>${MSG_TG_HTML[6]} :</b>  <code>${HOST}</code>
<b>${MSG_TG_HTML[7]} :</b>  <code>${TAG}</code>
<b>${MSG_TG_HTML[8]} :</b>  <code>${android_version}</code>"
}


#################################################################
### MAIN - RUN THE ZENMAXBUILDER (ZMB) MAIN PROCESS...
#################################################################

# TERMINAL COLORS
_terminal_colors

# TRAP INTERRUPT SIGNALS
trap '_error $MSG_ERR_KBOARD; _exit' INT QUIT TSTP CONT

# DATE AND TIME
if [[ $TIMEZONE == default ]]
then _get_user_timezone; fi
DATE=$(TZ=$TIMEZONE date +%Y-%m-%d)
TIME=$(TZ=$TIMEZONE date +%Hh%Mm%Ss)

# TRANSFROM LONG OPTIONS TO SHORT
for opt in "$@"
do
    shift
    case $opt in
        "--help")   set -- "$@" "-h"; break;;
        "--start")  set -- "$@" "-s";;
        "--update") set -- "$@" "-u";;
        "--msg")    set -- "$@" "-m";;
        "--file")   set -- "$@" "-f";;
        "--zip")    set -- "$@" "-z";;
        "--list")   set -- "$@" "-l";;
        "--tag")    set -- "$@" "-t";;
        "--debug")  set -- "$@" "-d";;
        *)          set -- "$@" "$opt"
    esac
done

# HANDLES OPTIONS ARGUMENTS
if [[ $# -eq 0 ]]
then _error "$MSG_ERR_EOPT"; _exit; fi
while getopts ':hsuldt:m:f:z:' option
do
    case $option in
        h)  clear; _terminal_banner; _usage
            rm -f "./bashvar"; exit 0;;
        u)  _install_dependencies; _full_upgrade; _exit;;
        m)  _install_dependencies; _send_msg_option; _exit;;
        f)  _install_dependencies; _send_file_option; _exit;;
        z)  _install_dependencies; _create_zip_option; _exit;;
        l)  _install_dependencies; _list_all_kernels; _exit;;
        t)  _install_dependencies; _get_linux_tag; _exit;;
        s)  _install_dependencies; clear; _terminal_banner;;
        d)  _install_dependencies; clear; _terminal_banner
            export DEBUG_MODE=True;;
        :)  _error "$MSG_ERR_MARG ${RED}-$OPTARG"
            _exit;;
        \?) _error "$MSG_ERR_IOPT ${RED}-$OPTARG"
            _exit
    esac
done
if [[ $OPTIND -eq 1 ]]
then _error "$MSG_ERR_IOPT ${RED}$1"; _exit; fi
shift $(( OPTIND - 1 ))


#################################################################
### START OPTION - START NEW ANDROID KERNEL COMPILATION...
#################################################################

# PREVENT ERRORS IN USER SETTINGS
if [[ $KERNEL_DIR != default  ]] &&
    [[ ! -f ${KERNEL_DIR}/Makefile ]] && \
    [[ ! -d ${KERNEL_DIR}/arch ]]
then # Bad kernel dir
    _error "$MSG_ERR_KDIR"
    _exit
elif [[ ! $COMPILER =~ ^(default|${PROTON_GCC_NAME}|\
    ${PROTON_CLANG_NAME}|${EVA_GCC_NAME}|${LOS_GCC_NAME}) ]]
then # Bad compiler
    _error "$MSG_ERR_COMPILER"
    _exit
fi

# DEVICE CODENAME
_note "$MSG_NOTE_START $DATE"
_ask_for_codename

# CREATE DEVICE FOLDERS
folders=(builds logs toolchains out)
for folder in "${folders[@]}"
do
    if [[ ! -d ${DIR}/${folder}/$CODENAME ]] && \
        [[ $folder != toolchains ]]
    then
        _check mkdir -p "${DIR}/${folder}/$CODENAME"
    elif [[ ! -d ${DIR}/$folder ]]
    then
        _check mkdir "${DIR}/$folder"
    fi
done

# EXPORT WORKING FOLDERS
export OUT_DIR=${DIR}/out/$CODENAME
export BUILD_DIR=${DIR}/builds/$CODENAME
export PROTON_DIR=${DIR}/toolchains/$PROTON_DIR
export GCC_ARM64_DIR=${DIR}/toolchains/$GCC_ARM64_DIR
export GCC_ARM_DIR=${DIR}/toolchains/$GCC_ARM_DIR
export LOS_ARM64_DIR=${DIR}/toolchains/$LOS_ARM64_DIR
export LOS_ARM_DIR=${DIR}/toolchains/$LOS_ARM_DIR

# ASK QUESTIONS TO THE USER
_ask_for_kernel_dir
_ask_for_defconfig
_ask_for_menuconfig
_ask_for_toolchain
_ask_for_cores

# CLONE AK3 AND REQUIRED TOOLCHAINS
_clone_toolchains
_clone_anykernel

# MAKE KERNEL VERSION
_export_path_and_options
_handle_makefile_cross_compile
_note "${MSG_NOTE_LINUXVER}..."
make -C "$KERNEL_DIR" kernelversion \
    | grep -v make > linuxver & wait $!
LINUX_VERSION=$(cat linuxver)
KERNEL_NAME=${TAG}-${CODENAME}-$LINUX_VERSION

# MAKE CLEAN
_ask_for_make_clean
if [[ $MAKE_CLEAN == True ]]
then _make_clean; _make_mrproper; rm -rf "$OUT_DIR"
fi

# MAKE DEFCONFIG
_make_defconfig
if [[ $MENUCONFIG == True ]]
then
    _make_menuconfig
    _ask_for_save_defconfig
    if [[ $SAVE_DEFCONFIG != False ]]
    then _save_defconfig
    else
        if [[ $ORIGINAL_DEFCONFIG == False ]]
        then
            _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."
            _exit
        fi
    fi
fi

# MAKE KERNEL
_ask_for_new_build
if [[ $NEW_BUILD == False ]]
then _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."; _exit
else
    _ask_for_telegram
    START_TIME=$(TZ=$TIMEZONE date +%s)
    LOG=${DIR}/logs/${CODENAME}/${KERNEL_NAME}_${DATE}_${TIME}.log
    _terminal_banner > "$LOG"
    _make_build | tee -a "$LOG"
fi

# CHECK FOR SUCCESSFUL BUILD
_get_build_time
BOOT_DIR="${DIR}/out/${CODENAME}/arch/${ARCH}/boot"
# shellcheck disable=SC2012
most_recent_file=$(ls -Art "$BOOT_DIR" 2>/dev/null | tail -n 1)
ftime=$(stat -c %Z "${BOOT_DIR}/${most_recent_file}" 2>/dev/null)
if [[ ! -d $BOOT_DIR ]] || [[ -z $(ls -A "$BOOT_DIR") ]] || \
    [[ $ftime < $START_TIME ]]
then _error "$MSG_ERR_MAKE"; _exit; fi

# RETURN BUILD STATUS
_note "$MSG_NOTE_SUCCESS $BUILD_TIME !"
_send_success_build_status

# CREATE FLASHABLE SIGNED ZIP
_ask_for_flashable_zip
if [[ $FLASH_ZIP == True ]]
then
    _ask_for_kernel_image
    _zip "${KERNEL_NAME}-$DATE" "$K_IMG" \
        "$BUILD_DIR" | tee -a "$LOG"
    _sign_zip "${BUILD_DIR}/${KERNEL_NAME}-$DATE" \
        | tee -a "$LOG"
    _note "$MSG_NOTE_ZIPPED !"
fi

# UPLOAD THE BUILD AND EXIT
_upload_signed_build
_clean_anykernel
_exit


# THANKS FOR READING !
# ZMB by darkmaster @grm34

