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

# [ZMB] ZenMaxBuilder...
# -------------------------------------------------------------------
#  0. ==>              Starting blocks...                       (RUN)
#  1. MAIN..........:  ZenMaxBuilder main process              (FUNC)
#  2. MANAGER.......:  global management of the script         (FUNC)
#  3. REQUIREMENTS..:  dependency install management           (FUNC)
#  4. OPTIONS.......:  command line option management          (FUNC)
#  5. START.........:  start new android kernel compilation    (FUNC)
#  6. QUESTIONER....:  questions asked to the user             (FUNC)
#  7. MAKER.........:  everything related to the make process  (FUNC)
#  8. ZIP...........:  everything related to the zip creation  (FUNC)
#  9. TELEGRAM......:  kernel building feedback                (FUNC)
# 10. ==>              run ZenMaxBuilder                        (RUN)
# -------------------------------------------------------------------

# Ensure proper use
if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
  echo "ERROR: ZenMaxBuilder cannot be sourced" >&2
  return 1
elif ! [[ -t 0 ]]; then
  echo "ERROR: run ZenMaxBuilder from a terminal" >&2
  exit 1
elif [[ $(tput cols) -lt 80 ]] || [[ $(tput lines) -lt 12 ]]; then
  echo "ERROR: terminal window is too small (min 80x12)" >&2
  exit 68
elif [[ $(uname) != Linux ]]; then
  echo "ERROR: run ZenMaxBuilder on Linux" >&2
  exit 1
elif [[ $(whoami) == root ]]; then
  echo "ERROR: do not run ZenMaxBuilder as root" >&2
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

# User configuration
# shellcheck source=/dev/null
if [[ -f ${DIR}/etc/user.cfg ]]; then
  source "${DIR}/etc/user.cfg"
else
  source "${DIR}/etc/settings.cfg"
fi

# User language
# shellcheck source=/dev/null
if [[ -f "${DIR}/lang/${LANGUAGE}.cfg" ]]; then
  source "${DIR}/lang/${LANGUAGE}.cfg"
elif [[ -f "${DIR}/lang/${LANG:0:2}.cfg" ]]; then
  source "${DIR}/lang/${LANG:0:2}.cfg"
else
  source "${DIR}/lang/en.cfg"
fi


###---------------------------------------------------------------###
###        1. MAIN => the ZenMaxBuilder main process (ZMB)        ###
###---------------------------------------------------------------###

_zenmaxbuilder() {
  # 1. set shell colors
  # 2. trap interrupt signals
  # 3. transform long options to short
  # 4. handle general options
  _terminal_colors
  trap '_error $MSG_ERR_KBOARD; _exit 1' INT QUIT TSTP CONT HUP
  [[ $TIMEZONE == default ]] && _get_user_timezone
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
      p)  _install_dep; _patch patch; _exit 0 ;;
      r)  _install_dep; _patch revert; _exit 0 ;;
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


###---------------------------------------------------------------###
###    2. MANAGER => global management functions of the script    ###
###---------------------------------------------------------------###

_terminal_banner() {
  echo -e "$bold
   ┌──────────────────────────────────────────────┐
   │  ╔═╗┌─┐┌┐┌  ╔╦╗┌─┐─┐ ┬  ╔╗ ┬ ┬┬┬  ┌┬┐┌─┐┬─┐  │
   │  ╔═╝├┤ │││  ║║║├─┤┌┴┬┘  ╠╩╗│ │││   ││├┤ ├┬┘  │
   │  ╚═╝└─┘┘└┘  ╩ ╩┴ ┴┴ └─  ╚═╝└─┘┴┴─┘─┴┘└─┘┴└─  │
   │ Android Kernel Builder ∆∆ ZMB Neternels Team │
   └──────────────────────────────────────────────┘"
}

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

_cd() {
  # ARG $1 = the location to go
  # ARG $2 = the error message
  cd "$1" || (_error "$2"; _exit 1)
}

_prompt() {
  # Ask some information (question or selection)
  # ARG $1 = the question to ask
  # ARG $2 = question type (1=question/2=selection)
  local length; length="$*"; length="$(( ${#length} - 2 ))"
  echo -ne "\n${yellow}==> ${green}${1}$nc"
  _underline_prompt; [[ $2 == 1 ]] &&
    echo -ne "${yellow}\n==> $nc" || echo -ne "\n$nc"
}

_confirm() {
  # Ask confirmation yes/no
  # ARG $1 = the question to ask
  # ARG $2 = [Y/n] (to set default <ENTER> behavior)
  local length; length="$*"; length="${#length}"
  echo -ne "${yellow}\n==> ${green}${1} ${red}${2}$nc"
  _underline_prompt; confirm="False"
  echo -ne "${yellow}\n==> $nc"
  read -r confirm
  until [[ -z $confirm ]] \
      || [[ $confirm =~ ^(y|n|Y|N|yes|no|Yes|No|YES|NO) ]]; do
    _error "$MSG_ERR_CONFIRM"
    _confirm "$@"
  done
}

_underline_prompt() {
  if [[ $(tput cols) -gt $length ]]; then
    echo -ne "${yellow}\n==> "
    for (( char=1; char<=length; char++ )); do
      echo -ne "─"
    done
  fi
}

_note() {
  # Display some notes (with timestamp)
  # ARG $1 = the note to display
  echo -e "${yellow}\n[$(TZ=$TIMEZONE date +%T)] ${cyan}${1}$nc"
  sleep 1
}

_error() {
  # Display warning or error
  # ARG $1 = <warn> for warning (ignore $1 for error)
  # ARG $* = the error or warning message
  if [[ $1 == warn ]]; then
    echo -e "\n${blue}${MSG_WARN}:${nc}${lyellow}${*/warn/}$nc" >&2
  else
    echo -e "\n${red}${MSG_ERROR}: ${nc}${lyellow}${*}$nc" >&2
  fi
}

