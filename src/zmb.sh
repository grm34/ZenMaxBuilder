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

# ZMB: ZenMaxBuilder
# ===================
# .0. Starting blocks...                                       (RUN)
# .1. MAIN: the ZenMaxBuilder (ZMB) main function.            (FUNC)
# .2. MANAGER: global management functions of the script.     (FUNC)
# .3. REQUIREMENTS: dependency install management functions.  (FUNC)
# .4. OPTIONS: command line option management functions.      (FUNC)
# .5. START: start new android kernel compilation function.   (FUNC)
# .6. QUESTIONER: functions of questions asked to the user.   (FUNC)
# .7. MAKER: all the functions related to the make process.   (FUNC)
# .8. ZIP: all the functions related to the ZIP creation.     (FUNC)
# .9. TELEGRAM: all the functions for Telegram feedback.      (FUNC)
# 10. ==> run the ZenMaxBuilder (ZMB) main process.            (RUN)
# ------------------------------------------------------------------

# Ensure proper use
if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
  echo "ERROR: ZenMaxBuilder cannot be sourced" >&2
  return 1
elif ! [[ -t 0 ]]; then
  echo "ERROR: run ZenMaxBuilder from a terminal" >&2
  exit 1
elif [[ $(tput cols) -lt 76 ]] || [[ $(tput lines) -lt 12 ]]; then
  echo "ERROR: terminal window is too small (min 76x12)" >&2
  exit 68
elif [[ $(uname) != Linux ]]; then
  echo "ERROR: run ZenMaxBuilder on Linux" >&2
  exit 1
fi

# Absolute path
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
if ! cd "$DIR"; then
  echo "ERROR: ZenMaxBuilder directory not found" >&2
  exit 2
fi

# Lockfile
exec 201> "$(basename "$0").lock"
if ! flock -n 201; then
  echo "ERROR: ZenMaxBuilder is already running" >&2
  exit 114
fi

# Job control
(set -o posix; set)> "${DIR}/bashvar"
set -m -E -o pipefail #-b -v

# Shell settings
shopt -s checkwinsize progcomp
shopt -u autocd cdspell dirspell extglob progcomp_alias

# User language
LANGUAGE="${DIR}/lang/${LANG:0:2}.cfg"
if [[ -f $LANGUAGE ]]; then
  # shellcheck source=/dev/null
  source "$LANGUAGE"
else
  # shellcheck source=/dev/null
  source "${DIR}/lang/en.cfg"
fi

# User configuration
if [[ -f ${DIR}/etc/user.cfg ]]; then
  # shellcheck source=/dev/null
  source "${DIR}/etc/user.cfg"
else
  # shellcheck source=/dev/null
  source "${DIR}/etc/settings.cfg"
fi


###--------------------------------------------------------------###
### .1. MAIN => the ZenMaxBuilder (ZMB) main function            ###
###--------------------------------------------------------------###

_zenmaxbuilder() {
  # 1. set shell colors
  # 2. trap interrupt signals
  # 3. transform long options to short
  # 4. handle general options
  _terminal_colors
  trap '_error $MSG_ERR_KBOARD; _exit 1' INT QUIT TSTP CONT HUP
  if [[ $TIMEZONE == default ]]; then _get_user_timezone; fi
  DATE="$(TZ=$TIMEZONE date +%Y-%m-%d)"
  TIME="$(TZ=$TIMEZONE date +%Hh%Mm%Ss)"
  for opt in "$@"; do
    shift
    case $opt in
      "--help")    set -- "$@" "-h"; break ;;
      "--start")   set -- "$@" "-s" ;;
      "--update")  set -- "$@" "-u" ;;
      "--version") set -- "$@" "-v" ;;
      "--msg")     set -- "$@" "-m" ;;
      "--file")    set -- "$@" "-f" ;;
      "--zip")     set -- "$@" "-z" ;;
      "--list")    set -- "$@" "-l" ;;
      "--tag")     set -- "$@" "-t" ;;
      "--patch")   set -- "$@" "-p" ;;
      "--revert")  set -- "$@" "-r" ;;
      "--debug")   set -- "$@" "-d" ;;
      *)           set -- "$@" "$opt" ;;
    esac
  done
  if [[ $# -eq 0 ]]; then _error "$MSG_ERR_EOPT"; _exit 1; fi
  while getopts ':hsuvldprt:m:f:z:' option; do
    case $option in
      h)  clear; _terminal_banner; _usage; _exit 0 ;;
      u)  _install_dep; _full_upgrade; _exit 0 ;;
      v)  _install_dep; _tc_version_option; _exit 0 ;;
      m)  _install_dep; _send_msg_option; _exit 0 ;;
      f)  _install_dep; _patterns; _send_file_option; _exit 0 ;;
      z)  _install_dep; _create_zip_option; _exit 0 ;;
      l)  _install_dep; _list_all_kernels; _exit 0 ;;
      t)  _install_dep; _get_linux_tag; _exit 0 ;;
      p)  _install_dep; pmod=PATCH; _patch; _exit 0 ;;
      r)  _install_dep; pmod=REVERT; _patch; _exit 0 ;;
      s)  _install_dep; _patterns; _start; _exit 0 ;;
      d)  DEBUG="True"; _install_dep; _patterns; _start; _exit 0 ;;
      :)  _error "$MSG_ERR_MARG ${red}-$OPTARG"; _exit 1 ;;
      \?) _error "$MSG_ERR_IOPT ${red}-$OPTARG"; _exit 1 ;;
    esac
  done
  if [[ $OPTIND -eq 1 ]]; then
    _error "$MSG_ERR_IOPT ${red}$1"; _exit 1
  fi
  shift $(( OPTIND - 1 ))
}


###--------------------------------------------------------------###
### .2. MANAGER => global management functions of the script     ###
###--------------------------------------------------------------###

# Banner
_terminal_banner() {
  echo -e "$bold
   ┌──────────────────────────────────────────────┐
   │  ╔═╗┌─┐┌┐┌  ╔╦╗┌─┐─┐ ┬  ╔╗ ┬ ┬┬┬  ┌┬┐┌─┐┬─┐  │
   │  ╔═╝├┤ │││  ║║║├─┤┌┴┬┘  ╠╩╗│ │││   ││├┤ ├┬┘  │
   │  ╚═╝└─┘┘└┘  ╩ ╩┴ ┴┴ └─  ╚═╝└─┘┴┴─┘─┴┘└─┘┴└─  │
   │ Android Kernel Builder ∆∆ ZMB Neternels Team │
   └──────────────────────────────────────────────┘"
}

# Shell colors
_terminal_colors() {
  if [[ -t 1 ]]; then
    local ncolors; ncolors="$(tput colors)"
    if [[ -n $ncolors ]] && [[ $ncolors -ge 8 ]]; then
      bold="$(tput bold)"
      nc="\e[0m"
      red="$(tput bold setaf 1)"
      green="$(tput bold setaf 2)"
      yellow="$(tput bold setaf 3)"
      lyellow="$(tput setaf 3)"
      blue="$(tput bold setaf 4)"
      magenta="$(tput setaf 5)"
      cyan="$(tput bold setaf 6)"
    fi
  fi
}

