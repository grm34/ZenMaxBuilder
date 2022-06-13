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
#  0. ==>              starting blocks                          (RUN)
# 01. MAIN..........:  zmb main processus                      (FUNC)
# 02. MANAGER.......:  global management of the script         (FUNC)
# 03. COLLECTER.....:  functions to grab something             (FUNC)
# 04. CONTROLLER....:  functions to check something            (FUNC)
# 05. STARTER.......:  starts a new kernel compilation         (FUNC)
# 06. TOOLCHAINER...:  functions for the toolchains setting    (FUNC)
# 07. MAKER.........:  exports settings and runs make          (FUNC)
# 08. PACKER........:  functions for the zip creation          (FUNC)
# 09. QUESTIONER....:  questions asked to the user             (FUNC)
# 10. TELEGRAMER....:  kernel building feedback                (FUNC)
# 11. VERSIONER.....:  displays the toolchains versions        (FUNC)
# 12. READER........:  displays the compiled kernels           (FUNC)
# 13. PATCHER.......:  patchs/reverts patches to a kernel      (FUNC)
# 14. INSTALLER.....:  dependency install management           (FUNC)
# 15. UPDATER.......:  updates the script and toolchains       (FUNC)
# 16. HELPER........:  displays zmb help and usage             (FUNC)
# 00. ==>              runs zmb main processus                  (RUN)
# -------------------------------------------------------------------

# [!] Code Style, Naming Convention...
# -------------------------------------------------------------------
# - Line length: max 78
# - Variable: uppercase only while needs to be exported or logged
# - Function: always lowercase and starts with an underscore
# - Condition: always use the power of the double brackets
# - Command: prefer the use of _check() function to handle ERR
# - Exit: always use _exit() function to rm temp files and get logs
# - Language: see Contributing Guidelines...
# -------------------------------------------------------------------

# ensures proper use
if ! [[ $(uname -s) =~ ^(Linux|GNU*)$ ]]; then
  echo "ERROR: run ZenMaxBuilder on Linux" >&2
  exit 1
elif ! [[ -t 0 ]]; then
  echo "ERROR: run ZenMaxBuilder from a terminal" >&2
  exit 1
elif [[ $(tput cols) -lt 80 ]] || [[ $(tput lines) -lt 12 ]]; then
  echo "ERROR: terminal window is too small (min 80x12)" >&2
  exit 68
elif [[ $(whoami) == root ]]; then
  echo "ERROR: do not run ZenMaxBuilder as root" >&2
  exit 1
elif [[ ${BASH_SOURCE[0]} != "$0" ]]; then
  echo "ERROR: ZenMaxBuilder cannot be sourced" >&2
  return 1
fi

# absolute path
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
if ! cd "$DIR" || ! [[ -f ${DIR}/etc/settings.cfg ]]; then
  echo "ERROR: ZenMaxBuilder directory not found" >&2
  exit 2
fi

# lockfile
exec 201> "$(basename "$0").lock"
if ! flock -n 201; then
  echo "ERROR: ZenMaxBuilder is already running" >&2
  exit 114
fi

# shell settings
shopt -s checkwinsize progcomp
shopt -u autocd cdspell dirspell extglob progcomp_alias

# job control
set -m -o pipefail

# user configuration
# shellcheck source=/dev/null
if [[ -f ${DIR}/etc/user.cfg ]]; then
  source "${DIR}/etc/user.cfg"
else
  source "${DIR}/etc/settings.cfg"
fi

# user language
# shellcheck source=/dev/null
if [[ -f "${DIR}/lang/${LANGUAGE}.cfg" ]]; then
  source "${DIR}/lang/${LANGUAGE}.cfg"
elif [[ -f "${DIR}/lang/${LANG:0:2}.cfg" ]]; then
  source "${DIR}/lang/${LANG:0:2}.cfg"
else
  source "${DIR}/lang/en.cfg" 2>/dev/null \
    || echo "ERROR: language not found" >&2; exit 2
fi


###---------------------------------------------------------------###
###         01. MAIN => zmb main process (ZenMaxBuilder)          ###
###---------------------------------------------------------------###

_zenmaxbuilder() {
  # main processus
  # > defines shell colors
  # > traps interrupt signals
  # > grabs shell variables (bashvar)
  # > defines date and time
  # > transforms long options to short
  # > handles general options
  # returns => $zmb_option $DEBUG
  _terminal_colors
  trap '_error $MSG_ERR_KBOARD; _exit 1' INT QUIT TSTP CONT HUP
  set > "${DIR}/bashvar"
  [[ $TIMEZONE == default ]] && _get_user_timezone
  DATE="$(TZ=$TIMEZONE date +%Y-%m-%d)"
  TIME="$(TZ=$TIMEZONE date +%Hh%Mm%Ss)"
  local option
  for option in "$@"; do
    shift
    case $option in
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
      *)           set -- "$@" "$option" ;;
    esac
  done
  if [[ $# -eq 0 ]]; then _error "$MSG_ERR_EOPT"; _exit 1; fi
  while getopts ':hsuvldprt:m:f:z:' zmb_option; do
    case $zmb_option in
      h)  clear; _terminal_banner; _usage; _exit 0 ;;
      u)  _install_dep; _full_upgrade; _exit 0 ;;
      v)  _install_dep; _tc_version_option; _exit 0 ;;
      m)  _install_dep; _send_msg_option; _exit 0 ;;
      f)  _install_dep; _send_file_option; _exit 0 ;;
      z)  _install_dep; _create_zip_option; _exit 0 ;;
      l)  _install_dep; _list_all_kernels; _exit 0 ;;
      t)  _install_dep; _get_latest_linux_tag; _exit 0 ;;
      p)  _install_dep; _patch patch; _exit 0 ;;
      r)  _install_dep; _patch revert; _exit 0 ;;
      s)  _install_dep; _start; _exit 0 ;;
      d)  DEBUG="True"; _install_dep; _start; _exit 0 ;;
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
###        02. MANAGER => global management of the script         ###
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
  # uses colors only while they are terminal supported
  # returns => some colorized variables
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
      lblue="$(tput setaf 4)"
      magenta="$(tput setaf 5)"
      cyan="$(tput bold setaf 6)"
    fi
  fi
}

_cd() {
  # $1 = the location to go
  # $2 = the error message
  cd "$1" || (_error "$2"; _exit 1)
}

_prompt() {
  # asks some information (question or selection)
  # $1 = the question to ask
  # $2 = number (1 for question and 2 for selection)
  local length; length="$*"; length="$(( ${#length} - 2 ))"
  echo -ne "\n${yellow}==> ${green}${1}$nc"
  _underline_prompt; [[ $2 == 1 ]] &&
    echo -ne "${yellow}\n==> $nc" || echo -ne "\n$nc"
}

