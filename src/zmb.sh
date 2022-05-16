#!/usr/bin/env bash

# Copyright (c) 2021-2022 darkmaster @grm34 Neternels Team
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

# ZENMAXBUILDER PROJECT
# =====================
# - Starting blocks...
# - MANAGER: global management functions of the script.      (92)
# - REQUIREMENTS: dependency install management functions.  (315)
# - OPTIONS: command line option management functions.      (418)
# - QUESTIONER: functions of questions asked to the user.   (573)
# - MAKER: all the functions related to the make process.   (817)
# - ZIP: all the functions related to the ZIP creation.     (997)
# - TELEGRAM: all the functions for Telegram feedback.     (1090)
# - MAIN: run the ZenMaxBuilder (ZMB) main process.        (1198)
# - START: start new android kernel compilation.           (1257)


# BAN ALL ('n00bz')
if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    echo >&2 "ERROR: ZenMaxBuilder cannot be sourced"
    return 1
elif [[ ! -t 0 ]]; then
    echo >&2 "ERROR: run ZenMaxBuilder from a terminal"
    return 1
elif [[ $(tput cols) -lt 76 ]] || [[ $(tput lines) -lt 12 ]]; then
    echo >&2 "ERROR: terminal window is too small (min 76x12)"
    return 1
elif [[ $(uname) != Linux ]]; then
    echo >&2 "ERROR: run ZenMaxBuilder on Linux"
    return 1
fi

# ABSOLUTE PATH
DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
if ! cd "$DIR"; then
    echo >&2 "ERROR: ZenMaxBuilder directory not found"
    return 1
fi

# LOCKFILE
exec 201> "$(basename "$0").lock"
if ! flock -n 201; then
    echo >&2 "ERROR: ZenMaxBuilder is already running"
    return 1
fi

# JOB CONTROL
(set -o posix; set)> "${DIR}/bashvar"
set -m -E -o pipefail #-b -v

# USER LANGUAGE
LANGUAGE=${DIR}/lang/${LANG:0:2}.cfg
if [[ -f $LANGUAGE ]]; then
    # shellcheck source=/dev/null
    source "$LANGUAGE"
else
    # shellcheck source=/dev/null
    source "${DIR}/lang/en.cfg"
fi

# USER CONFIGURATION
if [[ -f ${DIR}/etc/user.cfg ]]; then
    # shellcheck source=/dev/null
    source "${DIR}/etc/user.cfg"
else
    # shellcheck source=/dev/null
    source "${DIR}/etc/settings.cfg"
fi


#################################################################
### MANAGER => global management functions of the script.     ###
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
    if [[ -t 1 ]]; then
        ncolors=$(tput colors)
        if [[ -n $ncolors ]] && [[ $ncolors -ge 8 ]]; then
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
    if [[ ! $TIMEZONE ]]; then
        TIMEZONE=$(    # Termux
            (getprop | grep timezone | cut -d' ' -f2 \
                | sed 's/\[//g' | sed 's/\]//g') 2>/dev/null
        )
    fi
}

# CURRENT BUILD TIME
_get_build_time() {
    end_time=$(TZ=$TIMEZONE date +%s)
    diff_time=$((end_time - START_TIME))
    min=$((diff_time / 60))
    sec=$((diff_time % 60))
    export BUILD_TIME=${min}m${sec}s
}