# Move to specified directory
_cd() {
  # ARG $1 = the location to go
  # ARG $2 = the error message
  cd "$1" || (_error "$2"; _exit 1)
}

# Ask some information (question or selection)
_prompt() {
    # ARG $1 = the question to ask
    # ARG $2 = question type (1=question/2=selection)
    local length count; length="$*"; count="${#length}"
    echo -ne "\n${yellow}==> ${green}$1 ${yellow}\n==> "
    for (( char=1; char<=count-2; char++ )); do
      echo -ne "─"
    done
    if [[ $2 == 1 ]]; then
      echo -ne "\n==> $nc"
    else
      echo -ne "\n$nc"
    fi
}

# Ask confirmation yes/no
_confirm() {
  # ARG $1 = the question to ask
  # ARG $2 = [Y/n] (to set default <ENTER> behavior)
  confirm="False"
  local count; count="$(( ${#1} + 6 ))"
  echo -ne "${yellow}\n==> ${green}${1} ${red}${2}${yellow}\n==> "
  for (( char=1; char<=count; char++ )); do
    echo -ne "─"
  done
  echo -ne "\n==> $nc"
  read -r confirm
  until [[ -z $confirm ]] || \
      [[ $confirm =~ ^(y|n|Y|N|yes|no|Yes|No|YES|NO) ]]; do
    _error "$MSG_ERR_CONFIRM"
    _confirm_msg "$@"
  done
}

# Display some notes (with timestamp)
_note() {
  # ARG $1 = the note to display
  echo -e "${yellow}\n[$(TZ=$TIMEZONE date +%T)] ${cyan}${1}$nc"
  sleep 1
}

# Display warning or error
_error() {
  # ARG $1 = <warn> for warning (ignore $1 for error)
  # ARG $* = the error or warning message
  if [[ $1 == warn ]]; then
    echo -e "\n${blue}${MSG_WARN}:${nc}${lyellow}${*/warn/}$nc" >&2
  else
    echo -e "\n${red}${MSG_ERROR}: ${nc}${lyellow}${*}$nc" >&2
  fi
}

# Handle shell commands
_check() {
  # ARG $@ = the command to run
  # ?  DEBUG MODE: display command
  # 1. run command as child and wait
  # 2. notify function and file on ERR
  # 3. get failed build logs (+TG feedback)
  # 4. ask to run again last failed command
  local cmd_err line func file; cmd_err="${*}"
  if [[ $DEBUG == True ]]; then
    echo -e "\n${blue}Command:"\
            "${nc}${lyellow}${cmd_err/unbuffer }$nc" >&2
    sleep 0.5
  fi
  until "$@" & wait $!; do
    line="${BASH_LINENO[$i+1]}"
    func="${FUNCNAME[$i+1]}"
    file="${BASH_SOURCE[$i+1]##*/}"
    _error "${cmd_err/unbuffer } ${red}${MSG_ERR_LINE}"\
           "${line}:${nc}${lyellow} ${func}"\
           "${red}${MSG_ERR_FROM}:"\
           "${nc}${lyellow}${file##*/}"
    _get_build_logs
    _ask_for_run_again
    if [[ $run_again == True ]]; then
      if [[ -f $log ]]; then _terminal_banner > "$log"; fi
      if [[ $start_time ]]; then
        start_time="$(TZ=$TIMEZONE date +%s)"
        _send_start_build_status
        "$@" | tee -a "$log" & wait $!
      else
        "$@" & wait $!
      fi
    else
      _exit 1; break
    fi
  done
}

# Properly exit the script
_exit() {
  # ARG: $1 = exit code
  # 1. kill make PID child on interrupt
  # 2. get current build logs
  # 3. remove user input files
  # 4. remove empty device folders
  # 5. exit with 3s timeout
  if pidof make; then pkill make || sleep 0.5; fi
  _get_build_logs
  local input_files device_folders
  input_files=(bashvar buildervar linuxver)
  for file in "${input_files[@]}"; do
    if [[ -f $file ]]; then _check rm -f "${DIR}/$file"; fi
  done
  device_folders=(out builds logs)
  for folder in "${device_folders[@]}"; do
    if [[ -d ${DIR}/${folder}/$CODENAME ]] && \
        [[ -z $(ls -A "${DIR}/${folder}/$CODENAME") ]]; then
      _check rm -rf "${DIR}/${folder}/$CODENAME"
    fi
  done
  case $option in
    s|u|z|p|r|d)
      echo
      for (( second=3; second>=1; second-- )); do
        echo -ne "\r\033[K${blue}${MSG_EXIT}"\
                 "in ${magenta}${second}${blue}"\
                 "second(s)...$nc"
        sleep 0.9
      done
      echo
    ;;
  esac
  if [[ $1 == 0 ]]; then exit 0; else kill -- $$; fi
}

# Operating system timezone
_get_user_timezone() {
  # Return: TIMEZONE
  TIMEZONE="$( # linux
    (timedatectl | grep 'Time zone' \
      | xargs | cut -d' ' -f3) 2>/dev/null
  )"
  if ! [[ $TIMEZONE ]]; then
    TIMEZONE="$( # termux
      (getprop | grep timezone | cut -d' ' -f2 \
        | sed 's/\[//g' | sed 's/\]//g') 2>/dev/null
    )"
  fi
}

# Current build time
_get_build_time() {
  # Return: BUILD_TIME
  local end_time diff_time min sec
  end_time="$(TZ=$TIMEZONE date +%s)"
  diff_time="$(( end_time - start_time ))"
  min="$(( diff_time / 60 ))"; sec="$(( diff_time % 60 ))"
  BUILD_TIME="${min}m${sec}s"
}

# Handle build logs
_get_build_logs() {
  # 1. get user inputs without excluded from CFG
  # 2. diff bash/user inputs and add them to logfile
  # 3. remove ANSI sequences (colors) from logfile
  # 4. send logfile on Telegram when the build fail
  if [[ -f $log ]]; then
    local null; null="$(IFS=$'|'; echo "${EXCLUDED_VARS[*]}")"
    unset IFS; (set -o posix; set | grep -v "${null//|/\\|}")> \
      "${DIR}/buildervar"
    printf "\n\n### ZMB SETTINGS ###\n" >> "$log"
    diff bashvar buildervar | grep -E \
      "^> [A-Z0-9_]{3,32}=" >> "$log" || sleep 0.5
    sed -ri "s/\x1b\[[0-9;]*[mGKHF]//g" "$log"
    _send_failed_build_logs
  fi
}

# Source some patterns
_patterns() {
  # Return: EXCLUDED_VARS PHOTO_F AUDIO_F VIDEO_F VOICE_F ANIM_F
  # shellcheck source=/dev/null
  source "${DIR}/etc/patterns.cfg"
}