_check() {
  # Handle shell commands
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
      [[ -f $log ]] && _terminal_banner > "$log"
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

_exit() {
  # Properly exit the script
  # ARG: $1 = exit code
  # 1. kill running PID childs on interrupt
  # 2. get current build logs
  # 3. remove user input files
  # 4. remove empty device folders
  # 5. exit with 3s timeout
  if [[ $1 != 0 ]]; then
    local pids; pids=(make git wget tar readelf zip java \
      apt pkg pacman yum emerge zypper dnf)
    for pid in "${pids[@]}"; do
      if pidof "$pid"; then pkill "$pid" || sleep 0.5; fi
    done
  fi
  _get_build_logs
  local files device_folders
  files=(bashvar buildervar linuxver wget-log \
    "${AOSP_CLANG_DIR##*/}.tar.gz" "${LLVM_ARM_DIR##*/}.gz"
    "${LLVM_ARM64_DIR##*/}.tar.gz")
  for file in "${files[@]}"; do
    [[ -f $file ]] && _check rm -f "${DIR}/$file"
  done
  device_folders=(out builds logs)
  for folder in "${device_folders[@]}"; do
    if [[ -d ${DIR}/${folder}/$CODENAME ]] \
        && [[ -z $(ls -A "${DIR}/${folder}/$CODENAME") ]]; then
      _check rm -rf "${DIR}/${folder}/$CODENAME"
    fi
  done
  case $option in
    s|u|p|r|d)
      echo
      for (( second=3; second>=1; second-- )); do
        echo -ne "\r\033[K${blue}${MSG_EXIT}"\
                 "in ${magenta}${second}${blue}"\
                 "second(s)...$nc"
        sleep 0.9
      done
      echo ;;
  esac
  if [[ $1 == 0 ]]; then exit 0; else kill -- $$; fi
}

_get_user_timezone() {
  TIMEZONE="$( # linux
    (timedatectl | grep -m 1 'Time zone' \
      | xargs | cut -d' ' -f3) 2>/dev/null
  )"
  [[ ! $TIMEZONE ]] &&
    TIMEZONE="$( # termux
      (getprop | grep -m 1 timezone | cut -d' ' -f2 \
        | sed 's/\[//g' | sed 's/\]//g') 2>/dev/null
    )"
}

_get_build_time() {
  local end_time diff_time min sec
  end_time="$(TZ=$TIMEZONE date +%s)"
  diff_time="$(( end_time - start_time ))"
  min="$(( diff_time / 60 ))"; sec="$(( diff_time % 60 ))"
  BUILD_TIME="${min}m${sec}s"
}

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

_patterns() {
  # Return: EXCLUDED_VARS PHOTO_F AUDIO_F VIDEO_F VOICE_F ANIM_F
  # shellcheck source=/dev/null
  source "${DIR}/etc/patterns.cfg"
}


###---------------------------------------------------------------###
###     3. REQUIREMENTS => dependency installation management     ###
###---------------------------------------------------------------###

_install_dep() {
  # Handle dependency installation
  # 1. set the package managers install command
  # 2. get the current Linux package manager
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
    [[ ${pm[0]} == _ ]] && termux=1
    if [[ ${pm[3]} ]]; then
      for dep in "${DEPENDENCIES[@]}"; do
        if [[ ${pm[0]} == _ ]] && [[ $dep == gcc ]]; then
          continue
        else
          [[ $dep == llvm ]] && dep="llvm-ar"
          [[ $dep == binutils ]] && dep="ld"
          if ! which "${dep}" &>/dev/null; then
            [[ $dep == llvm-ar ]] && dep="llvm"
            [[ $dep == ld ]] && dep="binutils"
            _ask_for_install_pkg "$dep"
            if [[ $install_pkg == True ]]; then
              [[ ${pm[0]} == _ ]] && pm=("${pm[@]:1}")
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

_clone_tc() {
  # ARG $1 = branch/version
  # ARG $2 = url
  # ARG $3 = dir
  if ! [[ -d $3 ]]; then
    _ask_for_clone_toolchain "${3##*/}"
    if [[ $clone_tc == True ]]; then
      case $2 in
        "$AOSP_CLANG_URL"|"$LLVM_ARM64_URL"|"$LLVM_ARM_URL")
          _get_latest_aosp_tag "$2" "$3"
          _install_aosp_tgz "$3" "$1"
          ;;
        *)
          _check unbuffer git clone --depth=1 -b "$1" "$2" "$3"
          ;;
      esac
    fi
  fi
}

_get_latest_aosp_tag() {
  # ARG $1 = url
  # ARG $2 = dir
  # Return: latest tgz
  local url regex rep
  case ${2##*/} in
    "${AOSP_CLANG_DIR##*/}")
      regex="clang-r\d+[a-z]{1}"; rep="${1/+/+archive}"
      ;;
    "${LLVM_ARM64_DIR##*/}"|"${LLVM_ARM_DIR##*/}")
      regex="llvm-r\d+[a-z]{0,1}"
      rep="${1/+refs/+archive\/refs\/heads}"
      ;;
  esac
  url="$(curl -s "$1")"
  latest="$(echo "$url" | grep -oP "${regex}" | tail -n 1)"
  tgz="${rep}/${latest}.tar.gz"
}

_install_aosp_tgz() {
  # ARG $1 = dir
  # ARG $2 = version
  _check mkdir "$1"
  _check unbuffer wget -O "${1##*/}.tar.gz" "$tgz"
  _note "$MSG_TAR_AOSP ${1##*/}.tar.gz > toolchains/${1##*/}"
  _check unbuffer tar -xvf "${1##*/}.tar.gz" -C "$1"
  [[ ! -f ${DIR}/toolchains/$2 ]] &&
    echo "$latest" > "${DIR}/toolchains/$2"
  _check rm "${1##*/}.tar.gz"
  [[ -f wget-log ]] && _check rm wget-log
}

_clone_toolchains() {
  case $COMPILER in # AOSP-Clang
    "$AOSP_CLANG_NAME")
      _clone_tc "$AOSP_CLANG_VERSION" "$AOSP_CLANG_URL" \
                "$AOSP_CLANG_DIR"
      _clone_tc "$LLVM_ARM64_VERSION" "$LLVM_ARM64_URL" \
                "$LLVM_ARM64_DIR"
      _clone_tc "$LLVM_ARM_VERSION" "$LLVM_ARM_URL" \
                "$LLVM_ARM_DIR"
      ;;
  esac
  case $COMPILER in # Neutron-Clang or Neutron-GCC
    "$NEUTRON_CLANG_NAME"|"$NEUTRON_GCC_NAME")
      _clone_tc "$NEUTRON_BRANCH" "$NEUTRON_URL" "$NEUTRON_DIR"
      ;;
  esac
  case $COMPILER in # Proton-Clang or Proton-GCC
    "$PROTON_CLANG_NAME"|"$PROTON_GCC_NAME")
      _clone_tc "$PROTON_BRANCH" "$PROTON_URL" "$PROTON_DIR"
      ;;
  esac
  case $COMPILER in # Eva-GCC or Proton-GCC or Neutron-GCC
    "$EVA_GCC_NAME"|"$PROTON_GCC_NAME"|"$NEUTRON_GCC_NAME")
      _clone_tc "$EVA_ARM_BRANCH" "$EVA_ARM_URL" "$EVA_ARM_DIR"
      _clone_tc "$EVA_ARM64_BRANCH" "$EVA_ARM64_URL" \
                "$EVA_ARM64_DIR"
      ;;
  esac
  case $COMPILER in # Lineage-GCC
    "$LOS_GCC_NAME")
      _clone_tc "$LOS_ARM_BRANCH" "$LOS_ARM_URL" "$LOS_ARM_DIR"
      _clone_tc "$LOS_ARM64_BRANCH" "$LOS_ARM64_URL" \
                "$LOS_ARM64_DIR"
      ;;
  esac
}