# HANDLE BUILD LOGS
_get_build_logs() {
    # 1. get user inputs without excluded from CFG
    # 2. diff bash/user inputs and add them to logfile
    # 3. remove ANSI sequences (colors) from logfile
    # 4. send logfile on Telegram when the build fail
    if [[ -f $LOG ]]; then
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
_cd() {
    # ARG $1 = the location to go
    # ARG $2 = the error message
    cd "$1" || (_error "$2"; _exit)
}

# ASK some INFORMATION
_prompt() {
    # $1 = the question to ask
    # $2 = prompt type (1 for question / 2 for selection)
    lenth=$*
    count=${#lenth}
    echo -ne "\n${YELL}==> ${GREEN}$1"
    echo -ne "${YELL}\n==> "
    for ((char=1; char<=count-2; char++)); do
        echo -ne "─"
    done
    if [[ $2 == 1 ]]; then
        echo -ne "\n==> $NC"
    else
        echo -ne "\n$NC"
    fi
}

# CONFIRMATION PROMPT
_confirm_msg() {
    CONFIRM=False
    count=$((${#1} + 6))
    echo -ne "${YELL}\n==> ${GREEN}${1}"\
             "${RED}${2}${YELL}\n==> "
    for ((char=1; char<=count; char++)); do
        echo -ne "─"
    done
    echo -ne "\n==> $NC"
    read -r CONFIRM
}

# ASK CONFIRMATION yes/no
_confirm() {
    # ARG $1 = the question to ask
    # ARG $2 = [Y/n] (to set default <ENTER> behavior)
    _confirm_msg "$@"
    until [[ -z $CONFIRM ]] || \
    [[ $CONFIRM =~ ^(y|n|Y|N|yes|no|Yes|No|YES|NO) ]]; do
        _error "$MSG_ERR_CONFIRM"
        _confirm_msg "$@"
    done
}

# DISPLAY some NOTES with TIMESTAMP
_note() {
    # ARG $1 = the note to display
    echo -e "${YELL}\n[$(TZ=$TIMEZONE date +%T)] ${CYAN}${1}$NC"
    sleep 1
}

# DISPLAY WARNING or ERROR
_error() {
    # ARG $1 = <WARN> for warning (leave empty for error)
    # ARG $* = ERROR or WARNING message
    if [[ $1 == WARN ]]; then
        echo -e "\n${BLUE}${MSG_WARN}:${NC}${YELLOW}${*/WARN/}$NC"
    else
        echo -e "\n${RED}${MSG_ERROR}: ${NC}${YELLOW}${*}$NC"
    fi
}

# HANDLE SHELL COMMANDS
_check() {
    # ARG $@ = the command to run
    # - DEBUG MODE: display command
    # 1. run command as child and wait
    # 2. notify function and file on ERR
    # 3. get failed build logs (+TG feedback)
    # 4. ask to run again last failed command
    cmd_err=${*}
    if [[ $DEBUG_MODE == True ]]; then
        echo -e "\n${BLUE}Command:"\
                "${NC}${YELLOW}${cmd_err/unbuffer }$NC"
    fi
    until "$@" & wait $!; do
        line=${BASH_LINENO[$i+1]}
        func=${FUNCNAME[$i+1]}
        file=${BASH_SOURCE[$i+1]##*/}
        _error "${cmd_err/unbuffer } ${RED}${MSG_ERR_LINE}"\
               "${line}:${NC}${YELLOW} ${func}"\
               "${RED}${MSG_ERR_FROM}:"\
               "${NC}${YELLOW}${file##*/}"
        _get_build_logs

        _ask_for_run_again
        if [[ $RUN_AGAIN == True ]]; then
            if [[ -f $LOG ]]; then
                _terminal_banner > "$LOG"
            fi
            if [[ $START_TIME ]]; then
                START_TIME=$(TZ=$TIMEZONE date +%s)
                _send_start_build_status
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

# PROPERLY EXIT THE SCRIPT
_exit() {
    # 1. kill make PID child on interrupt
    # 2. get current build logs
    # 3. remove user input files
    # 4. remove empty device folders
    # 5. exit with 3s timeout
    if pidof make; then
        pkill make || sleep 0.1
    fi

    _get_build_logs
    input_files=(bashvar buildervar linuxver)
    for file in "${input_files[@]}"; do
        if [[ -f $file ]]; then
            _check rm -f "${DIR}/$file"
        fi
    done
    device_folders=(out builds logs)
    for folder in "${device_folders[@]}"; do
        if [[ -d ${DIR}/${folder}/$CODENAME ]] && \
        [[ -z $(ls -A "${DIR}/${folder}/$CODENAME") ]]; then
            _check rm -rf "${DIR}/${folder}/$CODENAME"
        fi
    done

    for ((second=3; second>=1; second--)); do
        echo -ne "\r\033[K${BLUE}${MSG_EXIT}"\
                 "in ${MAGENTA}${second}${BLUE}"\
                 "second(s)...$NC"
        sleep 1
    done
    echo && kill -- $$
}


#################################################################
### REQUIREMENTS => dependency install management functions.  ###
#################################################################

# HANDLE DEPENDENCY INSTALLATION
_install_dependencies() {
    # 1. set the package manager for each Linux distribution
    # 2. get the install command of the current OS package manager
    # 3. GCC will not be installed on TERMUX (not fully supported)
    # 4. install the missing dependencies...
    if [[ $AUTO_DEPENDENCIES == True ]]; then
        declare -A pm_install_cmd=(
            [apt]="sudo apt install -y"
            [pkg]="_ pkg install -y"
            [pacman]="sudo pacman -S --noconfirm"
            [yum]="sudo yum install -y"
            [emerge]="sudo emerge -1 -y"
            [zypper]="sudo zypper install -y"
            [dnf]="sudo dnf install -y"
        )
        pm_list=(pacman yum emerge zypper dnf pkg apt)
        for manager in "${pm_list[@]}"; do
            if which "$manager" &>/dev/null; then
                IFS=" "
                pm="${pm_install_cmd[$manager]}"
                read -ra pm <<< "$pm"
                unset IFS
                break
            fi
        done
        if [[ ${pm[3]} ]]; then
            for DEP in "${DEPENDENCIES[@]}"; do
                if [[ ${pm[0]} == _ ]] && [[ $DEP == gcc ]]; then
                    continue
                else
                    if [[ $DEP == llvm ]]; then DEP=llvm-ar; fi
                    if [[ $DEP == binutils ]]; then DEP=ld; fi
                    if ! which "${DEP}" &>/dev/null; then
                        if [[ $DEP == llvm-ar ]]; then DEP=llvm; fi
                        if [[ $DEP == ld ]]; then DEP=binutils; fi
                        _ask_for_install_pkg "$DEP"
                        if [[ $INSTALL_PKG == True ]]; then
                            eval "${pm[0]/_}" "${pm[1]}" \
                                 "${pm[2]}" "${pm[3]}" "$DEP"
                        fi
                    fi
                fi
            done
        else
            _error "$MSG_ERR_OS"
        fi
    fi
}

# GIT CLONE some TOOLCHAINS
_clone_tc() {
    # ARG $1 = repo branch
    # ARG $2 = repo url
    # ARG $3 = repo folder
    if [[ ! -d $3 ]]; then
        _ask_for_clone_toolchain "${3##*/}"
        if [[ $CLONE_TC == True ]]; then
            git clone --depth=1 -b "$1" "$2" "$3"
        fi
    fi
}

# CLONE THE SELECTED TOOLCHAIN COMPILER
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
    if [[ ! -d $ANYKERNEL_DIR ]]; then
        _ask_for_clone_anykernel
        if [[ $CLONE_AK == True ]]; then
            git clone -b "$ANYKERNEL_BRANCH" \
                "$ANYKERNEL_URL" "$ANYKERNEL_DIR"
        fi
    fi
}


#################################################################
### OPTIONS => command line option management functions.      ###
#################################################################

### UPDATE OPTION ###
#####################

# UPDATE GIT REPOSITORY
_update_git() {
    # ARG $1 = repo branch
    # 1. ALL: checkout and fetch
    # 2. ZMB: check if settings.cfg was updated
    # 3. ZMB: if True warn the user to create new one
    # 4. ZMB: rename etc/user.cfg to etc/old.cfg
    # 5. ALL: reset to origin then pull changes
    git checkout "$1"
    git fetch origin "$1"
    if [[ $1 == zmb ]] && [[ -f ${DIR}/etc/user.cfg ]]; then
        conf=$(git diff origin/zmb "${DIR}/etc/settings.cfg")
        if [[ -n $conf ]] && [[ -f ${DIR}/etc/user.cfg ]]; then
            _error WARN "${MSG_CONF}"; echo
            _check mv "${DIR}/etc/user.cfg" "${DIR}/etc/old.cfg"
        fi
    fi
    git reset --hard "origin/$1"
    git pull
}

# UPDATE EVERYTHING THAT NEEDS TO BE
_full_upgrade() {
    # 1. set ZMB and AK3 and TC data
    # 2. upgrade existing stuff...
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
    for repository in "${up_list[@]}"; do
        IFS="€"
        repo="${up_data[$repository]}"
        read -ra repo <<< "$repo"
        unset IFS
        if [[ -d ${repo[0]} ]]; then
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
    if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
        _note "${MSG_NOTE_SEND}..."
        _send_msg "${OPTARG//_/-}"
    else
        _error "$MSG_ERR_API"
    fi
}

# SEND FILE
_send_file_option() {
    if [[ -f $OPTARG ]]; then
        if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
            _note "${MSG_NOTE_UPLOAD}: ${OPTARG##*/}..."
            _send_file "$OPTARG"
        else
            _error "$MSG_ERR_API"
        fi
    else
        _error "$MSG_ERR_FILE ${RED}$OPTARG"
    fi
}

### LIST KERNELS OPTION ###
###########################
_list_all_kernels() {
    if [[ -d ${DIR}/out ]] && \
    [[ $(ls -d out/*/ 2>/dev/null) ]]; then
        _note "${MSG_NOTE_LISTKERNEL}:"
        find out/ -mindepth 1 -maxdepth 1 -type d \
            | cut -f2 -d'/' | cat -n
    else
        _error "$MSG_ERR_LISTKERNEL"
    fi
}

### LINUX TAG OPTION ###
########################
_get_linux_tag() {
    _note "${MSG_NOTE_LTAG}..."
    ltag=$(git ls-remote --refs --sort='v:refname' --tags \
        "$LINUX_STABLE" | grep "$OPTARG" | tail --lines=1 \
        | cut --delimiter='/' --fields=3)
    if [[ $ltag == ${OPTARG}* ]]; then
        _note "${MSG_SUCCESS_LTAG}: ${RED}$ltag"
    else
        _error "$MSG_ERR_LTAG ${RED}$OPTARG"
    fi
}

### ZIP OPTION ###
##################
_create_zip_option() {
    if [[ -f $OPTARG ]] && [[ ${OPTARG##*/} == *Image* ]]; then
        _zip "${OPTARG##*/}-${DATE}-$TIME" "$OPTARG" \
            "${DIR}/builds/default"
        _sign_zip \
            "${DIR}/builds/default/${OPTARG##*/}-${DATE}-$TIME"
        _note "$MSG_NOTE_ZIPPED !"
    else
        _error "$MSG_ERR_IMG ${RED}$OPTARG"
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
### QUESTIONER => functions of questions asked to the user.   ###
#################################################################

# QUESTION: GET THE DEVICE CODENAME
_ask_for_codename() {
    # Validation checks REGEX to prevent invalid string.
    # Match "letters" and "numbers" and "-" and "_" only.
    # Should be at least "3" characters long and maximum "20".
    # Device codename can't start with "_" or "-" characters.
    if [[ $CODENAME == default ]]; then
        _prompt "$MSG_ASK_DEV :" 1
        read -r CODENAME
        regex="^[a-zA-Z0-9][a-zA-Z0-9_-]{2,19}$"
        until [[ $CODENAME =~ $regex ]]; do
            _error "$MSG_ERR_DEV ${RED}$CODENAME"
            _prompt "$MSG_ASK_DEV :" 1
            read -r CODENAME
        done
    fi
}

# QUESTION: GET THE KERNEL LOCATION
_ask_for_kernel_dir() {
    # Validation checks the presence of the "configs"
    # folder corresponding to the current architecture.
    if [[ $KERNEL_DIR == default ]]; then
        _prompt "$MSG_ASK_KDIR :" 1
        read -r -e KERNEL_DIR
        until [[ -d ${KERNEL_DIR}/arch/${ARCH}/configs ]]; do
            _error "$MSG_ERR_KDIR ${RED}$KERNEL_DIR"
            _prompt "$MSG_ASK_KDIR :" 1
            read -r -e KERNEL_DIR
        done
        KERNEL_DIR=$(realpath "$KERNEL_DIR")
    fi
}

# SELECTION: GET THE DEFCONFIG FILE TO USE
_ask_for_defconfig() {
    # Choices: all defconfig files located in "configs"
    # folder corresponding to the current architecture.
    # Validation checks are not needed here.
    CONF_DIR="${KERNEL_DIR}/arch/${ARCH}/configs"
    _cd "$CONF_DIR" "$MSG_ERR_DIR ${RED}$CONF_DIR"
    _prompt "$MSG_ASK_DEF :" 2
    select DEFCONFIG in *_defconfig; do
        [[ $DEFCONFIG ]] && break
        _error "$MSG_ERR_SELECT"
    done
    _cd "$DIR" "$MSG_ERR_DIR ${RED}$DIR"
}

# CONFIRMATION: RUN <make menuconfig>
_ask_for_menuconfig() {
    # Validation checks are not needed here.
    _confirm "$MSG_ASK_CONF ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export MENUCONFIG=True
    esac
}

# CONFIRMATION: SAVE NEW DEFCONFIG
_ask_for_save_defconfig() {
    # Otherwise request to continue with the original one.
    # Validation checks REGEX to prevent invalid string.
    # Match "letters" and "numbers" and "-" and "_" only.
    # Should be at least "3" characters long and maximum "26".
    # Defconfig file can't start with "_" or "-" characters.
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
            until [[ $DEFCONFIG =~ $regex ]]; do
                _error "$MSG_ERR_DEF_NAME ${RED}$DEFCONFIG"
                _prompt "$MSG_ASK_DEF_NAME :" 1
                read -r DEFCONFIG
            done
            export DEFCONFIG=${DEFCONFIG}_defconfig
    esac
}

# SELECTION: GET THE TOOLCHAIN TO USE
_ask_for_toolchain() {
    # Choices: Proton-Clang Eva-GCC Proton-GCC
    # Validation checks are not needed here.
    if [[ $COMPILER == default ]]; then
        _prompt "$MSG_SELECT_TC :" 2
        select COMPILER in $PROTON_CLANG_NAME \
        $EVA_GCC_NAME $PROTON_GCC_NAME $LOS_GCC_NAME; do
            [[ $COMPILER ]] && break
            _error "$MSG_ERR_SELECT"
        done
    fi
}

# CONFIRMATION: EDIT Makefile CROSS_COMPILE
_ask_for_edit_cross_compile() {
    # Validation checks are not needed here.
    _confirm "$MSG_ASK_CC $COMPILER ?" "[Y/n]"
    case $CONFIRM in n|N|no|No|NO)
        export EDIT_CC=False
    esac
}

# QUESTION: GET THE NUMBER OF CPU CORES TO USE
_ask_for_cores() {
    # Validation checks for a valid number corresponding
    # to the amount of available CPU cores (no limits here).
    # Otherwise all available CPU cores will be used.
    CPU=$(nproc --all)
    _confirm "$MSG_ASK_CPU ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _prompt "$MSG_ASK_CORES :" 1
            read -r CORES
            until (( 1<=CORES && CORES<=CPU )); do
                _error "$MSG_ERR_CORES ${RED}${CORES}"\
                       "${YELL}(${MSG_ERR_TOTAL}: ${CPU})"
                _prompt "$MSG_ASK_CORES :" 1
                read -r CORES
            done
            ;;
        *) export CORES=$CPU
    esac
}

# CONFIRMATION: RUN <make clean> AND <make mrproprer>
_ask_for_make_clean() {
    # Validation checks are not needed here.
    _confirm "${MSG_ASK_MCLEAN}: v$LINUX_VERSION ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export MAKE_CLEAN=True
    esac
}

# CONFIRMATION: MAKE A NEW BUILD
_ask_for_new_build() {
   # Validation checks are not needed here.
    _confirm \
        "$MSG_START ${TAG}-${CODENAME}-$LINUX_VERSION ?" "[Y/n]"
    case $CONFIRM in n|N|no|No|NO)
        export NEW_BUILD=False
    esac
}

# CONFIRMATION: SEND BUILD STATUS ON TELEGRAM
_ask_for_telegram() {
    # Validation checks are not needed here.
    if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
        _confirm "$MSG_ASK_TG ?" "[y/N]"
        case $CONFIRM in y|Y|yes|Yes|YES)
            export BUILD_STATUS=True
        esac
    fi
}

# CONFIRMATION: CREATE FLASHABLE ZIP
_ask_for_flashable_zip() {
    # Validation checks are not needed here.
    _confirm \
        "$MSG_ASK_ZIP ${TAG}-${CODENAME}-$LINUX_VERSION ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export FLASH_ZIP=True
    esac
}

# QUESTION: GET THE KERNEL IMAGE TO ZIP
_ask_for_kernel_image() {
    # Validation checks the presence of this file in
    # "boot" folder and verify it starts with "Image".
    _cd "$BOOT_DIR" "$MSG_ERR_DIR ${RED}$BOOT_DIR"
    _prompt "$MSG_ASK_IMG :" 1
    read -r -e K_IMG
    until [[ -f $K_IMG ]] && [[ $K_IMG == *Image* ]]; do
        _error "$MSG_ERR_IMG ${RED}$K_IMG"
        _prompt "$MSG_ASK_IMG" 1
        read -r -e K_IMG
    done
    K_IMG=$(realpath "$K_IMG")
    _cd "$DIR" "$MSG_ERR_DIR ${RED}$DIR"
}

# CONFIRMATION: RUN AGAIN LAST FAILED COMMAND
_ask_for_run_again() {
    # Validation checks are not needed here.
    RUN_AGAIN=False
    _confirm "$MSG_RUN_AGAIN ?" "[y/N]"
    case $CONFIRM in y|Y|yes|Yes|YES)
        export RUN_AGAIN=True
    esac
}

# CONFIRMATION: INSTALL MISSING PACKAGE
_ask_for_install_pkg() {
    # Warn the user that when false the script may crash.
    # Validation checks are not needed here.
    _confirm "${MSG_ASK_PKG}: $1 ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _error WARN "${MSG_WARN_DEP}: ${RED}${DEP}"; sleep 2
            ;;
        *) export INSTALL_PKG=True
    esac
}

# CONFIRMATION: CLONE MISSING TOOLCHAIN
_ask_for_clone_toolchain() {
    # Warn the user and exit the script when false.
    # Validation checks are not needed here.
    _confirm "${MSG_ASK_CLONE_TC}: $1 ?" "[Y/n]"
    case $CONFIRM in
        n|N|no|No|NO)
            _error "${MSG_ERR_CLONE}: ${RED}$1"
            _exit
            ;;
        *) export CLONE_TC=True
    esac
}