###--------------------------------------------------------------###
### .3. REQUIREMENTS => dependency install management functions  ###
###--------------------------------------------------------------###

# Handle dependency installation
_install_dep() {
  # 1. set the package manager for each Linux distribution
  # 2. get the install command of the current OS package manager
  # 3. install the missing dependencies...
  # NOTE: GCC will not be installed on TERMUX (not fully supported)
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
    local pm_list; pm_list=(pacman yum emerge zypper dnf pkg apt)
    for manager in "${pm_list[@]}"; do
      if which "$manager" &>/dev/null; then
        IFS=" "; local pm; pm="${pm_install_cmd[$manager]}"
        read -ra pm <<< "$pm"
        unset IFS; break
      fi
    done
    if [[ ${pm[3]} ]]; then
      for dep in "${DEPENDENCIES[@]}"; do
        if [[ ${pm[0]} == _ ]] && [[ $dep == gcc ]]; then
          continue
        else
          if [[ $dep == llvm ]]; then dep=llvm-ar; fi
          if [[ $dep == binutils ]]; then dep=ld; fi
          if ! which "${dep}" &>/dev/null; then
            if [[ $dep == llvm-ar ]]; then dep=llvm; fi
            if [[ $dep == ld ]]; then dep=binutils; fi
            _ask_for_install_pkg "$dep"
            if [[ $install_pkg == True ]]; then
              if [[ ${pm[0]} == _ ]]; then pm=("${pm[@]:1}"); fi
              "${pm[@]}" "$dep"
            fi
          fi
        fi
      done
    else
      _error "$MSG_ERR_OS"
    fi
    _clone_anykernel
  fi
}

# Git clone some toolchains
_clone_tc() {
  # ARG $1 = repo branch
  # ARG $2 = repo url
  # ARG $3 = repo folder
  if ! [[ -d $3 ]]; then
    _ask_for_clone_toolchain "${3##*/}"
    if [[ $clone_tc == True ]]; then
      git clone --depth=1 -b "$1" "$2" "$3"
    fi
  fi
}

# Clone the selected toolchains
_clone_toolchains() {
  case $COMPILER in
    # Proton-Clang or Proton-GCC
    "$PROTON_CLANG_NAME"|"$PROTON_GCC_NAME")
      _clone_tc "$PROTON_BRANCH" "$PROTON_URL" "$PROTON_DIR"
      ;;
  esac
  case $COMPILER in
    # Eva-GCC or Proton-GCC
    "$EVA_GCC_NAME"|"$PROTON_GCC_NAME")
      _clone_tc "$GCC_ARM_BRANCH" "$GCC_ARM_URL" "$GCC_ARM_DIR"
      _clone_tc "$GCC_ARM64_BRANCH" "$GCC_ARM64_URL" \
                "$GCC_ARM64_DIR"
      ;;
  esac
  case $COMPILER in
    # Lineage-GCC
    "$LOS_GCC_NAME")
      _clone_tc "$LOS_ARM_BRANCH" "$LOS_ARM_URL" "$LOS_ARM_DIR"
      _clone_tc "$LOS_ARM64_BRANCH" "$LOS_ARM64_URL" \
                "$LOS_ARM64_DIR"
      ;;
  esac
}

# Clone anykernel repository
_clone_anykernel() {
  if ! [[ -d $ANYKERNEL_DIR ]]; then
    _ask_for_clone_anykernel
    if [[ $clone_ak == True ]]; then
      git clone -b "$ANYKERNEL_BRANCH" "$ANYKERNEL_URL" \
                   "$ANYKERNEL_DIR"
    fi
  fi
}


###--------------------------------------------------------------###
### .4. OPTIONS => command line option management functions      ###
###--------------------------------------------------------------###

# Update option
#---------------

# Update git repository
_update_git() {
  # ARG $1 = repo branch
  # 1. ALL: checkout and reset to main branch
  # 2. ZMB: check if settings.cfg was updated
  # 3. ZMB: warn the user while settings changed
  # 4. ZMB: rename etc/user.cfg to etc/old.cfg
  # 5. ALL: pull changes
  git checkout "$1"; git reset --hard HEAD
  if [[ $1 == "$ZMB_BRANCH" ]] && \
      [[ -f ${DIR}/etc/user.cfg ]]; then
    local d
    d="$(git diff origin/"$ZMB_BRANCH" "${DIR}/etc/settings.cfg")"
    if [[ -n $d ]]; then
      _error warn "${MSG_CONF}"; echo
      _check mv "${DIR}/etc/user.cfg" "${DIR}/etc/old.cfg"
    fi
  fi
  git pull
}

# Update everything that needs to be
_full_upgrade() {
  # 1. set ZMB and AK3 and TC data
  # 2. upgrade existing stuff...
  local tp up_list; tp="${DIR}/toolchains"
  declare -A up_data=(
    [zmb]="${DIR}€${ZMB_BRANCH}€$MSG_UP_ZMB"
    [ak3]="${ANYKERNEL_DIR}€${ANYKERNEL_BRANCH}€$MSG_UP_AK3"
    [t1]="${tp}/${PROTON_DIR}€${PROTON_BRANCH}€$MSG_UP_CLANG"
    [t2]="${tp}/${GCC_ARM_DIR}€${GCC_ARM_BRANCH}€$MSG_UP_GCC"
    [t3]="${tp}/${GCC_ARM64_DIR}€${GCC_ARM64_BRANCH}€$MSG_UP_GCC64"
    [t4]="${tp}/${LOS_ARM_DIR}€${LOS_ARM_BRANCH}€$MSG_UP_LOS"
    [t5]="${tp}/${LOS_ARM64_DIR}€${LOS_ARM64_BRANCH}€$MSG_UP_LOS64"
  )
  up_list=(zmb ak3 t1 t2 t3 t4 t5)
  for repository in "${up_list[@]}"; do
    IFS="€"; local repo
    repo="${up_data[$repository]}"
    read -ra repo <<< "$repo"
    unset IFS
    if [[ -d ${repo[0]} ]]; then
      _note "${repo[2]}..."
      _cd "${repo[0]}" "$MSG_ERR_DIR ${red}${repo[0]}"
      _update_git "${repo[1]}"
      _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
    fi
  done
}

# Toolchains Versions Option
# ---------------------------

_tc_version_option() {
  _note "${MSG_SCAN_TC}..."
  local v tcn pt gcc
  v=("$PROTON_VERSION" "$GCC_ARM64_VERSION" "$LOS_ARM64_VERSION")
  for tc in "${v[@]}"; do
    if [[ -d ${DIR}/toolchains/$tc ]]; then
      _get_tc_version "$tc"
      case ${tc##*/} in
        *clang*) tcn="$PROTON_GCC_NAME" pt="${tc_version##*/}";;
        *elf*) tcn="$EVA_GCC_NAME" gcc="${tc_version##*/}" ;;
        *android*) tcn="$LOS_GCC_NAME" ;;
      esac
      echo -e "${green}${tcn}: ${red}${tc_version##*/}$nc"
    fi
  done
  if [[ -n $pt ]] && [[ -n $gcc ]]; then
    echo -e "${green}${PROTON_GCC_NAME}: ${red}$pt ${gcc}$nc"
  fi
  if [[ -z $tcn ]]; then _error warn "$MSG_WARN_SCAN_TC"; fi
}