_clone_anykernel() {
  if ! [[ -d $ANYKERNEL_DIR ]]; then
    _ask_for_clone_anykernel
    [[ $clone_ak == True ]] &&
      _check unbuffer git clone -b "$ANYKERNEL_BRANCH" \
        "$ANYKERNEL_URL" "$ANYKERNEL_DIR"
  fi
}


###---------------------------------------------------------------###
###         4. OPTIONS => command-line options management         ###
###---------------------------------------------------------------###

# Update option
#---------------

_update_git() {
  # ARG $1 = repo branch
  # 1. ALL: checkout and reset to main branch
  # 2. ZMB: check if settings.cfg was updated
  # 3. ZMB: warn the user while settings changed
  # 4. ZMB: rename etc/user.cfg to etc/old.cfg
  # 5. ALL: pull changes
  git checkout "$1"; git reset --hard HEAD
  if [[ $1 == "$ZMB_BRANCH" ]] \
      && [[ -f ${DIR}/etc/user.cfg ]]; then
    local d
    d="$(git diff origin/"$ZMB_BRANCH" "${DIR}/etc/settings.cfg")"
    if [[ -n $d ]]; then
      _error warn "${MSG_CONF}"; echo
      _check mv "${DIR}/etc/user.cfg" "${DIR}/etc/old.cfg"
    fi
  fi
  _check unbuffer git pull
}

_get_local_aosp_tag() {
  # ARG $1 = dir
  # ARG $2 = version
  # Return: tag
  local regex
  case ${1##*/} in
    "${AOSP_CLANG_DIR##*/}") regex="r\d+[a-z]{1}" ;;
    "${LLVM_ARM64_DIR##*/}"|"${LLVM_ARM_DIR##*/}")
      regex="llvm-r\d+[a-z]{0,1}" ;;
  esac
  tag=$(grep -oP "${regex}" "${DIR}/toolchains/$2")
}

_full_upgrade() {
  # 1. set ZMB and AK3 and TC data
  # 2. upgrade existing stuff...
  local tp up_list; tp="${DIR}/toolchains"
  declare -A up_data=(
    [zmb]="${DIR}€${ZMB_BRANCH}€$MSG_UP_ZMB"
    [ak3]="${ANYKERNEL_DIR}€${ANYKERNEL_BRANCH}"
    [t1]="${tp}/${PROTON_DIR}€${PROTON_BRANCH}"
    [t2]="${tp}/${NEUTRON_DIR}€${NEUTRON_BRANCH}"
    [t3]="${tp}/${EVA_ARM64_DIR}€${EVA_ARM64_BRANCH}"
    [t4]="${tp}/${EVA_ARM_DIR}€${EVA_ARM_BRANCH}"
    [t5]="${tp}/${LOS_ARM64_DIR}€${LOS_ARM64_BRANCH}"
    [t6]="${tp}/${LOS_ARM_DIR}€${LOS_ARM_BRANCH}"
    [t7]="${tp}/${AOSP_CLANG_DIR}€${AOSP_CLANG_URL}€$AOSP_CLANG_VERSION"
    [t8]="${tp}/${LLVM_ARM64_DIR}€${LLVM_ARM64_URL}€$LLVM_ARM64_VERSION"
    [t9]="${tp}/${LLVM_ARM_DIR}€${LLVM_ARM_URL}€$LLVM_ARM_VERSION"
  )
  up_list=(zmb ak3 t1 t2 t3 t4 t5 t6 t7 t8 t9)
  for repository in "${up_list[@]}"; do
    IFS="€"; local repo
    repo="${up_data[$repository]}"
    read -ra repo <<< "$repo"
    unset IFS
    if [[ -d ${repo[0]} ]]; then
      _note "$MSG_UP ${repo[0]##*/}..."
      case $repository in
        t7|t8|t9)
          _get_local_aosp_tag "${repo[0]}" "${repo[2]}"
          _get_latest_aosp_tag "${repo[1]}" "${repo[0]}"
          if [[ $tag != "${latest/clang-}" ]]; then
            _ask_for_update_aosp "${repo[0]##*/}"
            if [[ $update_aosp == True ]]; then
              _check mv "${repo[0]}" "${repo[0]}-${tag/llvm-}"
              _install_aosp_tgz "${repo[0]}" "${repo[2]}"
            fi
          else
            echo "${MSG_ALREADY_UP}: $latest"
          fi
          ;;
        *)
          _cd "${repo[0]}" "$MSG_ERR_DIR ${red}${repo[0]}"
          _update_git "${repo[1]}"
          _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
          ;;
      esac
    fi
  done
}

# Toolchains Versions Option
# ---------------------------

_get_tc_version() {
  # ARG: $1 = toolchain VERSION (from settings.cfg)
  case $1 in
    "$AOSP_CLANG_VERSION"|"$LLVM_ARM64_VERSION"|\
    "$LLVM_ARM_VERSION")
      tc_version="$(head -n 1 "${DIR}/toolchains/$1")"
      ;;
    "$HOST_CLANG_NAME")
      tc_version="$(clang --version | grep -m 1 "clang\|version" \
        | awk -F " " '{print $NF}')"
      ;;
    *)
      tc_version="$(find "${DIR}/toolchains/$1" \
        -mindepth 1 -maxdepth 1 -type d | head -n 1)"
      ;;
  esac
}