_confirm() {
  # asks confirmation (yes/no)
  # $1 = the question to ask
  # $2 = [Y/n] (to set default <ENTER> behavior)
  # returns => $confirm
  local length; length="$*"; length="${#length}"
  echo -ne "${yellow}\n==> ${green}${1} ${red}${2}$nc"
  _underline_prompt; confirm="False"
  echo -ne "${yellow}\n==> $nc"
  read -r confirm
  until [[ $confirm =~ ^(y|n|Y|N|yes|no|Yes|No|YES|NO)$ ]] \
      || [[ -z $confirm ]]; do
    _error "$MSG_ERR_CONFIRM"
    _confirm "$@"
  done
}

_underline_prompt() {
  # underlines only while the terminal window is large
  # enough to display the prompt on a single line
  if [[ $(tput cols) -gt $length ]]; then
    local char; echo -ne "${yellow}\n==> "
    for (( char=1; char<=length; char++ )); do
      echo -ne "─"
    done
  fi
}

_note() {
  # displays some notes (with timestamp)
  # $1 = the note to display
  echo -e "${yellow}\n[$(TZ=$TIMEZONE date +%T)] ${cyan}${1}$nc"
  sleep 1
}

_error() {
  # displays warning or error
  # $1 = <warn> for warning (ignore $1 for error)
  # $* = the error or warning message
  if [[ $1 == warn ]]; then
    echo -e "\n${blue}${MSG_WARN}${nc}${lyellow}${*/warn/}$nc" >&2
  else
    echo -e "\n${red}$MSG_ERROR ${nc}${lyellow}${*}$nc" >&2
  fi
}

_check() {
  # handles shell command
  # $@ = the command to run
  # DEBUG MODE: displays the command
  # runs the command as child and waits
  # notifies function and file on ERR
  # grabs logs on command error
  # asks to run again last failed command
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
           "${red}${MSG_ERR_FROM}"\
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
  # $1 = exit code
  # kills running PID childs on interrupt
  # grabs the logs (if the build started)
  # removes temp files and device folders
  # exits with 3s timeout
  local pid pids file files folder folders second
  if [[ $1 != 0 ]]; then
    pids=(make git wget tar readelf zip \
      java apt pkg pacman yum emerge zypper dnf)
    for pid in "${pids[@]}"; do
      if pidof "$pid"; then pkill "$pid" || sleep 0.5; fi
    done
  fi
  _get_build_logs
  files=(bashvar buildervar linuxver wget-log \
    "${AOSP_CLANG_DIR##*/}.tar.gz" "${LLVM_ARM_DIR##*/}.gz"
    "${LLVM_ARM64_DIR##*/}.tar.gz")
  for file in "${files[@]}"; do
    [[ -f $file ]] && _check rm -f "${DIR}/$file"
  done
  folders=(out builds logs)
  for folder in "${folders[@]}"; do
    if [[ -z $(find "${DIR}/${folder}/$CODENAME" \
        -mindepth 1 -maxdepth 1 2>/dev/null) ]]; then
      _check rm -rf "${DIR}/${folder}/$CODENAME"
    fi
  done
  case $zmb_option in
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


###---------------------------------------------------------------###
###         03. COLLECTER => functions to grab something          ###
###---------------------------------------------------------------###

_get_user_timezone() {
  # linux: uses <timedatectl>
  # termux: uses <getprop>
  # returns => $TIMEZONE
  if which timedatectl &>/dev/null; then
    TIMEZONE="$(timedatectl | grep -sm 1 'Time zone' \
      | awk -F" " '{print $3}')"
  elif which getprop &>/dev/null; then
    local tz
    tz="$(getprop | grep -sm 1 timezone | awk -F": " '{print $2}')"
    tz=${tz/\[}; TIMEZONE=${tz/\]}
  fi
}

_get_build_time() {
  # returns => $BUILD_TIME
  local end_time diff_time min sec
  end_time="$(TZ=$TIMEZONE date +%s)"
  diff_time="$(( end_time - start_time ))"
  min="$(( diff_time / 60 ))"; sec="$(( diff_time % 60 ))"
  BUILD_TIME="${min}m${sec}s"
}

_get_build_logs() {
  # grabs builder vars (without EXCLUDED_VARS)
  # diffs bash/builder vars and adds the output
  # removes ANSI sequences (color codes)
  # sends logfile on telegram (while the build fail)
  if [[ -f $log ]] \
      && ! grep -sqm 1 "### ZMB SETTINGS ###" "$log"; then
    local excluded EXCLUDED_VARS
    # shellcheck source=/dev/null
    source "${DIR}/etc/excluded.cfg"
    excluded="$(IFS=$'|'; echo "${EXCLUDED_VARS[*]}")"; unset IFS
    set | grep -v "${excluded//|/\\|}" > "${DIR}/buildervar"
    printf "\n\n### ZMB SETTINGS ###\n" >> "$log"
    diff "${DIR}/bashvar" "${DIR}/buildervar" \
      | grep -E "^> [A-Z0-9_]{3,32}=" >> "$log" || sleep 0.5
    sed -ri "s/\x1b\[[0-9;]*[mGKHF]//g" "$log"
    _send_failed_build_logs
  fi
}

_get_latest_aosp_tag() {
  # $1 = toolchain url (from settings.cfg)
  # $2 = toolchain folder (from settings.cfg)
  # returns => $latest $tgz
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

_get_local_aosp_tag() {
  # $1 = toolchain folder (from settings.cfg)
  # $2 = toolchain version (from settings.cfg)
  # returns => $tag
  local regex
  case ${1##*/} in
    "${AOSP_CLANG_DIR##*/}") regex="r\d+[a-z]{1}" ;;
    "${LLVM_ARM64_DIR##*/}"|"${LLVM_ARM_DIR##*/}")
      regex="llvm-r\d+[a-z]{0,1}" ;;
  esac
  tag=$(grep -oP "${regex}" "${DIR}/toolchains/$2")
}

_get_tc_version() {
  # $1 = toolchain version (from settings.cfg)
  # returns => $tc_version
  case $1 in
    "$AOSP_CLANG_VERSION"|"$LLVM_ARM64_VERSION"|\
    "$LLVM_ARM_VERSION")
      tc_version="$(head -n 1 "${DIR}/toolchains/$1")"
      ;;
    "$HOST_CLANG_NAME")
      tc_version="$(clang --version | grep -m 1 "clang\|version" \
        | awk -F" " '{print $NF}')"
      ;;
    *)
      tc_version="$(find "${DIR}/toolchains/$1" \
        -mindepth 1 -maxdepth 1 -type d | head -n 1)"
      ;;
  esac
}