# Telegram options
#------------------

# Send message
_send_msg_option() {
  if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
    _note "${MSG_NOTE_SEND}..."
    _send_msg "${OPTARG//_/-}"
  else
    _error "$MSG_ERR_API"
  fi
}

# Send file
_send_file_option() {
  if [[ -f $OPTARG ]]; then
    if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
      _note "${MSG_NOTE_UPLOAD}: ${OPTARG##*/}..."
      _send_file "$OPTARG"
    else
      _error "$MSG_ERR_API"
    fi
  else
    _error "$MSG_ERR_FILE ${red}$OPTARG"
  fi
}

# List kernels option
#---------------------

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

# Linux tag option
#------------------

_get_linux_tag() {
  _note "${MSG_NOTE_LTAG}..."
  if [[ $OPTARG != v* ]]; then OPTARG="v$OPTARG"; fi
  local ltag; ltag="$(git ls-remote --refs --sort='v:refname' \
    --tags "$LINUX_STABLE" | grep "$OPTARG" | tail --lines=1 \
    | cut --delimiter='/' --fields=3)"
  if [[ $ltag == ${OPTARG}* ]]; then
    _note "${MSG_SUCCESS_LTAG}: ${red}$ltag"
  else
    _error "$MSG_ERR_LTAG ${red}$OPTARG"
  fi
}

# Zip option
#------------

_create_zip_option() {
  if [[ -f $OPTARG ]] && [[ ${OPTARG##*/} == *Image* ]]; then
    _zip "${OPTARG##*/}-${DATE}-$TIME" "$OPTARG" \
      "${DIR}/builds/default"
    _sign_zip \
      "${DIR}/builds/default/${OPTARG##*/}-${DATE}-$TIME"
    _note "$MSG_NOTE_ZIPPED !"
  else
    _error "$MSG_ERR_IMG ${red}$OPTARG"
  fi
}

# Patch Option
#-------------

_patch() {
  case $pmod in
    PATCH) pargs=(-p1) ;;
    REVERT) pargs=(-R -p1) ;;
  esac
  _ask_for_patch
  _ask_for_kernel_dir
  _ask_for_apply_patch
  if [[ $apply_patch == True ]]; then
    _note "${MSG_NOTE_PATCH}: $kpatch > ${KERNEL_DIR##*/}"
    _cd "$KERNEL_DIR" "$MSG_ERR_DIR ${red}$KERNEL_DIR"
    patch "${pargs[@]}" -i "${DIR}/patches/$kpatch"
    _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
  fi
}

# Help option
#-------------

_usage() {
  echo -e "
${bold}Usage:$nc ${green}bash zmb \
${nc}[${lyellow}OPTION${nc}] [${lyellow}ARGUMENT${nc}] \
(e.g. ${magenta}bash zmb --start${nc})

  ${bold}Options$nc
    -h, --help                      $MSG_HELP_H
    -s, --start                     $MSG_HELP_S
    -u, --update                    $MSG_HELP_U
    -v, --version                   $MSG_HELP_V
    -l, --list                      $MSG_HELP_L
    -t, --tag            [v4.19]    $MSG_HELP_T
    -m, --msg          [message]    $MSG_HELP_M
    -f, --file            [file]    $MSG_HELP_F
    -z, --zip     [Image.gz-dtb]    $MSG_HELP_Z
    -p, --patch                     $MSG_HELP_P
    -r, --revert                    $MSG_HELP_R
    -d, --debug                     $MSG_HELP_D

${bold}${MSG_HELP_INFO}: \
${cyan}https://kernel-builder.com$nc\n"
}


###--------------------------------------------------------------###
### .5. START => start new android kernel compilation            ###
###--------------------------------------------------------------###

_start() {

  # Prevent errors in user settings
  if [[ $KERNEL_DIR != default  ]] &&
      ! [[ -f ${KERNEL_DIR}/Makefile ]] && \
      ! [[ -d ${KERNEL_DIR}/arch ]]; then
    _error "$MSG_ERR_CONF_KDIR"; _exit 1
  elif ! [[ $COMPILER =~ ^(default|${PROTON_GCC_NAME}|\
      ${PROTON_CLANG_NAME}|${EVA_GCC_NAME}|\
      ${LOS_GCC_NAME}) ]]; then
    _error "$MSG_ERR_COMPILER"; _exit 1
  fi

  # Start
  clear; _terminal_banner
  _note "$MSG_NOTE_START $DATE"

  # Device codename
  _ask_for_codename

  # Create device folders
  local folders; folders=(builds logs toolchains out)
  for folder in "${folders[@]}"; do
    if ! [[ -d ${DIR}/${folder}/$CODENAME ]] && \
        [[ $folder != toolchains ]]; then
      _check mkdir -p "${DIR}/${folder}/$CODENAME"
    elif ! [[ -d ${DIR}/$folder ]]; then
      _check mkdir "${DIR}/$folder"
    fi
  done

  # Get realpath working folders
  OUT_DIR="${DIR}/out/$CODENAME"
  BUILD_DIR="${DIR}/builds/$CODENAME"
  PROTON_DIR="${DIR}/toolchains/$PROTON_DIR"
  GCC_ARM64_DIR="${DIR}/toolchains/$GCC_ARM64_DIR"
  GCC_ARM_DIR="${DIR}/toolchains/$GCC_ARM_DIR"
  LOS_ARM64_DIR="${DIR}/toolchains/$LOS_ARM64_DIR"
  LOS_ARM_DIR="${DIR}/toolchains/$LOS_ARM_DIR"
  ANYKERNEL_DIR="${DIR}/$ANYKERNEL_DIR"
  BOOT_DIR="${DIR}/out/${CODENAME}/arch/${ARCH}/boot"

  # Ask questions to the user
  _ask_for_kernel_dir
  _ask_for_defconfig
  _ask_for_menuconfig
  _ask_for_cores
  _ask_for_toolchain

  # Clone the selected toolchains
  _clone_toolchains

  # Make kernel version
  _export_path_and_options
  _handle_makefile_cross_compile
  _note "${MSG_NOTE_LINUXVER}..."
  make -C "$KERNEL_DIR" kernelversion \
    | grep -v make > linuxver & wait $!
  LINUX_VERSION="$(cat linuxver)"
  KERNEL_NAME="${TAG}-${CODENAME}-$LINUX_VERSION"

  # Make clean
  _ask_for_make_clean
  if [[ $MAKE_CLEAN == True ]]; then
    _make_clean; _make_mrproper; rm -rf "$OUT_DIR"
  fi

  # Make defconfig
  _make_defconfig
  if [[ $MENUCONFIG == True ]]; then
    _make_menuconfig
    _ask_for_save_defconfig
    if [[ $save_defconfig != False ]]; then
      _save_defconfig
    else
      if [[ $original_defconfig == False ]]; then
        _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."; _exit 0
      fi
    fi
  fi

  # Make the kernel
  _ask_for_new_build
  if [[ $new_build == False ]]; then
    _note "${MSG_NOTE_CANCEL}: ${KERNEL_NAME}..."; _exit 0
  else
    _ask_for_telegram
    start_time="$(TZ=$TIMEZONE date +%s)"
    log="${DIR}/logs/${CODENAME}/${KERNEL_NAME}_${DATE}_${TIME}.log"
    _terminal_banner > "$log"
    _make_build | tee -a "$log"
  fi

  # Status -> zip -> upload the build
  _get_build_time
  local most_recent ftime
  # shellcheck disable=SC2012
  most_recent="$(ls -Art "$BOOT_DIR" 2>/dev/null | tail -n 1)"
  ftime="$(stat -c %Z "${BOOT_DIR}/${most_recent}" 2>/dev/null)"
  if ! [[ -d $BOOT_DIR ]] || [[ -z $(ls -A "$BOOT_DIR") ]] || \
      [[ $ftime < $start_time ]]; then
    _error "$MSG_ERR_MAKE"; _exit 1
  else
    _note "$MSG_NOTE_SUCCESS $BUILD_TIME !"
    _send_success_build_status
    _ask_for_flashable_zip
    if [[ $flash_zip == True ]]; then
      _ask_for_kernel_image
      _zip "${KERNEL_NAME}-$DATE" "$K_IMG" \
           "$BUILD_DIR" | tee -a "$log"
      _sign_zip "${BUILD_DIR}/${KERNEL_NAME}-$DATE" | tee -a "$log"
      _note "$MSG_NOTE_ZIPPED !"
    fi
    _upload_kernel_build
  fi
}


###--------------------------------------------------------------###
### .6. QUESTIONER => functions of questions asked to the user   ###
###--------------------------------------------------------------###

# Question: device codename
_ask_for_codename() {
  # Validation checks: REGEX to prevent invalid string
  # Return: CODENAME
  if [[ $CODENAME == default ]]; then
    _prompt "$MSG_ASK_DEV :" 1
    read -r CODENAME
    local regex; regex="^[a-zA-Z0-9][a-zA-Z0-9_-]{2,19}$"
    until [[ $CODENAME =~ $regex ]]; do
      _error "$MSG_ERR_DEV ${red}$CODENAME"
      _prompt "$MSG_ASK_DEV :" 1
      read -r CODENAME
    done
  fi
}

# Question: kernel location
_ask_for_kernel_dir() {
  # NOTE: we are working here from HOME (auto completion)
  # Validation checks: presence of <configs> folder (ARM)
  # Return: KERNEL_DIR CONF_DIR
  if [[ $KERNEL_DIR == default ]]; then
    _cd "$HOME" "$MSG_ERR_DIR ${red}HOME"
    _prompt "$MSG_ASK_KDIR :" 1
    read -r -e KERNEL_DIR
    until [[ -d ${KERNEL_DIR}/arch/${ARCH}/configs ]]; do
      _error "$MSG_ERR_KDIR ${red}$KERNEL_DIR"
      _prompt "$MSG_ASK_KDIR :" 1
      read -r -e KERNEL_DIR
    done
    KERNEL_DIR="$(realpath "$KERNEL_DIR")"
    CONF_DIR="${KERNEL_DIR}/arch/${ARCH}/configs"
    _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
  fi
}

# Selection: defconfig file
_ask_for_defconfig() {
  # Choices: all defconfig files located in <configs> (ARM)
  # Return: DEFCONFIG
  _cd "$CONF_DIR" "$MSG_ERR_DIR ${red}$CONF_DIR"
  _prompt "$MSG_ASK_DEF :" 2
  select DEFCONFIG in *_defconfig; do
    [[ $DEFCONFIG ]] && break
    _error "$MSG_ERR_SELECT"
  done
  _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
}

# Confirmation: make menuconfig?
_ask_for_menuconfig() {
  # Return: MENUCONFIG
  _confirm "$MSG_ASK_CONF ?" "[y/N]"
  case $confirm in
    y|Y|yes|Yes|YES) MENUCONFIG="True" ;;
  esac
}