_tc_version_option() {
  _note "${MSG_SCAN_TC}..."
  declare -A toolchains_data=(
    [aosp]="${AOSP_CLANG_VERSION}€${AOSP_CLANG_DIR}€$AOSP_CLANG_NAME"
    [llvm]="${LLVM_ARM64_VERSION}€${LLVM_ARM64_DIR}€Binutils"
    [eva]="${EVA_ARM64_VERSION}€${EVA_ARM64_DIR}€$EVA_GCC_NAME"
    [pclang]="${PROTON_VERSION}€${PROTON_DIR}€$PROTON_CLANG_NAME"
    [nclang]="${NEUTRON_VERSION}€${NEUTRON_DIR}€$NEUTRON_CLANG_NAME"
    [los]="${LOS_ARM64_VERSION}€${LOS_ARM64_DIR}€$LOS_GCC_NAME"
    [pgcc]="${PROTON_GCC_NAME}€notfound€$PROTON_GCC_NAME"
    [ngcc]="${NEUTRON_GCC_NAME}€notfound€$NEUTRON_GCC_NAME"
    [host]="${HOST_CLANG_NAME}€found€$HOST_CLANG_NAME"
  )
  local toolchains_list eva_v pt_v nt_v
  toolchains_list=(aosp llvm eva pclang nclang los pgcc ngcc host)
  for toolchain in "${toolchains_list[@]}"; do
    IFS="€"; local tc
    tc="${toolchains_data[$toolchain]}"
    read -ra tc <<< "$tc"
    unset IFS
    if [[ -d ${DIR}/toolchains/${tc[1]/found} ]]; then
      _get_tc_version "${tc[0]}"
      case ${tc[2]} in
        "$EVA_GCC_NAME") eva_v="${tc_version##*/}" ;;
        "$NEUTRON_CLANG_NAME") nt_v="${tc_version##*/}" ;;
        "$PROTON_CLANG_NAME") pt_v="${tc_version##*/}" ;;
      esac
      echo -e "${green}${tc[2]}: ${red}${tc_version##*/}$nc"
    elif [[ -n $eva_v ]] && [[ -n $pt_v ]]; then
      echo -e "${green}${tc[2]}: ${red}${pt_v}/${eva_v}$nc"
      unset pt_v
    elif [[ -n $eva_v ]] && [[ -n $nt_v ]]; then
      echo -e "${green}${tc[2]}: ${red}${nt_v}/${eva_v}$nc"
    fi
  done
}

# Telegram options
#------------------

_send_msg_option() {
  if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
    _note "${MSG_NOTE_SEND}..."; _send_msg "${OPTARG//_/-}"
  else
    _error "$MSG_ERR_API"
  fi
}

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
  if [[ -d ${DIR}/out ]] \
      && [[ $(ls -d out/*/ 2>/dev/null) ]]; then
    _note "${MSG_NOTE_LISTKERNEL}:"
    for kn in "${DIR}"/out/*; do
      [[ -f ${DIR}/out/${kn##*/}/include/generated/compile.h ]] &&
        red="$green"
      # shellcheck disable=SC2012
      data=$(ls -Art "${DIR}/logs/${kn##*/}" 2>/dev/null | tail -n1)
      if [[ -f ${DIR}/logs/${kn##*/}/$data ]]; then
        v=$(grep -m 1 LINUX_VERSION= "${DIR}/logs/${kn##*/}/$data")
        d=$(grep -m 1 DATE= "${DIR}/logs/${kn##*/}/$data")
        c=$(grep -m 1 COMPILER= "${DIR}/logs/${kn##*/}/$data")
        t=$(grep -m 1 TCVER= "${DIR}/logs/${kn##*/}/$data")
        echo -e "${red}${kn##*/}:$nc v${v/> LINUX_VERSION=} on"\
                "${d/> DATE=} with ${c/> COMPILER=} ${t/> TCVER=}"
      else
        echo -e "${red}${kn##*/}:$nc no log found..."
      fi
    done
  else
    _error "$MSG_ERR_LISTKERNEL"
  fi
}

# Linux tag option
#------------------

_get_linux_tag() {
  _note "${MSG_NOTE_LTAG}..."
  [[ $OPTARG != v* ]] && OPTARG="v$OPTARG"
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
  if [[ -f $OPTARG ]]; then
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
  # ARG $1 = patch mode (patch or revert)
  local pargs
  case $1 in
    patch) pargs=(-p1) ;;
    revert) pargs=(-R -p1) ;;
  esac
  _ask_for_patch
  _ask_for_kernel_dir
  _ask_for_apply_patch "${1}"
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


###---------------------------------------------------------------###
###      5. START => new android kernel compilation function      ###
###---------------------------------------------------------------###

_start() {

  # Prevent errors in user settings
  if [[ $KERNEL_DIR != default  ]] \
      && ! [[ -f ${KERNEL_DIR}/Makefile ]] \
      && ! [[ -d ${KERNEL_DIR}/arch/${ARCH}/configs ]]; then
    _error "$MSG_ERR_CONF_KDIR"; _exit 1
  elif ! [[ $COMPILER =~ ^(default|${PROTON_GCC_NAME}|\
      ${PROTON_CLANG_NAME}|${EVA_GCC_NAME}|${HOST_CLANG_NAME}|\
      ${LOS_GCC_NAME}|${AOSP_CLANG_NAME}|${NEUTRON_GCC_NAME}\
      ${NEUTRON_CLANG_NAME}) ]]; then
    _error "$MSG_ERR_COMPILER"; _exit 1
  fi

  # Start
  clear; _terminal_banner
  _note "$MSG_NOTE_START $DATE"
  [[ $termux ]] && _error warn "${MSG_WARN_TERMUX}...?"

  # Device codename
  _ask_for_codename

  # Create device folders
  local folders; folders=(builds logs toolchains out)
  for folder in "${folders[@]}"; do
    if ! [[ -d ${DIR}/${folder}/$CODENAME ]] \
        && [[ $folder != toolchains ]]; then
      _check mkdir -p "${DIR}/${folder}/$CODENAME"
    elif ! [[ -d ${DIR}/$folder ]]; then
      _check mkdir "${DIR}/$folder"
    fi
  done

  # Get realpath working folders
  OUT_DIR="${DIR}/out/$CODENAME"
  BUILD_DIR="${DIR}/builds/$CODENAME"
  PROTON_DIR="${DIR}/toolchains/$PROTON_DIR"
  NEUTRON_DIR="${DIR}/toolchains/$NEUTRON_DIR"
  EVA_ARM64_DIR="${DIR}/toolchains/$EVA_ARM64_DIR"
  EVA_ARM_DIR="${DIR}/toolchains/$EVA_ARM_DIR"
  AOSP_CLANG_DIR="${DIR}/toolchains/$AOSP_CLANG_DIR"
  LLVM_ARM64_DIR="${DIR}/toolchains/$LLVM_ARM64_DIR"
  LLVM_ARM_DIR="${DIR}/toolchains/$LLVM_ARM_DIR"
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

  # Export options and define CC
  _export_path_and_options
  _handle_makefile_cross_compile

  # Make kernel version
  _note "${MSG_NOTE_LINUXVER}..."
  make -C "$KERNEL_DIR" kernelversion \
    | grep -v make > linuxver & wait $!
  LINUX_VERSION="$(head -n 1 linuxver)"
  KERNEL_NAME="${TAG}-${CODENAME}-$LINUX_VERSION"

  # Make clean
  _ask_for_make_clean
  if [[ $MAKE_CLEAN == True ]]; then
    _make_clean; _make_mrproper; rm -rf "$OUT_DIR"
  fi

  # Make configuration
  _make_defconfig
  if [[ $MENUCONFIG ]]; then
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
  local ftime gen; gen="${OUT_DIR}/include/generated/compile.h"
  ftime="$(stat -c %Z "${gen}" 2>/dev/null)"
  if ! [[ -f $gen ]] || [[ $ftime < $start_time ]]; then
    _error "$MSG_ERR_MAKE"; _exit 1
  else
    compiler="$(grep -m 1 LINUX_COMPILER "$gen")"
    compiler="${compiler/\#define }"
    _note "$MSG_NOTE_SUCCESS $BUILD_TIME !"
    _note "$compiler"
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


###---------------------------------------------------------------###
###     6. QUESTIONER => all the questions asked to the user      ###
###---------------------------------------------------------------###

_ask_for_codename() {
  # Question: device codename
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

_ask_for_kernel_dir() {
  # Question: device codename
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

_ask_for_defconfig() {
  # Selection: defconfig file
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

_ask_for_menuconfig() {
  # Confirmation: make menuconfig?
  # Return: MENUCONFIG
  _confirm "$MSG_ASK_CONF ?" "[y/N]"
  case $confirm in
    y|Y|yes|Yes|YES)
      _prompt "$MSG_SELECT_MENU :" 2
      select MENUCONFIG in config menuconfig nconfig xconfig \
          gconfig oldconfig silentoldconfig allyesconfig \
          allmodconfig allnoconfig randconfig localmodconfig \
          localyesconfig; do
        [[ $MENUCONFIG ]] && break
        _error "$MSG_ERR_SELECT"
      done
      ;;
  esac
}

_ask_for_save_defconfig() {
  # Confirmation: save new defconfig?
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

_ask_for_toolchain() {
  # Selection: toolchain compiler
  # Return: COMPILER
  if [[ $COMPILER == default ]]; then
    _prompt "$MSG_SELECT_TC :" 2
    select COMPILER in $AOSP_CLANG_NAME $EVA_GCC_NAME \
        $PROTON_CLANG_NAME $NEUTRON_CLANG_NAME $LOS_GCC_NAME \
        $PROTON_GCC_NAME $NEUTRON_GCC_NAME $HOST_CLANG_NAME; do
      [[ $COMPILER ]] && break
      _error "$MSG_ERR_SELECT"
    done
  fi
}

_ask_for_edit_cross_compile() {
  # Confirmation: edit makefile?
  # Return: EDIT_CC
  _confirm "$MSG_ASK_CC $COMPILER ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO) EDIT_CC="False" ;;
  esac
}

_ask_for_cores() {
  # Question: number of cpu cores
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
      done ;;
    *) CORES="$cpu" ;;
  esac
}

_ask_for_make_clean() {
  # Confirmation: make clean and mrproprer?
  # Return: MAKE_CLEAN
  _confirm "${MSG_ASK_MCLEAN}: v$LINUX_VERSION ?" "[y/N]"
  case $confirm in
    y|Y|yes|Yes|YES) MAKE_CLEAN="True" ;;
  esac
}

_ask_for_new_build() {
  # Confirmation: make new build?
  # Return: new_build
  _confirm \
    "$MSG_START ${TAG}-${CODENAME}-$LINUX_VERSION ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO) new_build="False" ;;
  esac
}

_ask_for_telegram() {
  # Confirmation: send build status on telegram?
  # Return: build_status
  if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
    _confirm "$MSG_ASK_TG ?" "[y/N]"
    case $confirm in
      y|Y|yes|Yes|YES) build_status="True" ;;
    esac
  fi
}

_ask_for_flashable_zip() {
  # Confirmation: create flashable zip?
  # Return: flash_zip
  _confirm \
    "$MSG_ASK_ZIP ${TAG}-${CODENAME}-$LINUX_VERSION ?" "[y/N]"
  case $confirm in
    y|Y|yes|Yes|YES) flash_zip="True" ;;
  esac
}

_ask_for_kernel_image() {
  # Question: kernel image
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

_ask_for_run_again() {
  # Confirmation: run again failed command?
  # Return: run_again
  run_again="False"
  _confirm "$MSG_RUN_AGAIN ?" "[y/N]"
  case $confirm in
    y|Y|yes|Yes|YES) run_again="True" ;;
  esac
}

_ask_for_install_pkg() {
  # Confirmation: install missing packages?
  # Warn the user that the script may crash while NO
  # Return: install_pkg
  _confirm "${MSG_ASK_PKG}: $1 ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO)
      _error warn "${MSG_WARN_DEP}: ${red}${dep}"; sleep 2 ;;
    *) install_pkg="True" ;;
  esac
}

