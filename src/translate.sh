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

# For the moment this script automatically adds the base language
# strings to the various translations but without translating them.
# While new strings are added, it rearranges them alphabetically.

shopt -s checkwinsize progcomp
shopt -u autocd cdspell dirspell extglob progcomp_alias
set -u

_sort_strings() {
  IFS=$'\n' sorted_strings=("$(sort -d <<< "${*}")")
  unset IFS
}

_get_string_data() {
  IFS=$'\n' read -d "" -ra data <<< "${1//=/$'\n'}"
  unset IFS
}

echo "Running ZenMaxBuilder translate script..."
mapfile -t base_strings < lang/en.cfg
_sort_strings "${base_strings[@]}"

for line in "${sorted_strings[@]}"; do
  _get_string_data "$line"
  for file in lang/*.cfg; do
    if [[ $file != lang/en.cfg ]]; then
      if ! grep -sqm 1 "${data[0]}" "$file"; then
        echo "$line" >> "$file"
      fi
    fi
  done
done

for file in lang/*.cfg; do
  mapfile -t strings < "$file"
  _sort_strings "${strings[@]}"
  if [[ ${strings[*]} != "${sorted_strings[*]}" ]]; then
    rm -f "$file"; touch "$file"
    for line in "${sorted_strings[@]}"; do
      echo "$line" >> "$file"
    done
  fi
done