# CONFIRMATION: CLONE MISSING ANYKERNEL
_ask_for_clone_anykernel() {
    # Warn the user and exit the script when false.
    # Validation checks are not needed here.
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
### MAKER => all the functions related to the make process.   ###
#################################################################

# SET COMPILER BUILD OPTIONS
_export_path_and_options() {
    # 1. export target variables (CFG)
    # 2. append toolchains to the $PATH, export and verify
    # 3. get current toolchain compiler options
    # 4. get and export toolchain compiler version
    # 5. get CROSS_COMPILE and CC (to handle Makefile)
    # 6. set Link Time Optimization (LTO)
    # 7. DEBUG MODE: display $PATH
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
    if [[ $LTO == True ]]; then
        export LD_LIBRARY_PATH=${PROTON_DIR}/lib
        TC_OPTIONS[6]="LD=$LTO_LIBRARY"
    fi
    if [[ $DEBUG_MODE == True ]]; then
        echo -e "\n${BLUE}PATH: ${NC}${YELLOW}${PATH}$NC"
    fi
}

# ENSURE $PATH HAS BEEN CORRECTLY SET
_check_toolchain_path() {
    # $@ = toolchains DIR
    for toolchain_path in "$@"; do
        if [[ $PATH != *${toolchain_path}/bin* ]]; then
            _error "$MSG_ERR_PATH"; echo "$PATH"; _exit
        fi
    done
}

# GET TOOLCHAIN VERSION
_get_tc_version() {
    # $1 = toolchain lib DIR
    tc_version=$(find "${DIR}/toolchains/$1" \
        -mindepth 1 -maxdepth 1 -type d | head -n 1)
}

# GET CROSS_COMPILE and CC FROM MAKEFILE
_get_and_display_cross_compile() {
    r1=("^CROSS_COMPILE\s.*?=.*" "CROSS_COMPILE\ ?=\ ${cross}")
    r2=("^CC\s.*=.*" "CC\ =\ ${ccross}\ -I${KERNEL_DIR}")
    c1=$(sed -n "/${r1[0]}/{p;}" "${KERNEL_DIR}/Makefile")
    c2=$(sed -n "/${r2[0]}/{p;}" "${KERNEL_DIR}/Makefile")
    if [[ -z $c1 ]]; then
        _error "$MSG_ERR_CC"; _exit
    else
        echo "$c1"; echo "$c2"
    fi
}

# HANDLE Makefile CROSS_COMPILE and CC
_handle_makefile_cross_compile() {
    # 1. display them on TERM so user can check before
    # 2. ask to modify them in the kernel Makefile
    # 3. edit the kernel Makefile (SED) while True
    # 4. warn the user when they not seems correctly set
    # 5. DEBUG MODE: display edited Makefile values
    _note "$MSG_NOTE_CC"
    _get_and_display_cross_compile
    _ask_for_edit_cross_compile
    if [[ $EDIT_CC != False ]]; then
        _check sed -i "s|${r1[0]}|${r1[1]}|g" "${KERNEL_DIR}/Makefile"
        _check sed -i "s|${r2[0]}|${r2[1]}|g" "${KERNEL_DIR}/Makefile"
    fi
    mk=$(grep "${r1[0]}" "${KERNEL_DIR}/Makefile")
    if [[ -n ${mk##*"${cross/CROSS_COMPILE=/}"*} ]]; then
        _error WARN "$MSG_WARN_CC"
    fi
    if [[ $DEBUG_MODE == True ]] && [[ $EDIT_CC != False ]]; then
        echo -e "\n${BLUE}${MSG_DEBUG_CC}:$NC"
        _get_and_display_cross_compile
    fi
}

# RUN: MAKE CLEAN
_make_clean() {
    _note "$MSG_NOTE_MAKE_CLEAN [${LINUX_VERSION}]..."
    _check unbuffer make -C "$KERNEL_DIR" clean 2>&1
}

# RUN: MAKE MRPROPER
_make_mrproper() {
    _note "$MSG_NOTE_MRPROPER [${LINUX_VERSION}]..."
    _check unbuffer make -C "$KERNEL_DIR" mrproper 2>&1
}


# RUN: MAKE DEFCONFIG
_make_defconfig() {
    _note "$MSG_NOTE_DEFCONFIG $DEFCONFIG [${LINUX_VERSION}]..."
    _check unbuffer make -C "$KERNEL_DIR" \
        O="$OUT_DIR" ARCH="$ARCH" "$DEFCONFIG" 2>&1
}

# RUN: MAKE MENUCONFIG
_make_menuconfig() {
    _note "$MSG_NOTE_MENUCONFIG $DEFCONFIG [${LINUX_VERSION}]..."
    make -C "$KERNEL_DIR" O="$OUT_DIR" \
        ARCH="$ARCH" menuconfig "${OUT_DIR}/.config"
}

# SAVE DEFCONFIG from MENUCONFIG
_save_defconfig() {
    # When an existing defconfig file is modified with menuconfig,
    # the original defconfig will be saved as "example_defconfig_old"
    _note "$MSG_NOTE_SAVE $DEFCONFIG (arch/${ARCH}/configs)..."
    if [[ -f "${CONF_DIR}/$DEFCONFIG" ]]; then
        _check cp \
            "${CONF_DIR}/$DEFCONFIG" \
            "${CONF_DIR}/${DEFCONFIG}_old"
    fi
    _check cp "${OUT_DIR}/.config" "${CONF_DIR}/$DEFCONFIG"
}

# RUN: MAKE NEW BUILD
_make_build() {
    # 1. set Telegram HTML message
    # 2. send build status on Telegram
    # 3. CLANG: CROSS_COMPILE_ARM32 -> CROSS_COMPILE_COMPAT (> v4.2)
    # 4. make new android kernel build
    _note "${MSG_NOTE_MAKE}: ${KERNEL_NAME}..."
    _set_html_status_msg
    _send_start_build_status
    linuxversion="${LINUX_VERSION//.}"
    if [[ $(echo "${linuxversion:0:2} > 42" | bc) == 1 ]] && \
    [[ ${TC_OPTIONS[3]} == clang ]]; then
        cflags=${cflags/CROSS_COMPILE_ARM32/CROSS_COMPILE_COMPAT}
    fi
    _check unbuffer make -C "$KERNEL_DIR" -j"$CORES" \
        O="$OUT_DIR" ARCH="$ARCH" "${TC_OPTIONS[*]}" 2>&1
}


#################################################################
### ZIP => all the functions related to the ZIP creation.     ###
#################################################################

# FLASHABLE ZIP CREATION
_zip() {
    # ARG $1 = kernel name
    # ARG $2 = kernel image
    # ARG $3 = build folder
    # 1. send status on Telegram
    # 2. copy image to AK3 folder
    # 3. CD into AK3 folder
    # 4. set AK3 configuration
    # 5. create flashable ZIP
    # 6. move the ZIP into builds folder
    _clean_anykernel
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
    _clean_anykernel
}

# ANYKERNEL CONFIGURATION
_set_ak3_conf() {
    # NOTE: we are working here from AK3 folder
    # 1. copy included files into AK3 (in their dedicated folder)
    # 2. edit anykernel.sh to append device infos (SED)
    for file in "${INCLUDED[@]}"; do
        if [[ -f ${BOOT_DIR}/$file ]]; then
            if [[ ${file##*/} == *erofs.dtb ]]; then
                _check mkdir erofs; inc_dir=erofs/
            elif [[ ${file##*/} != *Image* ]] && \
            [[ ${file##*/} != *erofs.dtb ]] && \
            [[ ${file##*/} == *.dtb ]]; then
                _check mkdir dtb; inc_dir=dtb/;
            else
                inc_dir=""
            fi
            file=$(realpath "${BOOT_DIR}/$file")
            _check cp -af "$file" "${inc_dir}${file##*/}"
        fi
    done
    strings=(
        "s/kernel.string=.*/kernel.string=${TAG}-${CODENAME}/g"
        "s/kernel.for=.*/kernel.for=${KERNEL_VARIANT}/g"
        "s/kernel.compiler=.*/kernel.compiler=${COMPILER}/g"
        "s/kernel.made=.*/kernel.made=${BUILDER}/g"
        "s/kernel.version=.*/kernel.version=${LINUX_VERSION}/g"
        "s/message.word=.*/message.word=ZenMaxBuilder/g"
        "s/build.date=.*/build.date=${DATE}/g"
        "s/device.name1=.*/device.name1=${CODENAME}/g")
    for string in "${strings[@]}"; do
        _check sed -i "$string" anykernel.sh
    done
}

# CLEAN ANYKERNEL REPOSITORY
_clean_anykernel() {
    _note "${MSG_NOTE_CLEAN_AK3}..."
    for file in "${DIR}/${ANYKERNEL_DIR}"/*; do
        case $file in (*.zip*|*Image*|*erofs*|*dtb*|*spectrum.rc*)
            rm -rf "${file}" || sleep 0.1
        esac
    done
    _cd "$ANYKERNEL_DIR" "$MSG_ERR_DIR ${RED}AnyKernel"
    git checkout "$ANYKERNEL_BRANCH"
    git reset --hard "origin/$ANYKERNEL_BRANCH"
    _cd "$DIR" "$MSG_ERR_DIR ${RED}$DIR"
}

# SIGN ZIP with AOSP Keys
_sign_zip() {
    # ARG $1 = kernel name
    # 1. send signing status on Telegram
    # 2. sign ZIP with AOSP Keys (JAVA)
    if which java &>/dev/null; then
        _note "${MSG_NOTE_SIGN}..."
        _send_zip_signing_status
        _check unbuffer java -jar \
            "${DIR}/bin/zipsigner-3.0-dexed.jar" \
            "${1}.zip" "${1}-signed.zip" 2>&1
    else
        _error WARN "$MSG_WARN_JAVA"
    fi
}

#################################################################
### TELEGRAM => all the functions for Telegram feedback.      ###
#################################################################

### TELEGRAM API ###
####################

api="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN"

# SEND MESSAGE (POST)
_send_msg() {
    # ARG $1 = message
    curl --progress-bar -o /dev/null -fL \
        -X POST "${api}/sendMessage" \
        -d "parse_mode=html" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$1" \
        | tee /dev/null
}

# SEND FILE (POST)
_send_file() {
    # ARG $1 = file
    # ARG $2 = caption
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
    if [[ $BUILD_STATUS == True ]]; then
        _send_msg "${STATUS_MSG//_/-}"
    fi
}

# SUCCESS BUILD STATUS
_send_success_build_status() {
    if [[ $BUILD_STATUS == True ]]; then
        msg="$MSG_NOTE_SUCCESS $BUILD_TIME"
        _send_msg "${KERNEL_NAME//_/-} | $msg"
    fi
}

# ZIP CREATION STATUS
_send_zip_creation_status() {
    if [[ $BUILD_STATUS == True ]]; then
        _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_ZIP"
    fi
}

# ZIP SIGNING STATUS
_send_zip_signing_status() {
    if [[ $BUILD_STATUS == True ]]; then
        _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_SIGN"
    fi
}

# FAIL BUILD STATUS (+ LOGFILE)
_send_failed_build_logs() {
    if [[ $START_TIME ]] && [[ $BUILD_STATUS == True ]] && \
    { [[ ! $BUILD_TIME ]] || [[ $RUN_AGAIN == True ]]; }; then
        _get_build_time
        _send_file "$LOG" \
            "v${LINUX_VERSION//_/-} | $MSG_TG_FAILED $BUILD_TIME"
    fi
}

# UPLOAD THE KERNEL
_upload_signed_build() {
    if [[ $BUILD_STATUS == True ]] && [[ $FLASH_ZIP == True ]]; then
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
    if [[ -z $PLATFORM_VERSION ]]; then
        android_version="AOSP Unified"
    else
        android_version="AOSP $PLATFORM_VERSION"
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
### MAIN => run the ZenMaxBuilder (ZMB) main process.         ###
#################################################################

# TERMINAL COLORS
_terminal_colors

# TRAP INTERRUPT SIGNALS
trap '_error $MSG_ERR_KBOARD; _exit' INT QUIT TSTP CONT

# DATE AND TIME
if [[ $TIMEZONE == default ]]; then _get_user_timezone; fi
DATE=$(TZ=$TIMEZONE date +%Y-%m-%d)
TIME=$(TZ=$TIMEZONE date +%Hh%Mm%Ss)

# TRANSFROM LONG OPTIONS TO SHORT
for opt in "$@"; do
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

# HANDLE OPTIONS ARGUMENTS
if [[ $# -eq 0 ]]; then
    _error "$MSG_ERR_EOPT"; _exit; fi
while getopts ':hsuldt:m:f:z:' option; do
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
if [[ $OPTIND -eq 1 ]]; then
    _error "$MSG_ERR_IOPT ${RED}$1"; _exit; fi
shift $(( OPTIND - 1 ))


#################################################################
### START => start new android kernel compilation.            ###
#################################################################

# PREVENT ERRORS IN USER SETTINGS
if [[ $KERNEL_DIR != default  ]] &&
[[ ! -f ${KERNEL_DIR}/Makefile ]] && \
[[ ! -d ${KERNEL_DIR}/arch ]]; then
    _error "$MSG_ERR_KDIR"
    _exit
elif [[ ! $COMPILER =~ ^(default|${PROTON_GCC_NAME}|\
${PROTON_CLANG_NAME}|${EVA_GCC_NAME}|${LOS_GCC_NAME}) ]]; then
    _error "$MSG_ERR_COMPILER"
    _exit
fi

# DEVICE CODENAME
_note "$MSG_NOTE_START $DATE"
_ask_for_codename

# CREATE DEVICE FOLDERS
folders=(builds logs toolchains out)
for folder in "${folders[@]}"; do
    if [[ ! -d ${DIR}/${folder}/$CODENAME ]] && \
    [[ $folder != toolchains ]]; then
        _check mkdir -p "${DIR}/${folder}/$CODENAME"
    elif
        [[ ! -d ${DIR}/$folder ]]
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

# CLONE AK3 AND SELECTED TOOLCHAINS
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
if [[ $MAKE_CLEAN == True ]]; then
    _make_clean; _make_mrproper; rm -rf "$OUT_DIR"
fi

# MAKE DEFCONFIG
_make_defconfig
if [[ $MENUCONFIG == True ]]; then
    _make_menuconfig
    _ask_for_save_defconfig
    if [[ $SAVE_DEFCONFIG != False ]]; then
        _save_defconfig
    else
        if [[ $ORIGINAL_DEFCONFIG == False ]]; then
            _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."
            _exit
        fi
    fi
fi

# MAKE KERNEL
_ask_for_new_build
if [[ $NEW_BUILD == False ]]; then
    _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."; _exit
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
[[ $ftime < $START_TIME ]]; then
    _error "$MSG_ERR_MAKE"; _exit
fi

# RETURN BUILD STATUS
_note "$MSG_NOTE_SUCCESS $BUILD_TIME !"
_send_success_build_status

# CREATE FLASHABLE SIGNED ZIP
_ask_for_flashable_zip
if [[ $FLASH_ZIP == True ]]; then
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