_ask_for_clone_toolchain() {
  # Confirmation: clone missing toolchains?
  # Warn the user and exit the script while NO
  # Return: clone_tc
  _confirm "${MSG_ASK_CLONE_TC}: $1 ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO)
      _error "${MSG_ERR_CLONE}: ${red}$1"; _exit 1 ;;
    *) clone_tc="True" ;;
  esac
}

_ask_for_clone_anykernel() {
  # Confirmation: clone AK3?
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

_ask_for_patch() {
  # Selection: kernel patch
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

_ask_for_apply_patch() {
  # Confirmation: apply patch?
  # ARG $1 = patch mode (patch or revert)
  # Return: apply_patch
  _error warn "$kpatch => ${KERNEL_DIR##*/}"
  _confirm "$MSG_CONFIRM_PATCH (${1^^}) ?" "[Y/n]"
  case $confirm in
    n|N|no|No|NO) _exit 0 ;;
    *) apply_patch="True" ;;
  esac
}

_ask_for_update_aosp() {
  # Confirmation: update AOSP toolchains?
  # ARG $1 = name
  # Return: update_aosp
  _error warn "$1 $MSG_TAG $tag => ${latest/clang-}"
  _confirm "$MSG_CONFIRM_UP $1 ?" "[y/N]"
  case $confirm in
    y|Y|yes|Yes|YES) update_aosp="True" ;;
  esac
}


###---------------------------------------------------------------###
###      7. MAKER => everything related to the make process       ###
###---------------------------------------------------------------###

_aosp_clang_options() {
  TC_OPTIONS=("${AOSP_CLANG_OPTIONS[@]}")
  _check_linker "${1}/$AOSP_CLANG_CHECK" "${1}/$LLVM_ARM64_CHECK"
  local llvm_path
  llvm_path="${LLVM_ARM64_DIR}/bin:${LLVM_ARM_DIR}/bin"
  export PATH="${AOSP_CLANG_DIR}/bin:${llvm_path}:${PATH}"
  _check_tc_path "$AOSP_CLANG_DIR"
  _get_tc_version "$AOSP_CLANG_VERSION"
  TCVER="$tc_version"
  lto_dir="$AOSP_CLANG_DIR/lib"
}

