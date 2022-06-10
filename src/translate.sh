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
set -u

# For the moment this script automatically adds the base language
# strings into the various translations, but without translating them.
# It also removes duplicate strings and rearranges them alphabetically.

_sort_strings() {
  # Remove duplicate strings from an array
  # Sort the strings alphabetically
  # ARG: $@ = array of strings
  # Return: sorted_strings (array)
  declare -A strings
  for string in "${@}"; do
    [[ $string ]] && IFS=" " strings["${string:- }"]=1
  done
  # shellcheck disable=SC2207
  IFS=$'\n' sorted_strings=($(sort -d <<< "${!strings[*]}"))
  unset IFS
}

_clean_cfg_files() {
  # Remove duplicates lines and sort them alphabetically
  # ARG: $@ = array of files
  for file in "$@"; do
    mapfile -t strings < "$file"
    _sort_strings "${strings[@]}"
    printf "%s\n" "${sorted_strings[@]}" > "$file"
  done
}

_get_strings_from_cfg() {
  # Get strings from CFG files
  # ARG: $@ = array of files
  # Return: <language_code>_strings (array)
  #         cfg_list (array of the CFG found)
  for file in "$@"; do
    name=${file##*/}; name="${name/.cfg/_strings}"
    mapfile -t "$name" < "$file"
    [[ $name != en_strings ]] && cfg_list+=("$name")
  done
}

_get_string_data() {
  # Get string name and string value
  IFS=$'\n' read -d "" -ra data <<< "${1//=/$'\n'}"
  unset IFS
}

_add_missing_strings_into_cfg() {
  # Write missing strings from base language (en.cfg)
  # into the various translation files (from cfg_list)
  for line in "${en_strings[@]:?}"; do
    _get_string_data "$line"
    for language in "${cfg_list[@]}"; do
      declare -n trad_strings="$language"
      if [[ "${trad_strings[*]}" != *"${data[0]}"* ]]; then
        trad_strings+=("$line"); file="${language/_strings/.cfg}"
        printf "%s\n" "${trad_strings[@]}" > "lang/$file"
        echo "=> ${data[0]} added into $file"
      fi
    done
  done
}

_translate_string() {
  # ARG: $1 = string to translate
  # ARG: $2 = language code (uppercase string)
  # Return: translated (translated string)
  translated="$(curl -s https://api-free.deepl.com/v2/translate \
    -d auth_key=f1414922-db81-5454-67bd-9608cdca44b3:fx \
    -d "text=$1" -d "target_lang=$2" \
    | grep -o '"text":"[^"]*' | grep -o '[^"]*$')"
  echo "$translated" # TESTING: disable SC Warning
}

echo "Running ZMB translate (this could take a while)..."
_clean_cfg_files lang/*.cfg
_get_strings_from_cfg lang/*.cfg
_add_missing_strings_into_cfg
_clean_cfg_files lang/*.cfg

