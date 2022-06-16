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

_get_devices_specs() {
  # Usage: _get_devices_specs "$@"
  local key value
  for key in "$@"; do
    value="$(grep -o '"'"$key"'":"[^"]*' \
      "temp/query.json" | grep -o '[^"]*$')"
    IFS=$'\n' read -d "" -ra "$key" <<< "$value"
    unset IFS
  done
}

_print_devices() {
  # Usage: _print_devices "index" "name" "brand"
  echo -e \
    "${yellow}${1}${nc} => ${green}$2 ${nc}(${blue}${3}${nc})"
}

_return_device_specs() {
  local device_specs order key spec; echo
  declare -A device_specs=(
    [brand]="{brand: .data.brand}"
    [name]="{name: .data.phone_name}"
    [date]="{date: .data.release_date}"
    [dimension]="{dimension: .data.dimension}"
    [os]="{os: .data.os}"
    [storage]="{storage: .data.storage}"
    [price]="{price: .data.specifications[] | select(.title == \"Misc\").specs[] | select(.key == \"Price\").val[0]}"
)
  order=(brand name date dimension os storage price)
  for key in "${order[@]}"; do
    spec="${device_specs[$key]}"
    spec="$(jq -c "$spec" temp/device.json)"
    if [[ -n $spec ]]; then
      IFS=":" read -r spec spec <<< "$spec"; unset IFS
      echo -e "${green}${key^}${nc}: ${spec::-1}"
    fi
  done
}

_search_devices() {
  # Usage: _search_devices "search"
  curl -s -L "${url}${2// /%20}" -o temp/query.json
  if grep -sqm 1 "phone_name" temp/query.json; then
    local device index
    _get_devices_specs "brand" "phone_name" "detail"
    # shellcheck disable=SC2154
    for device in "${!phone_name[@]}"; do
      _print_devices "$(( device + 1 ))" \
        "${phone_name[device]}" "${brand[device]}"
    done
    echo "Enter the phone number to check : "
    read -r device_number
    index="$(( device_number - 1 ))"
    # shellcheck disable=SC2154
    curl -s -L "${detail[index]}" -o temp/device.json
    if grep -sqm 1 phone_name temp/device.json; then
      _return_device_specs
    else
      echo "ERROR: nothing found about ${phone_name[index]}"
    fi
  else
    echo "ERROR: device not found"
    exit 1
  fi
}

[[ $1 == "-s" ]] && _search_devices "$@"

