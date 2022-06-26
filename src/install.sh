#!/usr/bin/env bash

# Ensures proper use
if ! [[ $(uname -s) =~ ^(Linux|GNU*)$ ]]; then
  echo "ERROR: run ZenMaxBuilder Installer on Linux" >&2
  exit 1
elif ! [[ -t 0 ]]; then
  echo "ERROR: run ZenMaxBuilder Installer from a terminal" >&2
  exit 1
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
bin="${PREFIX/usr}/usr/bin"
dependencies=(bash sed wget git curl zip tar jq expect make cmake
  automake autoconf llvm lld lldb clang gcc binutils bison perl
  gperf gawk flex bc python3 zstd openssl)

# Shell colors
#if [[ -t 1 ]]; then
#  colors="$(tput colors)"
#  if [[ -n $colors ]] && [[ $colors -ge 8 ]]; then
#    bold="$(tput bold)"
#    nc="\e[0m"
#    red="$(tput bold setaf 1)"
#    green="$(tput bold setaf 2)"
#    lyellow="$(tput setaf 3)"
#  fi
#fi

_install_dependencies() {
  # Note: gcc will not be installed on termux (not fully supported)
  local pm_install_cmd pm_list manager pm dep termux dep_list
  if which getprop &>/dev/null; then termux=1; fi
  declare -a dep_list
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
  if [[ ${pm[3]} ]]; then
    for dep in "${dependencies[@]}"; do
      if [[ $termux ]] && [[ $dep == gcc ]]; then
        continue
      else
        [[ $dep == llvm ]] && dep="llvm-ar"
        [[ $dep == binutils ]] && dep="ld"
        if ! which "${dep}" &>/dev/null; then
          [[ $dep == llvm-ar ]] && dep="llvm"
          [[ $dep == ld ]] && dep="binutils"
          dep_list+=("$dep")
          #if [[ $install_pkg == True ]]; then
          #  [[ ${pm[0]} == _ ]] && pm=("${pm[@]:1}")
          #  "${pm[@]}" "$dep"
          #fi
        fi
      fi
    done
  #else
    #_error "$MSG_ERR_OS"
  fi
  #_clone_anykernel
  echo "${dep_list[*]}"
}

# Install / uninstall
case $1 in
  install)
    echo "-> Installing ZenMaxBuilder..."
    git clone "$repo" "$target"
    chmod 755 "${target}"
    chmod +x "${target}/src/zmb.sh"
    sudo ln -f "${target}/src/zmb.sh" "${bin}/zmb"
    _install_dependencies
    echo "-> Successfully installed"
    ;;
  uninstall)
    echo "-> Uninstalling ZenMaxBuilder..."
    sudo rm -f "${bin}/zmb"
    echo "-> Successfully uninstalled"
    ;;
  *)
    echo "ERROR: missing 'install' or 'uninstall' keyword"
    ;;
esac

