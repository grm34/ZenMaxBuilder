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

shopt -s checkwinsize progcomp
shopt -u autocd cdspell dirspell extglob progcomp_alias

# This script automatically translates base language strings and adds
# them into the various translations (original will be used on error).
# It also removes duplicate strings and rearranges them alphabetically.

_sort_strings() {
  # removes duplicate strings from an array
  # sorts the strings alphabetically
  # $@ = array of strings
  # returns => sorted_strings (array)
  local string strings
  declare -A strings
  for string in "${@}"; do
    [[ $string ]] && IFS=" " strings["${string:- }"]=1
  done
  # shellcheck disable=SC2207
  IFS=$'\n' sorted_strings=($(sort <<< "${!strings[*]}"))
  unset IFS
}

_clean_cfg_files() {
  # removes duplicates lines and sorts them alphabetically
  # $@ = array of files
  local file
  for file in "$@"; do
    mapfile -t strings < "$file"
    _sort_strings "${strings[@]}"
    printf "%s\n" "${sorted_strings[@]}" > "$file"
  done
}

_get_strings_from_cfg() {
  # grabs strings from CFG files
  # $@ = array of files
  # returns => <language_code>_strings cfg_list (arrays)
  local file name
  for file in "$@"; do
    name=${file##*/}; name="${name/.cfg/_strings}"
    mapfile -t "$name" < "$file"
    [[ $name != en_strings ]] && cfg_list+=("$name")
  done
}

_get_string_data() {
  # grabs string name and string value
  # returns => data (array)
  IFS=$'\n' read -d "" -ra data <<< "${1//=/$'\n'}"
  data[1]=${data[1]//\"}
  unset IFS
}

_translate_string() {
  # $1 = string to translate
  # $2 = language code (string)
  # returns => translated (string)
  translated="$(curl -s https://api-free.deepl.com/v2/translate \
    -d auth_key=f1414922-db81-5454-67bd-9608cdca44b3:fx \
    -d "text=$1" -d "target_lang=${2^^}" \
    | grep -o '"text":"[^"]*' | grep -o '[^"]*$')"
}

_translate_and_add_missing_strings_into_cfg() {
  # translates then write missing strings from base language
  # into the various translation files (from cfg_list)
  local line language trad_strings
  for line in "${en_strings[@]:?}"; do
    _get_string_data "$line"
    for language in "${cfg_list[@]}"; do
      declare -n trad_strings="$language"
      if [[ "${trad_strings[*]}" != *"${data[0]}"* ]]; then
        _translate_string "${data[1]}" "${language/_strings}"
        [[ -n $translated ]] && line="${data[0]}=\"${translated}\""
        [[ -n $translated ]] && note="translated" || note="original"
        trad_strings+=("$line"); file="${language/_strings/.cfg}"
        printf "%s\n" "${trad_strings[@]}" > "lang/$file"
        echo "=> ${data[0]} (${note}) added into $file"
      fi
    done
  done
}

echo "Running ZMB translate (this could take a while)..."
_clean_cfg_files lang/*.cfg
_get_strings_from_cfg lang/*.cfg
_translate_and_add_missing_strings_into_cfg
_clean_cfg_files lang/*.cfg
[[ $note ]] && echo "==> done" || echo "==> nothing to translate"

