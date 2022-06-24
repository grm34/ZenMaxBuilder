#!/usr/bin/env bash

set -u
shopt -s progcomp checkwinsize

required=(bash tput sed grep find wget git curl zip tar jq
  expect make cmake automake autoconf llvm-ar lld lldb clang
  gcc ld bison perl gperf gawk flex bc python3 zstd openssl)

echo "PATH -> ${PATH}"
for x in "${required[@]}"; do
  whereis="$(which "$x")"
  if [[ -n $whereis ]]; then
    echo "$x -> $whereis"
  else
    echo "$x -> not found"
  fi
done

