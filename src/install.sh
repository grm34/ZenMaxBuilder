#!/usr/bin/env bash

set -e

if ! [[ $(uname -s) =~ ^(Linux|GNU*)$ ]]; then
  echo "ERROR: run ZenMaxBuilder installer on Linux" >&2
  exit 1
elif ! [[ -t 0 ]]; then
  echo "ERROR: run ZenMaxBuilder installer from a terminal" >&2
  exit 1
elif [[ $(whoami) == root ]]; then
  echo "ERROR: do not run ZenMaxBuilder installer as root" >&2
  exit 1
elif [[ ${BASH_SOURCE[0]} != "$0" ]]; then
  echo "ERROR: ZenMaxBuilder installer cannot be sourced" >&2
  return 1
fi

repo="https://github.com/grm34/ZenMaxBuilder.git"
target="${HOME}/ZenMaxBuilder"
bin="${PREFIX/usr}/usr/bin"

case $1 in
  install)
    echo "-> Installing ZenMaxBuilder..."
    git clone "$repo" "$target"
    chmod 755 "${target}/src/zmb.sh"
    sudo ln -s "${target}/src/zmb.sh" "${bin}/zmb"
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