# Confirmation: save new defconfig?
_ask_for_save_defconfig() {
  # Otherwise request to continue with the original one
  # Validation checks: REGEX to prevent invalid string
  # Return: DEFCONFIG
  _confirm "${MSG_ASK_SAVE_DEF} ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO)
      save_defconfig="False"
      _confirm "${MSG_ASK_USE_DEF}: $DEFCONFIG ?" "[Y/n]"
      case $confirm in
        n|N|no|No|NO) original_defconfig="False" ;;
      esac
      ;;
    *)
      _prompt "$MSG_ASK_DEF_NAME :" 1
      read -r DEFCONFIG
      local regex; regex="^[a-zA-Z0-9][a-zA-Z0-9_-]{2,25}$"
      until [[ $DEFCONFIG =~ $regex ]]; do
        _error "$MSG_ERR_DEF_NAME ${red}$DEFCONFIG"
        _prompt "$MSG_ASK_DEF_NAME :" 1
        read -r DEFCONFIG
      done
      DEFCONFIG="${DEFCONFIG}_defconfig"
      ;;
  esac
}

# Selection: toolchain compiler
_ask_for_toolchain() {
  # Return: COMPILER
  if [[ $COMPILER == default ]]; then
    _prompt "$MSG_SELECT_TC :" 2
    select COMPILER in $PROTON_CLANG_NAME \
        $EVA_GCC_NAME $PROTON_GCC_NAME $LOS_GCC_NAME; do
      [[ $COMPILER ]] && break
      _error "$MSG_ERR_SELECT"
    done
  fi
}

# Confirmation: edit makefile?
_ask_for_edit_cross_compile() {
  # Return: EDIT_CC
  _confirm "$MSG_ASK_CC $COMPILER ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO) EDIT_CC="False" ;;
  esac
}

# Question: number of cpu cores
_ask_for_cores() {
  # Validation checks: amount of available cores (no limits here)
  # Return: CORES
  local cpu; cpu="$(nproc --all)"
  _confirm "$MSG_ASK_CPU ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO)
      _prompt "$MSG_ASK_CORES :" 1
      read -r CORES
      until (( 1<=CORES && CORES<=cpu )); do
        _error "$MSG_ERR_CORES ${red}${CORES}"\
               "${yellow}(${MSG_ERR_TOTAL}: ${cpu})"
        _prompt "$MSG_ASK_CORES :" 1
        read -r CORES
      done
      ;;
    *) CORES="$cpu" ;;
  esac
}

