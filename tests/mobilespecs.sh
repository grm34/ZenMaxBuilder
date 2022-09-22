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
[[ ! -d temp ]] && mkdir temp

_find_devices() {
  local key value
  for key in "$@"; do
    value="$(grep -o '"'"$key"'":"[^"]*' \
      "temp/query.json" | grep -o '[^"]*$')"
    IFS=$'\n' read -d "" -ra "$key" <<< "$value"
    unset IFS
  done
}

_print_devices() {
  echo -e \
    "${yellow}${1}${nc} => ${green}$2 ${nc}(${blue}${3}${nc})"
}

_deep_search() {
  echo "{$1: .data.specifications[] | " \
       "select(.title == \"$2\").specs[] | " \
       "select(.key == \"$3\").val[0]}"
}

_find_device_specs() {
  local device_specs key value order; echo
  declare -A device_specs=(
    [brand]="{brand: .data.brand}"
    [name]="{name: .data.phone_name}"
    [date]="{date: .data.release_date}"
    [dimension]="{dimension: .data.dimension}"
    [os]="{os: .data.os}"
    [storage]="{storage: .data.storage}"
    [screen]="$(_deep_search screen Body Build)"
    [size]="$(_deep_search size Display Size)"
    [resolution]="$(_deep_search resolution Display Resolution)"
    [chipset]="$(_deep_search chipset Platform Chipset)"
    [cpu]="$(_deep_search cpu Platform CPU)"
    [gpu]="$(_deep_search gpu Platform GPU)"
    [ram]="$(_deep_search ram Memory Internal)"
    [network]="$(_deep_search network Network Technology)"
    [speed]="$(_deep_search speed Network Speed)"
    [wlan]="$(_deep_search wlan Comms WLAN)"
    [bluetooth]="$(_deep_search bluetooth Comms Bluetooth)"
    [gps]="$(_deep_search gps Comms GPS)"
    [nfc]="$(_deep_search nfc Comms NFC)"
    [radio]="$(_deep_search radio Comms Radio)"
    [usb]="$(_deep_search usb Comms USB)"
    [battery]="$(_deep_search battery Battery Type)"
    [sensors]="$(_deep_search sensors Features Sensors)"
    [models]="$(_deep_search models Misc Models)"
    [price]="$(_deep_search price Misc Price)"
    [sim]="$(_deep_search sim Body SIM)"
  )
  order=(brand name os chipset cpu gpu storage ram screen size \
    resolution dimension usb network speed wlan bluetooth gps nfc \
    radio sim battery sensors models date price)
  for key in "${order[@]}"; do
    value="${device_specs[$key]}"
    value="$(jq -c "$value" temp/device.json)"
    if [[ -n $value ]]; then
      IFS=":" read -r value value <<< "$value"; unset IFS
      echo -e "${green}${key^}${nc}: ${value::-1}"
    fi
  done
}

_search_devices() {
  curl -s -L "${url}${2// /%20}" -o temp/query.json
  if grep -sqm 1 "phone_name" temp/query.json; then
    local device index
    _find_devices "brand" "phone_name" "detail"
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
      _find_device_specs
    else
      echo "ERROR: nothing found about ${phone_name[index]}"
    fi
  else
    echo "ERROR: device not found"
    exit 1
  fi
}

[[ $1 == "-i" ]] && _search_devices "$@"