_get_android_platform_version() {
  # grabs PLATFORM_VERSION from the kernel Makefile
  # returns => $amv $ptv
  amv="$(grep -m 1 ANDROID_MAJOR_VERSION= "${KERNEL_DIR}/Makefile")"
  ptv="$(grep -m 1 PLATFORM_VERSION= "${KERNEL_DIR}/Makefile")"
  amv="${amv/ANDROID_MAJOR_VERSION=}"
  ptv="${ptv/PLATFORM_VERSION=}"
}

_get_cross_compile() {
  # grabs CROSS_COMPILE and CC from the kernel Makefile
  # displays the outputs found on the terminal
  ! [[ $1 ]] && _note "$MSG_NOTE_CC"
  local cross cc
  cross="$(sed -n "/^CROSS_COMPILE\s.*?=.*/{p;}" \
    "${KERNEL_DIR}/Makefile")"
  cc="$(sed -n "/^CC\s.*=.*/{p;}" "${KERNEL_DIR}/Makefile")"
  if [[ -z $cross ]] || [[ -z $cc ]]; then
    _error "$MSG_ERR_CC"; _exit 1
  else
    echo "$cross"; echo "$cc"
  fi
}

_get_latest_linux_tag() {
  # displays the latest linux tag
  # $1 = tag number to scan (e.g. v4)
  _note "$MSG_NOTE_LTAG"
  [[ $OPTARG != v* ]] && OPTARG="v$OPTARG"
  local ltag; ltag="$(git ls-remote --refs --sort='v:refname' \
    --tags "$LINUX_STABLE" | grep "$OPTARG" | tail --lines=1 \
    | cut --delimiter='/' --fields=3)"
  if [[ $ltag == ${OPTARG}* ]]; then
    _note "$MSG_NOTE_SUCCESS_LTAG ${red}$ltag"
  else
    _error "$MSG_ERR_LTAG ${red}$OPTARG"
  fi
}

_get_realpath_working_folders() {
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
}


###---------------------------------------------------------------###
###        04. CONTROLLER => functions to check something         ###
###---------------------------------------------------------------###

_check_user_settings() {
  # kernel dir: checks the presence of <configs> folder
  # compiler: checks for a valid compiler name
  if [[ $KERNEL_DIR != default ]] \
      && ! [[ -f ${KERNEL_DIR}/Makefile ]] \
      && ! [[ -d ${KERNEL_DIR}/arch/${ARCH}/configs ]]; then
    _error "$MSG_ERR_CONF_KDIR"; _exit 1
  elif ! [[ $COMPILER =~ ^(default|${PROTON_GCC_NAME}|\
      ${PROTON_CLANG_NAME}|${EVA_GCC_NAME}|${HOST_CLANG_NAME}|\
      ${LOS_GCC_NAME}|${AOSP_CLANG_NAME}|${NEUTRON_GCC_NAME}\
      ${NEUTRON_CLANG_NAME})$ ]]; then
    _error "$MSG_ERR_COMPILER"; _exit 1
  fi
}

_check_linker() {
  # ensures the compiler is system supported
  # $@ = some toolchain *_CHECK (from settings.cfg)
  if [[ $HOST_LINKER == True ]]; then
    local regex linker
    regex="^\s*\[\w{1,}\s\w{1,}\s\w{1,}:\s|\[*\\w{1,}:\s"
    for linker in "$@"; do
      linker="$(readelf --program-headers "$linker" \
        | grep -m 1 -E "${regex}" | awk -F": " '{print $NF}')"
      linker="${linker/]}"
      if ! [[ -f $linker ]]; then
        _error warn "$MSG_WARN_LINKER ${red}${linker}$nc"
        _error "$MSG_ERR_LINKER $COMPILER"; _exit 1; break
      fi
    done
  fi
}

_check_tc_path() {
  # ensures $PATH has been correctly set
  # $@ = some toolchain paths
  local toolchain_path
  for toolchain_path in "$@"; do
    if [[ $PATH != *${toolchain_path}/bin* ]]; then
      _error "$MSG_ERR_PATH"; echo "$PATH"; _exit 1
    fi
  done
}