# Confirmation: make clean and mrproprer?
_ask_for_make_clean() {
  # Return: MAKE_CLEAN
  _confirm "${MSG_ASK_MCLEAN}: v$LINUX_VERSION ?" "[y/N]"
  case $confirm in
    y|Y|yes|Yes|YES) MAKE_CLEAN="True" ;;
  esac
}

# Confirmation: make new build?
_ask_for_new_build() {
  # Return: new_build
  _confirm \
    "$MSG_START ${TAG}-${CODENAME}-$LINUX_VERSION ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO) new_build="False" ;;
  esac
}

# Confirmation: send build status on telegram?
_ask_for_telegram() {
  # Return: build_status
  if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
    _confirm "$MSG_ASK_TG ?" "[y/N]"
    case $confirm in
      y|Y|yes|Yes|YES) build_status="True" ;
    esac
  fi
}

# Confirmation: create flashable zip?
_ask_for_flashable_zip() {
  # Return: flash_zip
  _confirm \
    "$MSG_ASK_ZIP ${TAG}-${CODENAME}-$LINUX_VERSION ?" "[y/N]"
  case $confirm in
    y|Y|yes|Yes|YES) flash_zip="True" ;;
  esac
}

# Question: kernel image
_ask_for_kernel_image() {
  # NOTE: we are working here from <boot> (auto completion)
  # Validation checks: presence of this file
  # Return: K_IMG
  _cd "$BOOT_DIR" "$MSG_ERR_DIR ${red}$BOOT_DIR"
  _prompt "$MSG_ASK_IMG :" 1
  read -r -e K_IMG
  until [[ -f $K_IMG ]]; do
    _error "$MSG_ERR_IMG ${red}$K_IMG"
    _prompt "$MSG_ASK_IMG" 1
    read -r -e K_IMG
  done
  K_IMG="$(realpath "$K_IMG")"
  _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
}

# Confirmation: run again failed command?
_ask_for_run_again() {
  # Return: run_again
  run_again="False"
  _confirm "$MSG_RUN_AGAIN ?" "[y/N]"
  case $confirm in
    y|Y|yes|Yes|YES) run_again="True" ;;
  esac
}

# Confirmation: install missing packages?
_ask_for_install_pkg() {
  # Warn the user that the script may crash while NO
  # Return: install_pkg
  _confirm "${MSG_ASK_PKG}: $1 ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO)
      _error warn "${MSG_WARN_DEP}: ${red}${dep}"; sleep 2
      ;;
    *) install_pkg="True" ;;
  esac
}

# Confirmation: clone missing toolchains?
_ask_for_clone_toolchain() {
  # Warn the user and exit the script while NO
  # Return: clone_tc
  _confirm "${MSG_ASK_CLONE_TC}: $1 ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO)
      _error "${MSG_ERR_CLONE}: ${red}$1"; _exit 1
      ;;
    *) clone_tc="True" ;;
  esac
}

# Confirmation: clone AK3?
_ask_for_clone_anykernel() {
  # Warn the user and exit the script while NO
  # Return: clone_ak
  _confirm "${MSG_ASK_CLONE_AK3}: AK3 ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO)
      _error "${MSG_ERR_CLONE}: ${red}${ANYKERNEL_DIR}"; _exit 1
      ;;
    *) clone_ak="True" ;;
  esac
}

# Selection: kernel patch
_ask_for_patch() {
  # Choices: all patch files located in <patches>
  # Return: kpatch
  _cd "${DIR}/patches" "$MSG_ERR_DIR ${red}${DIR}/patches"
  _prompt "$MSG_ASK_PATCH :" 2
  select kpatch in *.patch; do
    [[ $kpatch ]] && break
    _error "$MSG_ERR_SELECT"
  done
  _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
}

# Confirmation: apply patch?
_ask_for_apply_patch() {
  # Return: apply_patch
  _error warn "$kpatch => ${KERNEL_DIR##*/}"
  _confirm "$MSG_CONFIRM_PATCH (${pmod}) ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO) _exit 0 ;;
    *) apply_patch="True" ;;
  esac
}


###--------------------------------------------------------------###
### .7. MAKER => all the functions related to the make process   ###
###--------------------------------------------------------------###

# Set compiler options
_export_path_and_options() {
  # 1. export target variables (CFG)
  # 2. ensure system support toolchain compiler (verify linker)
  # 3. append toolchains to the $PATH, export and verify
  # 4. get toolchain compiler version
  # 5. get CROSS_COMPILE and CC (to handle Makefile)
  # 6. set Link Time Optimization (LTO)
  # ?  DEBUG MODE: display $PATH
  # Return: PATH TC_OPTIONS TCVER
  if [[ $BUILDER == default ]]; then BUILDER="$(whoami)"; fi
  if [[ $HOST == default ]]; then HOST="$(uname -n)"; fi
  export KBUILD_BUILD_USER="${BUILDER}"
  export KBUILD_BUILD_HOST="${HOST}"
  export PLATFORM_VERSION ANDROID_MAJOR_VERSION
  case $COMPILER in
    "$PROTON_CLANG_NAME")
      TC_OPTIONS=("${PROTON_CLANG_OPTIONS[@]}")
      cross="${PROTON_CLANG_OPTIONS[1]/CROSS_COMPILE=}"
      ccross="${PROTON_CLANG_OPTIONS[3]/CC=}"
      _check_linker "$PROTON_DIR/bin/$ccross"
      export PATH="${PROTON_DIR}/bin:${PATH}"
      _check_tc_path "$PROTON_DIR"
      _get_tc_version "$PROTON_VERSION"
      TCVER="${tc_version##*/}"
      ;;
    "$EVA_GCC_NAME")
      TC_OPTIONS=("${EVA_GCC_OPTIONS[@]}")
      cross="${EVA_GCC_OPTIONS[1]/CROSS_COMPILE=}"
      ccross="${EVA_GCC_OPTIONS[3]/CC=}"
      _check_linker "$GCC_ARM64_DIR/bin/$ccross"
      export PATH="${GCC_ARM64_DIR}/bin:${GCC_ARM_DIR}/bin:${PATH}"
      _check_tc_path "$GCC_ARM64_DIR" "$GCC_ARM_DIR"
      _get_tc_version "$GCC_ARM64_VERSION"
      TCVER="${tc_version##*/}"
      ;;
    "$LOS_GCC_NAME")
      TC_OPTIONS=("${LOS_GCC_OPTIONS[@]}")
      cross="${LOS_GCC_OPTIONS[1]/CROSS_COMPILE=}"
      ccross="${LOS_GCC_OPTIONS[3]/CC=}"
      _check_linker "$LOS_ARM64_DIR/bin/$ccross"
      export PATH="${LOS_ARM64_DIR}/bin:${LOS_ARM_DIR}/bin:${PATH}"
      _check_tc_path "$LOS_ARM64_DIR" "$LOS_ARM_DIR"
      _get_tc_version "$LOS_ARM64_VERSION"
      TCVER="${tc_version##*/}"
      ;;
    "$PROTON_GCC_NAME")
      TC_OPTIONS=("${PROTON_GCC_OPTIONS[@]}")
      cross="${PROTON_GCC_OPTIONS[1]/CROSS_COMPILE=}"
      ccross="${PROTON_GCC_OPTIONS[3]/CC=}"
      _check_linker "$PROTON_DIR/bin/$ccross"
      eva_path="${GCC_ARM64_DIR}/bin:${GCC_ARM_DIR}/bin"
      export PATH="${PROTON_DIR}/bin:${eva_path}:${PATH}"
      _check_tc_path "$PROTON_DIR" "$GCC_ARM_DIR" "$GCC_ARM64_DIR"
      _get_tc_version "$PROTON_VERSION"; v1="$tc_version"
      _get_tc_version "$GCC_ARM64_VERSION"; v2="$tc_version"
      TCVER="${v1##*/} ${v2##*/}"
      ;;
  esac
  if [[ $LTO == True ]]; then
    export LD_LIBRARY_PATH="${PROTON_DIR}/lib"
    TC_OPTIONS[6]="LD=$LTO_LIBRARY"
  fi
  if [[ $DEBUG == True ]]; then
    echo -e "\n${blue}SELECTED COMPILER:"\
            "${nc}${lyellow}${COMPILER} ${TCVER}$nc" >&2
    echo -e "\n${blue}COMPILER OPTIONS:$nc" >&2
    echo -e "${lyellow}ARCH=${ARCH}$nc" >&2
    for opt in "${TC_OPTIONS[@]}"; do
      echo -e "${lyellow}${opt}$nc" >&2
    done
    echo -e "\n${blue}PATH: ${nc}${lyellow}${PATH}$nc" >&2
  fi
}

