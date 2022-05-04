#!/usr/bin/bash

# Copyright (c) 2021-2022 @grm34 Neternels Team
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


####################
### Telegram API ###
####################

api="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN"


# [POST] Send message
# ===================
#   $1 = message
# ===================
_send_msg() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${api}/sendMessage" \
        -d "parse_mode=html" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$1" \
        | tee /dev/null
}


# [POST] Send file
# ================
#   $1 = file
#   $2 = caption
# ================
_send_file() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${api}/sendDocument" \
        -F "document=@$1" \
        -F "caption=$2" \
        -F "chat_id=$TELEGRAM_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        | tee /dev/null
}


#########################
### Make build status ###
#########################


# New build triggered
_send_make_build_status() {
    if [[ $BUILD_STATUS == True ]]
    then
        _send_msg "${STATUS_MSG//_/-}"
    fi
}


# Success build
_send_success_build_status() {
    if [[ $BUILD_STATUS == True ]]
    then
        msg="$MSG_NOTE_SUCCESS $BUILD_TIME"
        _send_msg "${KERNEL_NAME//_/-} | $msg"
    fi
}


# Zipping build
_send_zip_creation_status() {
    if [[ $BUILD_STATUS == True ]]
    then
        _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_ZIP"
    fi
}


# Signing build
_send_zip_signing_status() {
    if [[ $BUILD_STATUS == True ]]
    then
        _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_SIGN"
    fi
}


# Failed build with logfile
_send_failed_build_logs() {
    if [[ $START_TIME ]] && [[ ! $BUILD_TIME ]] && \
        [[ $BUILD_STATUS == True ]]
    then
        _get_build_time
        msg="$MSG_TG_FAILED $BUILD_TIME"
        _send_file \
            "${DIR}/${LOG##*/}" "v${LINUX_VERSION//_/-} | $msg"
    fi
}


# Upload build
_upload_signed_build() {
    if [[ $BUILD_STATUS == True ]] && \
        [[ $FLASH_ZIP == True ]]
    then
        file=${BUILD_DIR}/${KERNEL_NAME}-${DATE}-signed.zip
        _note "${MSG_NOTE_UPLOAD}: ${file##*/}..."
        MD5=$(md5sum "$file" | cut -d' ' -f1)
        caption="${MSG_TG_CAPTION}: $BUILD_TIME"
        _send_file \
            "$file" "$caption | MD5 Checksum: ${MD5//_/-}"
    fi
}


# Starting build message
_set_html_status_msg() {
    export STATUS_MSG="

<b>${MSG_TG_HTML[0]} :</b>  <code>${CODENAME}</code>
<b>${MSG_TG_HTML[1]} :</b>  <code>v${LINUX_VERSION}</code>
<b>${MSG_TG_HTML[2]} :</b>  <code>${KERNEL_VARIANT}</code>
<b>${MSG_TG_HTML[3]} :</b>  <code>${BUILDER}</code>
<b>${MSG_TG_HTML[4]} :</b>  <code>${CORES}</code>
<b>${MSG_TG_HTML[5]} :</b>  <code>${COMPILER} ${TCVER##*/}</code>
<b>${MSG_TG_HTML[6]} :</b>  <code>${HOST}</code>
<b>${MSG_TG_HTML[7]} :</b>  <code>${TAG}</code>
<b>${MSG_TG_HTML[8]} :</b>  <code>${PLATFORM_VERSION}</code>"
}