_check_makefile() {
  # checks CROSS_COMPILE and CC
  # warns the user while they not seems correctly set
  # asks to modify them in the kernel Makefile
  # edits the kernel Makefile (SED) while True
  # DEBUG MODE: displays edited Makefile values
  local cross cc r1 r2 check1 check2
  cross="${TC_OPTIONS[1]/CROSS_COMPILE=}"
  cc="${TC_OPTIONS[3]/CC=}"
  r1=("^CROSS_COMPILE\s.*?=.*" "CROSS_COMPILE\ ?=\ ${cross}")
  r2=("^CC\s.*=.*" "CC\ =\ ${cc}\ -I${KERNEL_DIR}")
  check1="$(grep -m 1 "${r1[0]}" "${KERNEL_DIR}/Makefile")"
  check2="$(grep -m 1 "${r2[0]}" "${KERNEL_DIR}/Makefile")"
  if [[ -n ${check1##*"${cross}"*} ]] \
      || [[ -n ${check2##*"${cc}"*} ]]; then
    _error warn "$MSG_WARN_CC"
    _ask_for_edit_cross_compile
    if [[ $EDIT_CC != False ]]; then
      _check sed -i "s|${r1[0]}|${r1[1]}|g" "${KERNEL_DIR}/Makefile"
      _check sed -i "s|${r2[0]}|${r2[1]}|g" "${KERNEL_DIR}/Makefile"
      if [[ $DEBUG == True ]]; then
        echo -e "\n${blue}${MSG_DEBUG_CC}$nc" >&2
        _get_cross_compile 1; sleep 0.5
      fi
    fi
  fi
}


###---------------------------------------------------------------###
###        05. STARTER => starts a new kernel compilation         ###
###---------------------------------------------------------------###

_start() {
  local folder folders ftime gen

  # displays banner
  _check_user_settings
  clear; _terminal_banner
  _note "$MSG_NOTE_START $DATE"
  [[ $termux ]] && _error warn "$MSG_WARN_TERMUX"

  # grabs device codename and creates folders
  _ask_for_codename
  folders=(builds logs toolchains out)
  for folder in "${folders[@]}"; do
    if ! [[ -d ${DIR}/${folder}/$CODENAME ]] \
        && [[ $folder != toolchains ]]; then
      _check mkdir -p "${DIR}/${folder}/$CODENAME"
    elif ! [[ -d ${DIR}/$folder ]]; then
      _check mkdir "${DIR}/$folder"
    fi
  done
  _get_realpath_working_folders

   # asks questions to the user and exports settings
  _ask_for_kernel_dir
  _ask_for_defconfig
  _ask_for_menuconfig 
  _get_cross_compile
  _ask_for_edit_makefile
  _ask_for_toolchain
  _clone_toolchains
  _export_path_and_options
  _ask_for_cores

  # makes kernel version
  _note "$MSG_NOTE_LINUXVER"
  make -C "$KERNEL_DIR" kernelversion \
    | grep -v make > linuxver & wait $!
  LINUX_VERSION="$(head -n 1 linuxver)"
  if [[ -z $LINUX_VERSION ]]; then
    _error "$MSG_ERR_LINUXVER"; _exit 1
  fi
  KERNEL_NAME="${TAG}-${CODENAME}-$LINUX_VERSION"

  # makes clean
  _ask_for_make_clean
  if [[ $MAKE_CLEAN == True ]]; then
    _make_clean; _make_mrproper; rm -rf "$OUT_DIR"
  fi

  # makes configuration
  _make_defconfig
  if [[ $MENUCONFIG ]]; then
    _make_menuconfig
    _ask_for_save_defconfig
    if [[ $save_defconfig != False ]]; then
      _save_defconfig
    elif [[ $original_defconfig == False ]]; then
      _note "$MSG_NOTE_CANCEL ${KERNEL_NAME}..."; _exit 0
    fi
  fi

  # makes the kernel
  _ask_for_new_build
  if [[ $new_build == False ]]; then
    _note "$MSG_NOTE_CANCEL ${KERNEL_NAME}..."; _exit 0
  else
    _ask_for_telegram
    start_time="$(TZ=$TIMEZONE date +%s)"
    log="${DIR}/logs/${CODENAME}/${KERNEL_NAME}_${DATE}_${TIME}.log"
    _terminal_banner > "$log"
    _make_build | tee -a "$log"
  fi

  # grabs status -> creates zip -> uploads the build
  _get_build_time
  gen="${OUT_DIR}/include/generated/compile.h"
  ftime="$(stat -c %Z "${gen}" 2>/dev/null)"
  if ! [[ -f $gen ]] || [[ $ftime -lt $start_time ]]; then
    _error "$MSG_ERR_MAKE"; _exit 1
  else
    REALCC="$(grep -m 1 LINUX_COMPILER "$gen")"
    REALCC="${REALCC/\#define }"
    _note "$MSG_NOTE_SUCCESS $BUILD_TIME !"
    _note "$REALCC"
    _send_success_build_status
    _ask_for_flashable_zip
    if [[ $flash_zip == True ]]; then
      _ask_for_kernel_image
      _zip "${KERNEL_NAME}-$DATE" "$K_IMG" \
           "$BUILD_DIR" | tee -a "$log"
      _sign_zip "${BUILD_DIR}/${KERNEL_NAME}-$DATE" | tee -a "$log"
      _note "$MSG_NOTE_ZIPPED"
    fi
    _get_build_logs
    _upload_kernel_build
  fi
}


###---------------------------------------------------------------###
###    06. TOOLCHAINER => functions for the toolchains setting    ###
###---------------------------------------------------------------###

_aosp_clang_options() {
  # $1 = toolchain realpath
  # returns => $TC_OPTIONS $PATH $TCVER $lto_dir
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
  # $1 = toolchain realpath
  # returns => $TC_OPTIONS $PATH $TCVER $lto_dir
  TC_OPTIONS=("${EVA_GCC_OPTIONS[@]}")
  _check_linker "${1}/$EVA_ARM64_CHECK"
  export PATH="${EVA_ARM64_DIR}/bin:${EVA_ARM_DIR}/bin:${PATH}"
  _check_tc_path "$EVA_ARM64_DIR" "$EVA_ARM_DIR"
  _get_tc_version "$EVA_ARM64_VERSION"
  TCVER="${tc_version##*/}"
  lto_dir="$EVA_ARM64_DIR/lib"
}

_neutron_clang_options() {
  # $1 = toolchain realpath
  # returns => $TC_OPTIONS $PATH $TCVER $lto_dir
  TC_OPTIONS=("${NEUTRON_CLANG_OPTIONS[@]}")
  _check_linker "${1}/$NEUTRON_CHECK"
  export PATH="${NEUTRON_DIR}/bin:${PATH}"
  _check_tc_path "$NEUTRON_DIR"
  _get_tc_version "$NEUTRON_VERSION"
  TCVER="${tc_version##*/}"
  lto_dir="$NEUTRON_DIR/lib"
}

_proton_clang_options() {
  # $1 = toolchain realpath
  # returns => $TC_OPTIONS $PATH $TCVER $lto_dir
  TC_OPTIONS=("${PROTON_CLANG_OPTIONS[@]}")
  _check_linker "${1}/$PROTON_CHECK"
  export PATH="${PROTON_DIR}/bin:${PATH}"
  _check_tc_path "$PROTON_DIR"
  _get_tc_version "$PROTON_VERSION"
  TCVER="${tc_version##*/}"
  lto_dir="$PROTON_DIR/lib"
}

_los_gcc_options() {
  # $1 = toolchain realpath
  # returns => $TC_OPTIONS $PATH $TCVER $lto_dir
  TC_OPTIONS=("${LOS_GCC_OPTIONS[@]}")
  _check_linker "${1}/$LOS_ARM64_CHECK"
  export PATH="${LOS_ARM64_DIR}/bin:${LOS_ARM_DIR}/bin:${PATH}"
  _check_tc_path "$LOS_ARM64_DIR" "$LOS_ARM_DIR"
  _get_tc_version "$LOS_ARM64_VERSION"
  TCVER="${tc_version##*/}"
  lto_dir="$LOS_ARM64_DIR/lib"
}

_proton_gcc_options() {
  # $1 = toolchain realpath
  # returns => $TC_OPTIONS $PATH $TCVER $lto_dir
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
  # $1 = toolchain realpath
  # returns => $TC_OPTIONS $PATH $TCVER $lto_dir
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
  # returns => $TC_OPTIONS $TCVER
  TC_OPTIONS=("${HOST_CLANG_OPTIONS[@]}")
  _get_tc_version "$HOST_CLANG_NAME"
  TCVER="$tc_version"
}


###---------------------------------------------------------------###
###          07. MAKER => exports settings and runs make          ###
###---------------------------------------------------------------###

_export_path_and_options() {
  # exports target variables (from settings.cfg)
  # defines PLATFORM_VERSION & ANDROID_MAJOR_VERSION
  # ensures compiler is system supported (checks linker)
  # appends toolchains to the $PATH, exports and checks
  # grabs the toolchain compiler version
  # checks Makefile and warns/edits while required
  # defines link time optimization (LTO)
  # defines additional clang/llvm flags
  # clang: CROSS_COMPILE_ARM32 -> CROSS_COMPILE_COMPAT (> v4.2)
  # adds CONFIG_DEBUG_SECTION_MISMATCH=y in debug mode
  # DEBUG MODE: displays compiler, options and path
  # returns => $PATH $TC_OPTIONS $TCVER
  local tcpath linuxversion option
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
  tcpath="${DIR}/toolchains"
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
  _check_makefile
  if [[ $LTO == True ]]; then
    export LD_LIBRARY_PATH="$lto_dir"
    TC_OPTIONS[7]="LD=$LTO_LIBRARY"
  fi
  [[ $LLVM_FLAGS == True ]] && export LLVM LLVM_IAS
  linuxversion="${LINUX_VERSION//.}"
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
    for option in "${TC_OPTIONS[@]}"; do
      echo -e "${lyellow}${option}$nc" >&2
    done
    echo -e "\n${blue}PATH: ${nc}${lyellow}${PATH}$nc" >&2
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
  # while an existing defconfig file is modified
  # the original will be saved as <*_defconfig_bak>
  _note "$MSG_NOTE_SAVE $DEFCONFIG (arch/${ARCH}/configs)..."
  [[ -f "${CONF_DIR}/$DEFCONFIG" ]] &&
    _check cp "${CONF_DIR}/$DEFCONFIG" \
              "${CONF_DIR}/${DEFCONFIG}_bak"
  _check cp "${OUT_DIR}/.config" "${CONF_DIR}/$DEFCONFIG"
}

_make_build() {
  # TG: defines HTML message and sends build status
  _note "$MSG_NOTE_MAKE ${KERNEL_NAME}..."
  _set_html_status_msg
  _send_start_build_status
  _check unbuffer make -C "$KERNEL_DIR" -j"$CORES" \
    O="$OUT_DIR" ARCH="$ARCH" "${TC_OPTIONS[*]}" 2>&1
}


###---------------------------------------------------------------###
###         08. PACKER => functions for the zip creation          ###
###---------------------------------------------------------------###

_zip() {
  # kernel zip creation
  # $1 = kernel name
  # $2 = kernel image
  # $3 = build folder
  # sends status on Telegram
  # copies image into <AnyKernel> folder
  # CD into <AnyKernel> folder
  # writes ak3 configuration (anykernel.sh)
  # creates new kernel zip
  # moves the zip into <builds> folder
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
  # NOTE: we are working here from <AnyKernel> folder
  # copies included files into ak3 (in their dedicated folder)
  # edits <anykernel.sh> to append device infos (SED)
  local file inc_dir string strings
  for file in "${INCLUDED[@]}"; do
    if [[ -f ${BOOT_DIR}/$file ]]; then
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

_clean_anykernel() {
  # removes unwanted files and folders
  _note "$MSG_NOTE_CLEAN_AK3"
  local file
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
  # $1 = kernel name
  # sends signing status on Telegram
  # signs the zip with aosp keys (java)
  if which java &>/dev/null; then
    _note "$MSG_NOTE_SIGN"
    _send_zip_signing_status
    _check unbuffer java -jar "${DIR}/bin/zipsigner-3.0-dexed.jar" \
      "${1}.zip" "${1}-signed.zip" 2>&1
  else
    _error warn "$MSG_WARN_JAVA"
  fi
}

_create_zip_option() {
  # $1 = kernel image
  if [[ -f $OPTARG ]]; then
    _zip "${OPTARG##*/}-${DATE}-$TIME" "$OPTARG" \
      "${DIR}/builds/default"
    _sign_zip \
      "${DIR}/builds/default/${OPTARG##*/}-${DATE}-$TIME"
    _note "$MSG_NOTE_ZIPPED"
  else
    _error "$MSG_ERR_IMG ${red}$OPTARG"
  fi
}


###---------------------------------------------------------------###
###         09. QUESTIONER => questions asked to the user         ###
###---------------------------------------------------------------###

_ask_for_codename() {
  # matchs regex to prevent invalid string
  # returns => $CODENAME
  if [[ $CODENAME == default ]]; then
    _prompt "$MSG_ASK_CODENAME" 1; read -r CODENAME
    local regex; regex="^[a-zA-Z0-9][a-zA-Z0-9_-]{2,19}$"
    until [[ $CODENAME =~ $regex ]]; do
      _error "$MSG_ERR_CODENAME ${red}$CODENAME"
      _prompt "$MSG_ASK_CODENAME" 1
      read -r CODENAME
    done
  fi
}

_ask_for_kernel_dir() {
  # NOTE: we are working here from $HOME (auto completion)
  # checks the presence of <configs> folder (ARM)
  # returns => $KERNEL_DIR $CONF_DIR
  if [[ $KERNEL_DIR == default ]]; then
    _cd "$HOME" "$MSG_ERR_DIR ${red}HOME"
    _prompt "$MSG_ASK_KDIR" 1; read -r -e KERNEL_DIR
    until [[ -d ${KERNEL_DIR}/arch/${ARCH}/configs ]]; do
      _error "$MSG_ERR_KDIR ${red}$KERNEL_DIR"
      _prompt "$MSG_ASK_KDIR" 1
      read -r -e KERNEL_DIR
    done
    KERNEL_DIR="$(realpath "$KERNEL_DIR")"
    CONF_DIR="${KERNEL_DIR}/arch/${ARCH}/configs"
    _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
  fi
}

_ask_for_defconfig() {
  # defconfig files located in <configs> (ARM)
  # returns => $DEFCONFIG
  _cd "$CONF_DIR" "$MSG_ERR_DIR ${red}$CONF_DIR"
  _prompt "$MSG_SELECT_DEF" 2
  select DEFCONFIG in *_defconfig; do
    [[ $DEFCONFIG ]] && break
    _error "$MSG_ERR_SELECT"
  done
  _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
}

_ask_for_menuconfig() {
  # returns => $MENUCONFIG
  _confirm "$MSG_CONFIRM_CONF" "[y/N]"
  if [[ $confirm =~ (y|Y|yes|Yes|YES) ]]; then
    _prompt "$MSG_SELECT_MENU" 2
    select MENUCONFIG in config menuconfig nconfig xconfig \
        gconfig oldconfig silentoldconfig allyesconfig \
        allmodconfig allnoconfig randconfig localmodconfig \
        localyesconfig; do
      [[ $MENUCONFIG ]] && break
      _error "$MSG_ERR_SELECT"
    done
  fi
}

_ask_for_save_defconfig() {
  # otherwise request to continue with the unmodified
  # matchs regex to prevent invalid string
  # returns => $DEFCONFIG
  _confirm "$MSG_CONFIRM_SAVE_DEF" "[Y/n]"
  if [[ $confirm =~ (n|N|no|No|NO) ]]; then
    save_defconfig="False"
    _confirm "$MSG_CONFIRM_USE_DEF $DEFCONFIG ?" "[Y/n]"
    [[ $confirm =~ (n|N|no|No|NO) ]] && original_defconfig="False"
  else
    _prompt "$MSG_ASK_DEF_NAME" 1; read -r DEFCONFIG
    local regex; regex="^[a-zA-Z0-9][a-zA-Z0-9_-]{2,25}$"
    until [[ $DEFCONFIG =~ $regex ]]; do
      _error "$MSG_ERR_DEF_NAME ${red}$DEFCONFIG"
      _prompt "$MSG_ASK_DEF_NAME" 1
      read -r DEFCONFIG
    done
    DEFCONFIG="${DEFCONFIG}_defconfig"
  fi
}

_ask_for_toolchain() {
  # returns => $COMPILER
  if [[ $COMPILER == default ]]; then
    _prompt "$MSG_SELECT_TC" 2
    select COMPILER in $AOSP_CLANG_NAME $EVA_GCC_NAME \
        $PROTON_CLANG_NAME $NEUTRON_CLANG_NAME $LOS_GCC_NAME \
        $PROTON_GCC_NAME $NEUTRON_GCC_NAME $HOST_CLANG_NAME; do
      [[ $COMPILER ]] && break
      _error "$MSG_ERR_SELECT"
    done
  fi
}

_ask_for_edit_makefile() {
  # returns => $EDIT_CC
  _confirm "$MSG_CONFIRM_MAKEFILE" "[y/N]"
  [[ $confirm =~ (y|Y|yes|Yes|YES) ]] &&
    $EDITOR "${KERNEL_DIR}/Makefile"
}

_ask_for_edit_cross_compile() {
  # returns => $EDIT_CC
  _confirm "$MSG_CONFIRM_CC $COMPILER ?" "[Y/n]"
  [[ $confirm =~ (n|N|no|No|NO) ]] && EDIT_CC="False"
}

_ask_for_cores() {
  # checks the amount of available cores (no limits here)
  # returns => $CORES
  local cpu; cpu="$(nproc --all)"
  _confirm "$MSG_CONFIRM_CPU" "[Y/n]"
  if [[ $confirm =~ (n|N|no|No|NO) ]]; then
    _prompt "$MSG_ASK_CORES" 1; read -r CORES
    until (( 1<=CORES && CORES<=cpu )); do
      _error "$MSG_ERR_CORES ${red}${CORES}"\
             "${yellow}($MSG_ERR_TOTAL ${cpu})"
      _prompt "$MSG_ASK_CORES" 1
      read -r CORES
    done
  else CORES="$cpu"
  fi
}

_ask_for_make_clean() {
  # returns => $MAKE_CLEAN
  _confirm "$MSG_CONFIRM_MCLEAN v$LINUX_VERSION ?" "[y/N]"
  [[ $confirm =~ (y|Y|yes|Yes|YES) ]] && MAKE_CLEAN="True"
}

_ask_for_new_build() {
  # returns => $new_build
  _confirm \
    "$MSG_CONFIRM_START ${TAG}-${CODENAME}-$LINUX_VERSION ?" \
    "[Y/n]"
  [[ $confirm =~ (n|N|no|No|NO) ]] && new_build="False"
}

_ask_for_telegram() {
  # returns => $build_status
  if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
    _confirm "$MSG_CONFIRM_TG" "[y/N]"
    [[ $confirm =~ (y|Y|yes|Yes|YES) ]] && build_status="True"
  fi
}

_ask_for_flashable_zip() {
  # returns => $flash_zip
  _confirm \
    "$MSG_CONFIRM_ZIP ${TAG}-${CODENAME}-$LINUX_VERSION ?" "[y/N]"
  [[ $confirm =~ (y|Y|yes|Yes|YES) ]] && flash_zip="True"
}

_ask_for_kernel_image() {
  # NOTE: we are working here from <boot> folder (auto completion)
  # checks the presence of this file
  # returns => $K_IMG
  _cd "$BOOT_DIR" "$MSG_ERR_DIR ${red}$BOOT_DIR"
  _prompt "$MSG_ASK_IMG" 1; read -r -e K_IMG
  until [[ -f $K_IMG ]]; do
    _error "$MSG_ERR_IMG ${red}$K_IMG"
    _prompt "$MSG_ASK_IMG" 1; read -r -e K_IMG
  done
  K_IMG="$(realpath "$K_IMG")"
  _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
}

_ask_for_run_again() {
  # returns => $run_again
  run_again="False"
  _confirm "$MSG_CONFIRM_RUN_AGAIN" "[y/N]"
  [[ $confirm =~ (y|Y|yes|Yes|YES) ]] && run_again="True"
}

_ask_for_install_pkg() {
  # warns the user that the script may crash while NO
  # returns => $install_pkg
  _confirm "$MSG_CONFIRM_PKG $1 ?" "[Y/n]"
  if [[ $confirm =~ (n|N|no|No|NO) ]]; then
    _error warn "$MSG_WARN_DEP ${red}${dep}"; sleep 2
  else install_pkg="True"
  fi
}

_ask_for_clone_toolchain() {
  # warns the user and exits the script while NO
  # returns => $clone_tc
  _confirm "$MSG_CONFIRM_CLONE_TC $1 ?" "[Y/n]"
  if [[ $confirm =~ (n|N|no|No|NO) ]]; then
    _error "$MSG_ERR_CLONE ${red}$1"; _exit 1
  else clone_tc="True"
  fi
}

_ask_for_clone_anykernel() {
  # warns the user and exits the script while NO
  # returns => $clone_ak
  _confirm "$MSG_CONFIRM_CLONE_AK3" "[Y/n]"
  if [[ $confirm =~ (n|N|no|No|NO) ]]; then
    _error "$MSG_ERR_CLONE ${red}${ANYKERNEL_DIR}"; _exit 1
  else clone_ak="True"
  fi
}

_ask_for_patch() {
  # patches from <patches>
  # returns => $kpatch
  _cd "${DIR}/patches" "$MSG_ERR_DIR ${red}${DIR}/patches"
  _prompt "$MSG_SELECT_PATCH" 2
  select kpatch in *.patch; do
    [[ $kpatch ]] && break
    _error "$MSG_ERR_SELECT"
  done
  _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
}

_ask_for_apply_patch() {
  # $1 = mode (patch or revert)
  # returns => $apply_patch
  _error warn "$kpatch => ${KERNEL_DIR##*/}"
  _confirm "$MSG_CONFIRM_PATCH (${1^^}) ?" "[Y/n]"
  [[ $confirm =~ (n|N|no|No|NO) ]] && _exit 0 || apply_patch="True"
}

_ask_for_update_aosp() {
  # $1 = name
  # returns => $update_aosp
  _error warn "$1 $MSG_ERR_LTAG $tag => ${latest/clang-}"
  _confirm "$MSG_CONFIRM_UP $1 ?" "[y/N]"
  [[ $confirm =~ (y|Y|yes|Yes|YES) ]] && update_aosp="True"
}


###---------------------------------------------------------------###
###          10. TELEGRAMER => kernel building feedback           ###
###---------------------------------------------------------------###

_send_msg() {
  # $1 = message
  curl --progress-bar -o /dev/null -fL -X POST -d text="$1" \
    -d parse_mode=html -d chat_id="$TELEGRAM_CHAT_ID" \
    "${TELEGRAM_API}/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
}

_send_file() {
  # $1 = file
  # $2 = caption
  local tg mode extension PHOTO_F AUDIO_F VIDEO_F ANIM_F VOICE_F
  extension=${1##*/*.}
  # shellcheck source=/dev/null
  source "${DIR}/etc/telegram.cfg"
  if [[ ${#extension} -lt 3 ]] \
    && [[ $extension != ai ]]; then tg="sendDocument"
  elif [[ ${PHOTO_F} =~ ${extension} ]]; then tg="sendPhoto"
  elif [[ ${AUDIO_F} =~ ${extension} ]]; then tg="sendAudio"
  elif [[ ${VIDEO_F} =~ ${extension} ]]; then tg="sendVideo"
  elif [[ ${ANIM_F} =~ ${extension} ]]; then tg="sendAnimation"
  elif [[ ${VOICE_F} =~ ${extension} ]]; then tg="sendVoice"
  else tg="sendDocument"
  fi
  mode="${tg/send}"
  curl --progress-bar -o /dev/null -fL -X POST \
    -F "${mode,}"=@"$1" -F caption="$2" \
    -F chat_id="$TELEGRAM_CHAT_ID" \
    -F disable_web_page_preview=true \
    "${TELEGRAM_API}/bot${TELEGRAM_BOT_TOKEN}/$tg"
}

_send_start_build_status() {
  [[ $build_status == True ]] && _send_msg "${status_msg//_/-}"
}

_send_success_build_status() {
  if [[ $build_status == True ]]; then
    local msg
    msg="$MSG_NOTE_SUCCESS $BUILD_TIME | ${REALCC//_/-}"
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
    _note "$MSG_NOTE_UPLOAD ${file##*/}..."
    MD5="$(md5sum "$file" | cut -d' ' -f1)"
    caption="$MSG_TG_CAPTION $BUILD_TIME"
    _send_file "$file" "$caption | MD5 Checksum: ${MD5//_/-}"
  fi
}

_set_html_status_msg() {
  # returns => $status_msg
  local android_version; android_version="AOSP $PLATFORM_VERSION"
  status_msg="

<b>${MSG_TG_HTML[0]}</b>  <code>${CODENAME}</code>
<b>${MSG_TG_HTML[1]}</b>  <code>v${LINUX_VERSION}</code>
<b>${MSG_TG_HTML[2]}</b>  <code>${KERNEL_VARIANT}</code>
<b>${MSG_TG_HTML[3]}</b>  <code>${BUILDER}</code>
<b>${MSG_TG_HTML[4]}</b>  <code>${CORES} Core(s)</code>
<b>${MSG_TG_HTML[5]}</b>  <code>${COMPILER} ${TCVER}</code>
<b>${MSG_TG_HTML[6]}</b>  <code>${HOST}</code>
<b>${MSG_TG_HTML[7]}</b>  <code>${TAG}</code>
<b>${MSG_TG_HTML[8]}</b>  <code>${android_version}</code>"
}

_send_msg_option() {
  # $1 = the message to send
  if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
    _note "$MSG_NOTE_SEND"; _send_msg "${OPTARG//_/-}"
  else
    _error "$MSG_ERR_API"
  fi
}

_send_file_option() {
  # $1 = the file to send
  if [[ -f $OPTARG ]]; then
    if [[ $TELEGRAM_CHAT_ID ]] && [[ $TELEGRAM_BOT_TOKEN ]]; then
      _note "$MSG_NOTE_UPLOAD ${OPTARG##*/}..."
      _send_file "$OPTARG"
    else
      _error "$MSG_ERR_API"
    fi
  else
    _error "$MSG_ERR_FILE ${red}$OPTARG"
  fi
}


###---------------------------------------------------------------###
###       11. VERSIONER => displays the toolchains versions       ###
###---------------------------------------------------------------###

_tc_version_option() {
  # displays the installed toolchains versions
  _note "$MSG_NOTE_SCAN_TC"
  local toolchains_data toolchains_list toolchain eva_v pt_v nt_v tc
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
  toolchains_list=(aosp llvm eva pclang nclang los pgcc ngcc host)
  for toolchain in "${toolchains_list[@]}"; do
    IFS="€"
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
      echo -e "${green}${tc[2]}: ${lblue}${tc_version##*/}$nc"
    elif [[ -n $eva_v ]] && [[ -n $pt_v ]]; then
      echo -e "${green}${tc[2]}: ${lblue}${pt_v}/${eva_v}$nc"
      unset pt_v
    elif [[ -n $eva_v ]] && [[ -n $nt_v ]]; then
      echo -e "${green}${tc[2]}: ${lblue}${nt_v}/${eva_v}$nc"
    fi
  done
}


###---------------------------------------------------------------###
###          12. READER => displays the compiled kernels          ###
###---------------------------------------------------------------###

_list_all_kernels() {
  # success: displays device codename in green
  # fail: displays device codename in red
  # grabs linuxversion, date, time and compiler from the logs
  if [[ -n $(find "${DIR}/out" \
      -mindepth 1 -maxdepth 1 -type d 2>/dev/null) ]]; then
    _note "$MSG_NOTE_LISTKERNEL"
    local kernel logfile linuxversion logdate compiler \
      compilerversion titlecolor
    for kernel in "${DIR}"/out/*; do
      logfile="$(find "${DIR}/logs/${kernel##*/}" -mindepth 1 \
        -maxdepth 1 -type f -iname "*.log" -printf "%T@ - %p\n" \
        2>/dev/null | sort -nr | head -n 1 \
        | awk -F" - " '{print $2}')"
      if [[ -f $logfile ]]; then
        if grep -sqm 1 REALCC= "$logfile"; then
          titlecolor="$green"
        else
          titlecolor="$red"
        fi
        linuxversion="$(grep -m 1 LINUX_VERSION= "$logfile")"
        logdate="$(grep -m 1 "> DATE=" "$logfile")"
        logtime="$(grep -m 1 "> TIME=" "$logfile")"
        compiler="$(grep -m 1 "> COMPILER=" "$logfile")"
        compilerversion="$(grep -m 1 "> TCVER=" "$logfile")"
        echo -e "${titlecolor}${kernel##*/}:$lblue"\
                "v${linuxversion/> LINUX_VERSION=}$magenta ─$nc"\
                "${compiler/> COMPILER=}$lblue"\
                "${compilerversion/> TCVER=}$magenta ─$nc"\
                "${logdate/> DATE=}$lblue ${logtime/> TIME=}"
      else
        echo -e "${red}${kernel##*/}:$nc $MSG_WARN_NO_LOG"
      fi
    done
  else
    _error "$MSG_ERR_LISTKERNEL"
  fi
}


###---------------------------------------------------------------###
###       13. PATCHER => patchs/reverts patches to a kernel       ###
###---------------------------------------------------------------###

_patch() {
  # $1 = mode (patch or revert)
  local pargs
  case $1 in
    patch) pargs=(-p1) ;;
    revert) pargs=(-R -p1) ;;
  esac
  _ask_for_patch
  _ask_for_kernel_dir
  _ask_for_apply_patch "${1}"
  if [[ $apply_patch == True ]]; then
    _note "$MSG_NOTE_PATCH $kpatch > ${KERNEL_DIR##*/}"
    _cd "$KERNEL_DIR" "$MSG_ERR_DIR ${red}$KERNEL_DIR"
    patch "${pargs[@]}" -i "${DIR}/patches/$kpatch"
    _cd "$DIR" "$MSG_ERR_DIR ${red}$DIR"
  fi
}


###---------------------------------------------------------------###
###      14. INSTALLER => dependency installation management      ###
###---------------------------------------------------------------###

_install_dep() {
  # defines the install command of some package managers
  # grabs the current linux package manager
  # checks and installs the missing dependencies...
  # NOTE: gcc will not be installed on termux (not fully supported)
  if [[ $AUTO_DEPENDENCIES == True ]]; then
    local pm_install_cmd pm_list manager pm dep
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
        IFS=" "; pm="${pm_install_cmd[$manager]}"
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
  # $1 = branch/version
  # $2 = url
  # $3 = dir
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

_install_aosp_tgz() {
  # $1 = dir
  # $2 = version
  _check mkdir "$1"
  _check unbuffer wget -O "${1##*/}.tar.gz" "$tgz"
  _note "$MSG_NOTE_TAR_AOSP ${1##*/}.tar.gz > toolchains/${1##*/}"
  _check unbuffer tar -xvf "${1##*/}.tar.gz" -C "$1"
  [[ ! -f ${DIR}/toolchains/$2 ]] &&
    echo "$latest" > "${DIR}/toolchains/$2"
  _check rm "${1##*/}.tar.gz"
  [[ -f wget-log ]] && _check rm wget-log
}

_clone_toolchains() {
  case $COMPILER in # aosp-clang
    "$AOSP_CLANG_NAME")
      _clone_tc "$AOSP_CLANG_VERSION" "$AOSP_CLANG_URL" \
                "$AOSP_CLANG_DIR"
      _clone_tc "$LLVM_ARM64_VERSION" "$LLVM_ARM64_URL" \
                "$LLVM_ARM64_DIR"
      _clone_tc "$LLVM_ARM_VERSION" "$LLVM_ARM_URL" \
                "$LLVM_ARM_DIR"
      ;;
  esac
  case $COMPILER in # neutron-clang or neutron-gcc
    "$NEUTRON_CLANG_NAME"|"$NEUTRON_GCC_NAME")
      _clone_tc "$NEUTRON_BRANCH" "$NEUTRON_URL" "$NEUTRON_DIR"
      ;;
  esac
  case $COMPILER in # proton-Clang or proton-gcc
    "$PROTON_CLANG_NAME"|"$PROTON_GCC_NAME")
      _clone_tc "$PROTON_BRANCH" "$PROTON_URL" "$PROTON_DIR"
      ;;
  esac
  case $COMPILER in # eva-gcc or proton-gcc or neutron-gcc
    "$EVA_GCC_NAME"|"$PROTON_GCC_NAME"|"$NEUTRON_GCC_NAME")
      _clone_tc "$EVA_ARM_BRANCH" "$EVA_ARM_URL" "$EVA_ARM_DIR"
      _clone_tc "$EVA_ARM64_BRANCH" "$EVA_ARM64_URL" \
                "$EVA_ARM64_DIR"
      ;;
  esac
  case $COMPILER in # lineage-gcc
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
###        15. UPDATER => update the script and toolchains        ###
###---------------------------------------------------------------###

_update_git() {
  # $1 = repo branch
  # all: checkouts and resets to main branch
  # zmb: checks if settings.cfg was updated
  # zmb: warns the user while settings changed
  # zmb: renames <user.cfg> to <user.cfg_bak>
  # all: pulls the changes
  git checkout "$1"; git reset --hard HEAD
  if [[ $1 == "$ZMB_BRANCH" ]] \
      && [[ -f ${DIR}/etc/user.cfg ]]; then
    local mod
    mod="$(git diff origin/"$ZMB_BRANCH" "${DIR}/etc/settings.cfg")"
    if [[ -n $mod ]]; then
      _error warn "$MSG_UP_CONF"; echo
      _check mv "${DIR}/etc/user.cfg" "${DIR}/etc/user.cfg_bak"
    fi
  fi
  _check unbuffer git pull
}

_full_upgrade() {
  # defines zmb and ak3 and toolchains data
  # upgrades existing stuff...
  local tp up_list up_data repository repo
  tp="${DIR}/toolchains"
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
    IFS="€"
    repo="${up_data[$repository]}"
    read -ra repo <<< "$repo"
    unset IFS
    if [[ -d ${repo[0]} ]]; then
      _note "$MSG_UPDATE ${repo[0]##*/}..."
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
            echo "$MSG_UP_ALREADY_UP $latest"
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


###---------------------------------------------------------------###
###           16. HELPER => displays zmb help and usage           ###
###---------------------------------------------------------------###

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

${bold}$MSG_HELP_INFO \
${cyan}https://kernel-builder.com$nc\n"
}


###---------------------------------------------------------------###
###        00. Runs the ZenMaxBuilder (ZMB) main processus        ###
###---------------------------------------------------------------###
_zenmaxbuilder "$@"


# THANKS FOR READING !
# ZMB by darkmaster @grm34
# -------------------------