# Ensure system support toolchain compiler
_check_linker() {
  # ARG: $1 = cross compiler
  local linker
  linker="$(/usr/bin/readelf --all "$1" \
    | grep interpreter | awk -F ": " '{print $NF}')"
  linker="${linker/]}"
  if ! [[ -f $linker ]]; then
    _error warn "$MSG_WARN_LINKER ${red}${linker}$nc"
    _error "$MSG_ERR_LINKER $COMPILER"; _exit 1
  fi
}

# Ensure $PATH has been correctly set
_check_tc_path() {
  # ARG: $@ = toolchains DIR
  for toolchain_path in "$@"; do
    if [[ $PATH != *${toolchain_path}/bin* ]]; then
      _error "$MSG_ERR_PATH"; echo "$PATH"; _exit 1
    fi
  done
}

# Get toolchain version
_get_tc_version() {
  # ARG: $1 = toolchain lib DIR
  tc_version="$(find "${DIR}/toolchains/$1" \
    -mindepth 1 -maxdepth 1 -type d | head -n 1)"
}

# Get CROSS_COMPILE and CC from Makefile
_get_and_display_cross_compile() {
  r1=("^CROSS_COMPILE\s.*?=.*" "CROSS_COMPILE\ ?=\ ${cross}")
  r2=("^CC\s.*=.*" "CC\ =\ ${ccross}\ -I${KERNEL_DIR}")
  local c1 c2
  c1="$(sed -n "/${r1[0]}/{p;}" "${KERNEL_DIR}/Makefile")"
  c2="$(sed -n "/${r2[0]}/{p;}" "${KERNEL_DIR}/Makefile")"
  if [[ -z $c1 ]]; then
    _error "$MSG_ERR_CC"; _exit 1
  else
    echo "$c1"; echo "$c2"
  fi
}

