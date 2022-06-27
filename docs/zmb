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

# Ensures proper use
if ! [[ $(uname -s) =~ ^(Linux|GNU*)$ ]]; then
  echo "ERROR: run ZenMaxBuilder Installer on Linux" >&2
  exit 1
elif ! [[ -t 0 ]]; then
  echo "ERROR: run ZenMaxBuilder Installer from a terminal" >&2
  exit 1
elif ! which tput &>/dev/null; then
  echo "ERROR: tput is missing, please install ncurses utils" >&2
  exit 65
elif [[ $(whoami) == root ]]; then
  echo "ERROR: do not run ZenMaxBuilder Installer as root" >&2
  exit 1
elif [[ ${BASH_SOURCE[0]} != "$0" ]]; then
  echo "ERROR: ZenMaxBuilder Installer cannot be sourced" >&2
  return 1
fi

# Shell options
set -e
shopt -s progcomp
shopt -u dirspell progcomp_alias

# Required variables
repo="https://github.com/grm34/ZenMaxBuilder.git"
target="${HOME}/ZenMaxBuilder"
bin="${PREFIX/\/usr}/usr/bin"

# Required dependencies
dependencies=(bash sed wget git curl zip tar jq expect make cmake
  automake autoconf llvm lld lldb clang gcc binutils bison perl
  gperf gawk flex bc python3 zstd openssl)

# Shell colors
if [[ -t 1 ]]; then
  colors="$(tput colors)"
  if [[ -n $colors ]] && [[ $colors -ge 8 ]]; then
    nc="\e[0m"
    red="$(tput bold setaf 1)"
    green="$(tput bold setaf 2)"
    yellow="$(tput setaf 3)"
    blue="$(tput bold setaf 4)"
    magenta="$(tput bold setaf 5)"
    cyan="$(tput setaf 6)"
  fi
fi

_note() {
  # Usage: _warn "message"
  echo -e "\n${magenta}Status: ${nc}${yellow}${*}$nc" >&2
}

_warn() {
  # Usage: _warn "message"
  echo -e "\n${blue}Warning: ${nc}${yellow}${*}$nc" >&2
}

_error() {
  # Usage: _error "message"
  echo -e "\n${red}Error: ${nc}${yellow}${*}$nc" >&2
}

_confirm() {
  # Usage: _confirm "question" "[Y/n]" (<ENTER> behavior)
  # Returns: $confirm
  echo -ne "${yellow}\n==> ${cyan}${1} ${red}${2} $nc"
  read -r confirm
  until [[ $confirm =~ ^(y|n|Y|N|yes|no|Yes|No|YES|NO)$ ]] \
      || [[ -z $confirm ]]; do
    _error "enter yes or no"
    _confirm "$@"
  done
}

_get_pm_and_missing_dependencies() {
  # Note: gcc will not be installed on termux (not fully supported)
  # Returns: $pm $missing_deps
  local pm_install_cmds pm_list manager dep termux
  if which getprop &>/dev/null; then termux=1; fi
  declare -A pm_install_cmds=(
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
      IFS=" "; pm="${pm_install_cmds[$manager]}"
      read -ra pm <<< "$pm"
      unset IFS; break
    fi
  done
  if [[ ${pm[3]} ]]; then
    missing_deps=()
    for dep in "${dependencies[@]}"; do
      if [[ $termux ]] && [[ $dep == gcc ]]; then
        continue
      else
        [[ $dep == llvm ]] && dep="llvm-ar"
        [[ $dep == binutils ]] && dep="ld"
        if ! which "${dep}" &>/dev/null; then
          [[ $dep == llvm-ar ]] && dep="llvm"
          [[ $dep == ld ]] && dep="binutils"
          missing_deps+=("$dep")
        fi
      fi
    done
  else
    _warn "your package manager cannot be found,"\
          "you have to manually install the dependencies."\
          "More information at$cyan https://kernel-builder.com"
  fi
}

# Options
case $1 in

  # Install dep and clone ZMB and add symlink to usr/bin
  install)
    echo -ne "\n${cyan}> Search for missing dependencies...$nc"
    _get_pm_and_missing_dependencies
    if [[ ${missing_deps[0]} ]]; then
      _warn "the following dependencies are missing"
      echo "${missing_deps[*]}"
      _confirm "Do you want to install ?" "[y/N]"
      if [[ $confirm =~ (y|Y|yes|Yes|YES) ]]; then
        [[ ${pm[0]} == _ ]] && pm=("${pm[@]:1}") &&
          missing_deps=("${missing_deps/openssl/openssl-tool}")
        "${pm[@]}" "${missing_deps[@]}"
      fi
    fi
    echo -e "\n${cyan}> Downloading ZenMaxBuilder...$nc"
    git clone "$repo" "$target"
    echo -e "\n${cyan}> Installing ZenMaxBuilder...$nc"
    chmod 755 "${target}"
    chmod +x "${target}/src/zmb.sh"
    sudo ln -f "${target}/src/zmb.sh" "${bin}/zmb"
    echo -e "\n${green}> Successfully installed !$nc"
    ;;

  # Remove symlink from usr/bin
  uninstall)
    echo -e "\n${cyan}> Uninstalling ZenMaxBuilder...$nc"
    sudo rm -f "${bin}/zmb"
    echo -e "\n${green}> Successfully uninstalled !$nc"
    ;;

  # Check dep and repo and symlink
  check)
    echo -ne "\n${cyan}> Search for missing dependencies...$nc"
    _get_pm_and_missing_dependencies
    if [[ ${missing_deps[0]} ]]; then
      _note "the following dependencies are missing"
      echo "${missing_deps[*]}"
    else
      _note "dependencies are already satisfied"
    fi
    echo -ne "\n${cyan}> Search for ZMB executable...$nc"
    if [[ -f ${bin}/zmb ]]; then _note "installed in $bin"
    else _note "no executable found in $bin"
    fi
    echo -ne "\n${cyan}> Search for ZMB repository...$nc"
    if [[ -d $target ]]; then _note "found ZenMaxBuilder in $HOME"
    else _note "no repository found in $HOME"
    fi
    ;;

  *)
    _error "missing 'check' or install' or 'uninstall' keyword"
    ;;
esac

