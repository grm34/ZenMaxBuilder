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

# Install / uninstall
case $1 in
  install)
    echo "-> Installing ZenMaxBuilder..."
    git clone "$repo" "$target"
    chmod 755 "${target}/src/zmb.sh"
    sudo ln -f "${target}/src/zmb.sh" "${bin}/zmb"
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

