#!/usr/bin/env bash

set -u



nc="\e[0m"
#red="$(tput bold setaf 1)"
green="$(tput bold setaf 2)"
yellow="$(tput bold setaf 3)"
blue="$(tput bold setaf 4)"
#magenta="$(tput bold setaf 5)"
#cyan="$(tput bold setaf 6)"

url="https://api-mobilespecs.azharimm.site/v2/search?query="

_parse_json() {
  # Usage: _parse_json "$file" $@"
  local data args
  [[ $1 =~ device ]] && args="-om 1" || args="-o"
  for data in "${@/$1}"; do
    grep "$args" '"'"$data"'":"[^"]*' "temp/$1" \
      | grep -o '[^"]*$' > "temp/${data}.txt"
  done
}

_map_data() {
  # Usage: _map_data "$@"
  local file name
  for file in "$@"; do
    name="${file##*/}"; name="${name/.txt}"
    mapfile -t "$name" < "$file"
  done
}

_print_devices() {
  # Usage: _print_devices "index" "name" "brand"
  echo -e \
    "${yellow}${1}${nc} => ${green}$2 ${nc}(${blue}${3}${nc})"
}

_return_search() {
  local device
  # shellcheck disable=SC2154
  for device in "${!phone_name[@]}"; do
    _print_devices "$(( device + 1 ))" \
      "${phone_name[device]}" "${brand[device]}"
  done
}

_return_device_specs() {
  # Usage: _run_device_specs "$@"
  local spec; echo
  for spec in "$@"; do
    [[ -n $spec ]] && echo -e "${green}${spec^}${nc}: ${!spec}"
  done
}

_search_device() {
  # Usage: _search_device "search"
  curl -s -L "${url}${2// /%20}" -o temp/query.json
  if grep -sqm 1 phone_name temp/query.json; then
    _parse_json query.json "brand" "phone_name" "detail"
    _map_data temp/*.txt && rm temp/*.txt
    _return_search
    echo "Enter the phone number to check : "
    read -r device_number
    local index; index="$(( device_number - 1 ))"
    # shellcheck disable=SC2154
    curl -s -L "${detail[index]}" -o temp/device.json
    if grep -sqm 1 phone_name temp/device.json; then
      local specs; specs=("brand" "phone_name" "release_date" \
        "dimension" "os" "storage")
      _parse_json device.json "${specs[@]}"
      _map_data temp/*.txt && rm temp/*.txt
      _return_device_specs "${specs[@]}"
    else
      echo "ERROR: nothing found about ${phone_name[index]}"
    fi
  else
    echo "ERROR: device not found"
    exit 1
  fi
}

[[ $1 == "-s" ]] && _search_device "$@"