# Handle Makefile CROSS_COMPILE and CC
_handle_makefile_cross_compile() {
  # 1. display them on TERM so user can check before
  # 2. ask to modify them in the kernel Makefile
  # 3. edit the kernel Makefile (SED) while True
  # 4. warn the user when they not seems correctly set
  # ?  DEBUG MODE: display edited Makefile values
  _note "$MSG_NOTE_CC"
  _get_and_display_cross_compile
  _ask_for_edit_cross_compile
  if [[ $EDIT_CC != False ]]; then
    _check sed -i "s|${r1[0]}|${r1[1]}|g" "${KERNEL_DIR}/Makefile"
    _check sed -i "s|${r2[0]}|${r2[1]}|g" "${KERNEL_DIR}/Makefile"
  fi
  local mk; mk="$(grep "${r1[0]}" "${KERNEL_DIR}/Makefile")"
  if [[ -n ${mk##*"${cross/CROSS_COMPILE=/}"*} ]]; then
    _error warn "$MSG_WARN_CC"
  fi
  if [[ $DEBUG == True ]] && [[ $EDIT_CC != False ]]; then
    echo -e "\n${blue}${MSG_DEBUG_CC}:$nc" >&2
    _get_and_display_cross_compile; sleep 0.5
  fi
}

# Make clean process
_make_clean() {
  _note "$MSG_NOTE_MAKE_CLEAN [${LINUX_VERSION}]..."
  _check unbuffer make -C "$KERNEL_DIR" clean 2>&1
}

# Make mrproper process
_make_mrproper() {
  _note "$MSG_NOTE_MRPROPER [${LINUX_VERSION}]..."
  _check unbuffer make -C "$KERNEL_DIR" mrproper 2>&1
}

# Make defconfig process
_make_defconfig() {
  _note "$MSG_NOTE_DEFCONFIG $DEFCONFIG [${LINUX_VERSION}]..."
  _check unbuffer make -C "$KERNEL_DIR" \
    O="$OUT_DIR" ARCH="$ARCH" "$DEFCONFIG" 2>&1
}

# Make menuconfig process
_make_menuconfig() {
  _note "$MSG_NOTE_MENUCONFIG $DEFCONFIG [${LINUX_VERSION}]..."
  make -C "$KERNEL_DIR" O="$OUT_DIR" \
    ARCH="$ARCH" menuconfig "${OUT_DIR}/.config"
}

# Save defconfig from menuconfig
_save_defconfig() {
  # When an existing defconfig file is modified with menuconfig
  # the original defconfig will be saved as "example_defconfig_old"
  _note "$MSG_NOTE_SAVE $DEFCONFIG (arch/${ARCH}/configs)..."
  if [[ -f "${CONF_DIR}/$DEFCONFIG" ]]; then
    _check cp "${CONF_DIR}/$DEFCONFIG" \
              "${CONF_DIR}/${DEFCONFIG}_old"
  fi
  _check cp "${OUT_DIR}/.config" "${CONF_DIR}/$DEFCONFIG"
}

# Make new build process
_make_build() {
  # 1. set Telegram HTML message
  # 2. send build status on Telegram
  # 3. CLANG: CROSS_COMPILE_ARM32 -> CROSS_COMPILE_COMPAT (> v4.2)
  # 4. make new android kernel build
  _note "${MSG_NOTE_MAKE}: ${KERNEL_NAME}..."
  _set_html_status_msg
  _send_start_build_status
  local linuxversion; linuxversion="${LINUX_VERSION//.}"
  if [[ $(echo "${linuxversion:0:2} > 42" | bc) == 1 ]] && \
      [[ ${TC_OPTIONS[3]} == clang ]]; then
    TC_OPTIONS[2]="${TC_OPTIONS[2]/_ARM32=/_COMPAT=}"
  fi
  _check unbuffer make -C "$KERNEL_DIR" -j"$CORES" \
    O="$OUT_DIR" ARCH="$ARCH" "${TC_OPTIONS[*]}" 2>&1
}


###--------------------------------------------------------------###
### .8. ZIP => all the functions related to the ZIP creation     ###
###--------------------------------------------------------------###

# Flashable zip creation
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
  if [[ $start_time ]]; then _clean_anykernel; fi
  _note "$MSG_NOTE_ZIP ${1}.zip..."
  _send_zip_creation_status
  _check cp "$2" "$ANYKERNEL_DIR"
  if ! [[ -f ${ANYKERNEL_DIR}/banner ]]; then
    _check cp "${DIR}/docs/ak3/banner" "${ANYKERNEL_DIR}/banner"
  fi
  _cd "$ANYKERNEL_DIR" "$MSG_ERR_DIR ${red}${ANYKERNEL_DIR}"
  if [[ $start_time ]]; then _set_ak3_conf; fi
  _check unbuffer zip -r9 "${1}.zip" \
    ./* -x .git README.md ./*placeholder 2>&1
  if ! [[ -d $3 ]]; then _check mkdir "$3"; fi
  _check mv "${1}.zip" "$3"
  _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
  _clean_anykernel
}

# Anykernel configuration
_set_ak3_conf() {
  # NOTE: we are working here from AK3 folder
  # 1. copy included files into AK3 (in their dedicated folder)
  # 2. edit anykernel.sh to append device infos (SED)
  for file in "${INCLUDED[@]}"; do
    if [[ -f ${BOOT_DIR}/$file ]]; then
      local inc_dir
      if [[ ${file##*/} == *erofs.dtb ]]; then
        _check mkdir erofs; inc_dir="erofs/"
      elif [[ ${file##*/} != *Image* ]] && \
          [[ ${file##*/} != *erofs.dtb ]] && \
          [[ ${file##*/} == *.dtb ]]; then
        _check mkdir dtb; inc_dir="dtb/";
      else
        inc_dir=""
      fi
      file="$(realpath "${BOOT_DIR}/$file")"
      _check cp -af "$file" "${inc_dir}${file##*/}"
    fi
  done
  local strings; strings=(
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

# Clean anykernel repository
_clean_anykernel() {
  _note "${MSG_NOTE_CLEAN_AK3}..."
  for file in "${INCLUDED[@]}"; do
    if [[ -f ${ANYKERNEL_DIR}/$file ]]; then
      _check rm -rf "${ANYKERNEL_DIR}/${file}"
    fi
  done
  for file in "${ANYKERNEL_DIR}"/*; do
    case $file in
      (*.zip*|*Image*|*erofs*|*dtb*|*spectrum.rc*)
        _check rm -rf "${file}" ;;
    esac
  done
}

# Sign ZIP with AOSP Keys
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
    _error warn "$MSG_WARN_JAVA"
  fi
}


###--------------------------------------------------------------###
### .9. TELEGRAM => all the functions for Telegram feedback      ###
###--------------------------------------------------------------###

# Telegram API
#--------------

# Send message (POST)
_send_msg() {
  # ARG $1 = message
  curl --progress-bar -o /dev/null -fL -X POST -d text="$1" \
    -d parse_mode=html -d chat_id="$TELEGRAM_CHAT_ID" \
    "${TELEGRAM_API}/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
}

# Send file (POST)
_send_file() {
  # ARG $1 = file
  # ARG $2 = caption
  local tg sendtype
  if [[ ${PHOTO_F} =~ ${1##*/*.} ]]; then tg=sendPhoto
  elif [[ ${AUDIO_F} =~ ${1##*/*.} ]]; then tg=sendAudio
  elif [[ ${VIDEO_F} =~ ${1##*/*.} ]]; then tg=sendVideo
  elif [[ ${ANIM_F} =~ ${1##*/*.} ]]; then tg=sendAnimation
  elif [[ ${VOICE_F} =~ ${1##*/*.} ]]; then tg=sendVoice
  else tg=sendDocument
  fi
  sendtype="${tg/send}"
  curl --progress-bar -o /dev/null -fL -X POST \
    -F "${sendtype,}"=@"$1" -F caption="$2" \
    -F chat_id="$TELEGRAM_CHAT_ID" \
    -F disable_web_page_preview=true \
    "${TELEGRAM_API}/bot${TELEGRAM_BOT_TOKEN}/$tg"
}

# Kernel build status
#--------------------

# Start build status
_send_start_build_status() {
  if [[ $build_status == True ]]; then
    _send_msg "${status_msg//_/-}"
  fi
}

# Success build status
_send_success_build_status() {
  if [[ $build_status == True ]]; then
    local msg; msg="$MSG_NOTE_SUCCESS $BUILD_TIME"
    _send_msg "${KERNEL_NAME//_/-} | $msg"
  fi
}

# ZIP creation status
_send_zip_creation_status() {
  if [[ $build_status == True ]]; then
    _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_ZIP"
  fi
}

# ZIP signing status
_send_zip_signing_status() {
  if [[ $build_status == True ]]; then
    _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_SIGN"
  fi
}

# Fail build status (+ logfile)
_send_failed_build_logs() {
  if [[ $start_time ]] && [[ $build_status == True ]] && \
      { ! [[ $BUILD_TIME ]] || [[ $run_again == True ]]; }; then
    _get_build_time
    _send_file "$log" \
      "v${LINUX_VERSION//_/-} | $MSG_TG_FAILED $BUILD_TIME"
  fi
}

# Upload the kernel
_upload_kernel_build() {
  if [[ $build_status == True ]] && [[ $flash_zip == True ]]; then
    local file caption
    file="${BUILD_DIR}/${KERNEL_NAME}-${DATE}-signed.zip"
    if ! [[ -f $file ]]; then file="${file/-signed}"; fi
    _note "${MSG_NOTE_UPLOAD}: ${file##*/}..."
    MD5="$(md5sum "$file" | cut -d' ' -f1)"
    caption="${MSG_TG_CAPTION}: $BUILD_TIME"
    _send_file \
      "$file" "$caption | MD5 Checksum: ${MD5//_/-}"
  fi
}

# HTML start build status message
_set_html_status_msg() {
  local android_version; android_version="AOSP Unified"
  if [[ -n $PLATFORM_VERSION ]]; then
    android_version="${android_version/Unified/$PLATFORM_VERSION}"
  fi
  status_msg="

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


###--------------------------------------------------------------###
### 10. Run the ZenMaxBuilder (ZMB) main process...              ###
###--------------------------------------------------------------###
_zenmaxbuilder "$@"


# THANKS FOR READING !
# ZMB by darkmaster @grm34
# -------------------------

