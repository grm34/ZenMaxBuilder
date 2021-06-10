#!/usr/bin/bash

#   Copyright 2021 Neternels-Builder by darkmaster @grm34 Neternels Team
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Telegram API
API="https://api.telegram.org/${TELEGRAM_BOT}:${TELEGRAM_TOKEN}"


_send_msg() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${API}"/sendMessage \
        -d "parse_mode=html" \
        -d "chat_id=${TELEGRAM_ID}" \
        -d "text=${1}" \
        | tee /dev/null
}


_send_build() {
    curl --progress-bar -o /dev/null -fL \
        -X POST -F document=@"${1}" "${API}"/sendDocument \
        -F "chat_id=${TELEGRAM_ID}" \
        -F "disable_web_page_preview=true" \
        -F "caption=${2}" \
        | tee /dev/null
}