_eva_gcc_options() {
  TC_OPTIONS=("${EVA_GCC_OPTIONS[@]}")
  _check_linker "${1}/$EVA_ARM64_CHECK"
  export PATH="${EVA_ARM64_DIR}/bin:${EVA_ARM_DIR}/bin:${PATH}"
  _check_tc_path "$EVA_ARM64_DIR" "$EVA_ARM_DIR"
  _get_tc_version "$EVA_ARM64_VERSION"
  TCVER="${tc_version##*/}"
  lto_dir="$EVA_ARM64_DIR/lib"
}

_neutron_clang_options() {
  TC_OPTIONS=("${NEUTRON_CLANG_OPTIONS[@]}")
  _check_linker "${1}/$NEUTRON_CHECK"
  export PATH="${NEUTRON_DIR}/bin:${PATH}"
  _check_tc_path "$NEUTRON_DIR"
  _get_tc_version "$NEUTRON_VERSION"
  TCVER="${tc_version##*/}"
  lto_dir="$NEUTRON_DIR/lib"
}

_proton_clang_options() {
  TC_OPTIONS=("${PROTON_CLANG_OPTIONS[@]}")
  _check_linker "${1}/$PROTON_CHECK"
  export PATH="${PROTON_DIR}/bin:${PATH}"
  _check_tc_path "$PROTON_DIR"
  _get_tc_version "$PROTON_VERSION"
  TCVER="${tc_version##*/}"
  lto_dir="$PROTON_DIR/lib"
}

_los_gcc_options() {
  TC_OPTIONS=("${LOS_GCC_OPTIONS[@]}")
  _check_linker "${1}/$LOS_ARM64_CHECK"
  export PATH="${LOS_ARM64_DIR}/bin:${LOS_ARM_DIR}/bin:${PATH}"
  _check_tc_path "$LOS_ARM64_DIR" "$LOS_ARM_DIR"
  _get_tc_version "$LOS_ARM64_VERSION"
  TCVER="${tc_version##*/}"
  lto_dir="$LOS_ARM64_DIR/lib"
}

_proton_gcc_options() {
  TC_OPTIONS=("${PROTON_GCC_OPTIONS[@]}")
  _check_linker "${1}/$PROTON_CHECK" "${1}/$EVA_ARM64_CHECK"
  local eva_path eva_v pt_v
  eva_path="${EVA_ARM64_DIR}/bin:${EVA_ARM_DIR}/bin"
  export PATH="${PROTON_DIR}/bin:${eva_path}:${PATH}"
  _check_tc_path "$PROTON_DIR" "$EVA_ARM64_DIR" "$EVA_ARM_DIR"
  _get_tc_version "$PROTON_VERSION"; pt_v="$tc_version"
  _get_tc_version "$EVA_ARM64_VERSION"; eva_v="$tc_version"
  TCVER="${pt_v##*/}/${eva_v##*/}"
  lto_dir="$PROTON_DIR/lib"
}

_neutron_gcc_options() {
  TC_OPTIONS=("${NEUTRON_GCC_OPTIONS[@]}")
  _check_linker "${1}/$NEUTRON_CHECK" "${1}/$EVA_ARM64_CHECK"
  local eva_path eva_v nt_v
  eva_path="${EVA_ARM64_DIR}/bin:${EVA_ARM_DIR}/bin"
  export PATH="${NEUTRON_DIR}/bin:${eva_path}:${PATH}"
  _check_tc_path "$NEUTRON_DIR" "$EVA_ARM64_DIR" "$EVA_ARM_DIR"
  _get_tc_version "$NEUTRON_VERSION"; nt_v="$tc_version"
  _get_tc_version "$EVA_ARM64_VERSION"; eva_v="$tc_version"
  TCVER="${nt_v##*/}/${eva_v##*/}"
  lto_dir="$NEUTRON_DIR/lib"
}

_host_clang_options() {
  TC_OPTIONS=("${HOST_CLANG_OPTIONS[@]}")
  _get_tc_version "$HOST_CLANG_NAME"
  TCVER="$tc_version"
}

_export_path_and_options() {
  # Set compiler options
  # 1. export target variables (CFG)
  # 2. define PLATFORM_VERSION & ANDROID_MAJOR_VERSION
  # 3. ensure compiler is system supported (verify linker)
  # 4. append toolchains to the $PATH, export and verify
  # 5. get the toolchain compiler version
  # 6. set Link Time Optimization (LTO)
  # 7. set additional Clang/LLVM flags
  # 8. CLANG: CROSS_COMPILE_ARM32 -> CROSS_COMPILE_COMPAT (> v4.2)
  # 9. adds CONFIG_DEBUG_SECTION_MISMATCH=y in DEBUG Mode
  # ?  DEBUG MODE: display compiler, options and PATH
  # Return: PATH TC_OPTIONS TCVER
  [[ $BUILDER == default ]] && BUILDER="$(whoami)"
  [[ $HOST == default ]] && HOST="$(uname -n)"
  export KBUILD_BUILD_USER="${BUILDER}"
  export KBUILD_BUILD_HOST="${HOST}"
  _get_android_platform_version
  if [[ $IGNORE_MAKEFILE == "True" ]] || [[ -z $amv ]]; then
    export ANDROID_MAJOR_VERSION
  elif [[ -n $amv ]]; then
    ANDROID_MAJOR_VERSION="$amv"
  fi
  if [[ $IGNORE_MAKEFILE == "True" ]] || [[ -z $ptv ]]; then
    export PLATFORM_VERSION
  elif [[ -n $ptv ]]; then
    PLATFORM_VERSION="$ptv"
  fi
  local tcpath; tcpath="${DIR}/toolchains"
  case $COMPILER in
    "$NEUTRON_CLANG_NAME") _neutron_clang_options "$tcpath" ;;
    "$PROTON_CLANG_NAME") _proton_clang_options "$tcpath" ;;
    "$AOSP_CLANG_NAME") _aosp_clang_options "$tcpath" ;;
    "$EVA_GCC_NAME") _eva_gcc_options "$tcpath" ;;
    "$LOS_GCC_NAME") _los_gcc_options "$tcpath" ;;
    "$NEUTRON_GCC_NAME") _neutron_gcc_options "$tcpath" ;;
    "$PROTON_GCC_NAME") _proton_gcc_options "$tcpath" ;;
    "$HOST_CLANG_NAME") _host_clang_options ;;
  esac
  if [[ $LTO == True ]]; then
    export LD_LIBRARY_PATH="$lto_dir"
    TC_OPTIONS[7]="LD=$LTO_LIBRARY"
  fi
  [[ $LLVM_FLAGS == True ]] && export LLVM LLVM_IAS
  local linuxversion; linuxversion="${LINUX_VERSION//.}"
  if [[ ${linuxversion:0:2} -gt 42 ]] \
      && [[ ${TC_OPTIONS[3]} == clang ]]; then
    TC_OPTIONS[2]="${TC_OPTIONS[2]/_ARM32=/_COMPAT=}"
  fi
  [[ $MAKE_CMD_ARGS != True ]] && TC_OPTIONS=("${TC_OPTIONS[0]}")
  if [[ $DEBUG == True ]]; then
    TC_OPTIONS=(CONFIG_DEBUG_SECTION_MISMATCH=y "${TC_OPTIONS[@]}")
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

