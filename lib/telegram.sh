#!/usr/bin/bash

#    Copyright (c) 2022 @grm34 Neternels Team
#
#    Permission is hereby granted, free of charge, to any person
#    obtaining a copy of this software and associated documentation
#    files (the "Software"), to deal in the Software without restriction,
#    including without limitation the rights to use, copy, modify, merge,
#    publish, distribute, sublicense, and/or sell copies of the Software,
#    and to permit persons to whom the Software is furnished to do so,
#    subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be
#    included in all copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Telegram API
API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"


_send_msg() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${API}/sendMessage" \
        -F "parse_mode=html" \
        -F "chat_id=${TELEGRAM_CHAT_ID}" \
        -F "text=${1}" \
        | tee /dev/null
}


_send_file() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${API}/sendDocument" \
        -F "document=@${1}" \
        -F "caption=${2}" \
        -F "chat_id=${TELEGRAM_CHAT_ID}" \
        -F "disable_web_page_preview=true" \
        | tee /dev/null
}


_send_status_on_telegram() {
    if [[ ${BUILD_STATUS} == True ]]; then
        _send_msg "<b>${CODENAME}-${LINUX_VERSION}</b> | \
<code>Kernel Successfully Compiled after $((BUILD_TIME / 60)) minutes and \
$((BUILD_TIME % 60)) seconds</code>"
    fi
}


# Upload build on Telegram
_upload_build_on_telegram() {
    if [[ ${BUILD_STATUS} == True ]]; then
        _note "Uploading build on Telegram..."

        MD5=$(md5sum "${DIR}/builds/${TAG}-${CODENAME}-${LINUX_VERSION}-\
${DATE}-signed.zip" | cut -d' ' -f1)

        _send_file "${DIR}/builds/${TAG}-${CODENAME}-${LINUX_VERSION}-\
${DATE}-signed.zip" "MD5 Checksum: ${MD5}"
    fi
}