_check_linker() {
  # Ensure compiler is system supported
  # ARG: $@ = toolchain check (from settings.cfg)
  if [[ $HOST_LINKER == True ]]; then
    local r; r="^\s*\[\w{1,}\s\w{1,}\s\w{1,}:\s|\[*\\w{1,}:\s"
    for linker in "$@"; do
      linker="$(readelf --program-headers "$linker" \
        | grep -m 1 -E "${r}" | awk -F ": " '{print $NF}')"
      linker="${linker/]}"
      if ! [[ -f $linker ]]; then
        _error warn "$MSG_WARN_LINKER ${red}${linker}$nc"
        _error "$MSG_ERR_LINKER $COMPILER"; _exit 1; break
      fi
    done
  fi
}

_check_tc_path() {
  # Ensure $PATH has been correctly set
  # ARG: $@ = toolchains DIR
  for toolchain_path in "$@"; do
    if [[ $PATH != *${toolchain_path}/bin* ]]; then
      _error "$MSG_ERR_PATH"; echo "$PATH"; _exit 1
    fi
  done
}

_get_android_platform_version() {
  # Get PLATFORM_VERSION from Makefile
  # Return: amv ptv
  amv="$(grep -m 1 ANDROID_MAJOR_VERSION= "${KERNEL_DIR}/Makefile")"
  ptv="$(grep -m 1 PLATFORM_VERSION= "${KERNEL_DIR}/Makefile")"
  amv="${amv/ANDROID_MAJOR_VERSION=}"
  ptv="${ptv/PLATFORM_VERSION=}"
}

_get_and_display_cross_compile() {
  # Get CROSS_COMPILE and CC from Makefile
  # Return: r1 r2 tc_cross
  local tc_cc c1 c2
  tc_cc="${TC_OPTIONS[3]/CC=}"
  tc_cross="${TC_OPTIONS[1]/CROSS_COMPILE=}"
  r1=("^CROSS_COMPILE\s.*?=.*" "CROSS_COMPILE\ ?=\ ${tc_cross}")
  r2=("^CC\s.*=.*" "CC\ =\ ${tc_cc}\ -I${KERNEL_DIR}")
  c1="$(sed -n "/${r1[0]}/{p;}" "${KERNEL_DIR}/Makefile")"
  c2="$(sed -n "/${r2[0]}/{p;}" "${KERNEL_DIR}/Makefile")"
  if [[ -z $c1 ]]; then
    _error "$MSG_ERR_CC"; _exit 1
  else
    echo "$c1"; echo "$c2"
  fi
}

_handle_makefile_cross_compile() {
  # Handle Makefile CROSS_COMPILE and CC
  # 1. display them on TERM so user can check before
  # 2. ask to modify them in the kernel Makefile
  # 3. edit the kernel Makefile (SED) while True
  # 4. warn the user while they not seems correctly set
  # ?  DEBUG MODE: display edited Makefile values
  _note "$MSG_NOTE_CC"
  _get_and_display_cross_compile
  _ask_for_edit_cross_compile
  if [[ $EDIT_CC != False ]]; then
    _check sed -i "s|${r1[0]}|${r1[1]}|g" "${KERNEL_DIR}/Makefile"
    _check sed -i "s|${r2[0]}|${r2[1]}|g" "${KERNEL_DIR}/Makefile"
  fi
  local mk; mk="$(grep -m 1 "${r1[0]}" "${KERNEL_DIR}/Makefile")"
  [[ -n ${mk##*"${tc_cross/CROSS_COMPILE=/}"*} ]] &&
    _error warn "$MSG_WARN_CC"
  if [[ $DEBUG == True ]] && [[ $EDIT_CC != False ]]; then
    echo -e "\n${blue}${MSG_DEBUG_CC}:$nc" >&2
    _get_and_display_cross_compile; sleep 0.5
  fi
}

_make_clean() {
  _note "$MSG_NOTE_MAKE_CLEAN [${LINUX_VERSION}]..."
  _check unbuffer make -C "$KERNEL_DIR" clean 2>&1
}

_make_mrproper() {
  _note "$MSG_NOTE_MRPROPER [${LINUX_VERSION}]..."
  _check unbuffer make -C "$KERNEL_DIR" mrproper 2>&1
}

_make_defconfig() {
  _note "$MSG_NOTE_DEFCONFIG $DEFCONFIG [${LINUX_VERSION}]..."
  _check unbuffer make -C "$KERNEL_DIR" \
    O="$OUT_DIR" ARCH="$ARCH" "$DEFCONFIG" 2>&1
}

_make_menuconfig() {
  _note "$MSG_NOTE_MENUCONFIG $DEFCONFIG [${LINUX_VERSION}]..."
  make -C "$KERNEL_DIR" O="$OUT_DIR" \
    ARCH="$ARCH" "$MENUCONFIG" "${OUT_DIR}/.config"
}

_save_defconfig() {
  # Save defconfig from menuconfig
  # When an existing defconfig file is modified with menuconfig
  # the original defconfig will be saved as "example_defconfig_old"
  _note "$MSG_NOTE_SAVE $DEFCONFIG (arch/${ARCH}/configs)..."
  [[ -f "${CONF_DIR}/$DEFCONFIG" ]] &&
    _check cp "${CONF_DIR}/$DEFCONFIG" \
              "${CONF_DIR}/${DEFCONFIG}_old"
  _check cp "${OUT_DIR}/.config" "${CONF_DIR}/$DEFCONFIG"
}

_make_build() {
  # 1. set Telegram HTML message
  # 2. send build status on Telegram
  # 3. make new android kernel build
  _note "${MSG_NOTE_MAKE}: ${KERNEL_NAME}..."
  _set_html_status_msg
  _send_start_build_status
  _check unbuffer make -C "$KERNEL_DIR" -j"$CORES" \
    O="$OUT_DIR" ARCH="$ARCH" "${TC_OPTIONS[*]}" 2>&1
}


###---------------------------------------------------------------###
###    8. ZIP => everything related to the signed zip creation    ###
###---------------------------------------------------------------###

_zip() {
  # Flashable zip creation
  # ARG $1 = kernel name
  # ARG $2 = kernel image
  # ARG $3 = build folder
  # 1. send status on Telegram
  # 2. copy image to AK3 folder
  # 3. CD into AK3 folder
  # 4. set AK3 configuration
  # 5. create flashable ZIP
  # 6. move the ZIP into builds folder
  [[ $start_time ]] && _clean_anykernel
  _note "$MSG_NOTE_ZIP ${1}.zip..."
  _send_zip_creation_status
  _check cp "$2" "$ANYKERNEL_DIR"
  [[ $AK3_BANNER == True ]] &&
    _check cp "${DIR}/$AK3_BANNER_FILE" "${ANYKERNEL_DIR}/banner"
  _cd "$ANYKERNEL_DIR" "$MSG_ERR_DIR ${red}${ANYKERNEL_DIR}"
  [[ $start_time ]] && _set_ak3_conf
  _check unbuffer zip -r9 "${1}.zip" \
    ./* -x .git README.md ./*placeholder 2>&1
  [[ ! -d $3 ]] && _check mkdir "$3"
  _check mv "${1}.zip" "$3"
  _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
  _clean_anykernel
}

_set_ak3_conf() {
  # Anykernel configuration
  # NOTE: we are working here from AK3 folder
  # 1. copy included files into AK3 (in their dedicated folder)
  # 2. edit anykernel.sh to append device infos (SED)
  for file in "${INCLUDED[@]}"; do
    if [[ -f ${BOOT_DIR}/$file ]]; then
      local inc_dir
      if [[ ${file##*/} == *erofs.dtb ]]; then
        _check mkdir erofs; inc_dir="erofs/"
      elif [[ ${file##*/} != *Image* ]] \
          && [[ ${file##*/} != *erofs.dtb ]] \
          && [[ ${file##*/} == *.dtb ]]; then
        _check mkdir dtb; inc_dir="dtb/";
      else
        inc_dir=""
      fi
      _check cp -af "${BOOT_DIR}/$file" "${inc_dir}${file##*/}"
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

_clean_anykernel() {
  _note "${MSG_NOTE_CLEAN_AK3}..."
  for file in "${INCLUDED[@]}"; do
    [[ -f ${ANYKERNEL_DIR}/$file ]] &&
      _check rm -rf "${ANYKERNEL_DIR}/${file}"
  done
  for file in "${ANYKERNEL_DIR}"/*; do
    case $file in
      *.zip*|*Image*|*erofs*|*dtb*|*spectrum.rc*)
        _check rm -rf "${file}" ;;
    esac
  done
}

_sign_zip() {
  # Sign ZIP with AOSP Keys
  # ARG $1 = kernel name
  # 1. send signing status on Telegram
  # 2. sign ZIP with AOSP Keys (JAVA)
  if which java &>/dev/null; then
    _note "${MSG_NOTE_SIGN}..."
    _send_zip_signing_status
    _check unbuffer java -jar "${DIR}/bin/zipsigner-3.0-dexed.jar" \
      "${1}.zip" "${1}-signed.zip" 2>&1
  else
    _error warn "$MSG_WARN_JAVA"
  fi
}


###---------------------------------------------------------------###
###    9. TELEGRAM => building status Telegram feedback (POST)    ###
###---------------------------------------------------------------###

# Telegram API
#--------------

_send_msg() {
  # ARG $1 = message
  curl --progress-bar -o /dev/null -fL -X POST -d text="$1" \
    -d parse_mode=html -d chat_id="$TELEGRAM_CHAT_ID" \
    "${TELEGRAM_API}/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
}

_send_file() {
  # ARG $1 = file
  # ARG $2 = caption
  local tg sendtype extension
  extension=${1##*/*.}
  if [[ ${#extension} -lt 3 ]] \
    && [[ $extension != ai ]]; then tg="sendDocument"
  elif [[ ${PHOTO_F} =~ ${extension} ]]; then tg="sendPhoto"
  elif [[ ${AUDIO_F} =~ ${extension} ]]; then tg="sendAudio"
  elif [[ ${VIDEO_F} =~ ${extension} ]]; then tg="sendVideo"
  elif [[ ${ANIM_F} =~ ${extension} ]]; then tg="sendAnimation"
  elif [[ ${VOICE_F} =~ ${extension} ]]; then tg="sendVoice"
  else tg="sendDocument"
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

_send_start_build_status() {
  [[ $build_status == True ]] && _send_msg "${status_msg//_/-}"
}

_send_success_build_status() {
  if [[ $build_status == True ]]; then
    local msg
    msg="$MSG_NOTE_SUCCESS $BUILD_TIME | ${compiler//_/-}"
    _send_msg "${KERNEL_NAME//_/-} | $msg"
  fi
}

_send_zip_creation_status() {
  [[ $build_status == True ]] &&
    _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_ZIP [AK3]"
}

_send_zip_signing_status() {
  [[ $build_status == True ]] &&
    _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_SIGN [JAVA]"
}

_send_failed_build_logs() {
  if [[ $start_time ]] && [[ $build_status == True ]] \
      && { ! [[ $BUILD_TIME ]] || [[ $run_again == True ]]; }; then
    _get_build_time
    _send_file "$log" \
      "v${LINUX_VERSION//_/-} | $MSG_TG_FAILED $BUILD_TIME"
  fi
}

_upload_kernel_build() {
  if [[ $build_status == True ]] && [[ $flash_zip == True ]]; then
    local file caption
    file="${BUILD_DIR}/${KERNEL_NAME}-${DATE}-signed.zip"
    [[ ! -f $file ]] && file="${file/-signed}"
    _note "${MSG_NOTE_UPLOAD}: ${file##*/}..."
    MD5="$(md5sum "$file" | cut -d' ' -f1)"
    caption="${MSG_TG_CAPTION}: $BUILD_TIME"
    _send_file "$file" "$caption | MD5 Checksum: ${MD5//_/-}"
  fi
}

_set_html_status_msg() {
  local android_version; android_version="AOSP $PLATFORM_VERSION"
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


###---------------------------------------------------------------###
###        10. Run the ZenMaxBuilder (ZMB) main process...        ###
###---------------------------------------------------------------###
_zenmaxbuilder "$@"


# THANKS FOR READING !
# ZMB by darkmaster @grm34
# -------------------------

