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
### TELEGRAM API ###
####################

api="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN"

# SEND MESSAGE (POST)
# ===================
#  $1 = message
#
_send_msg() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${api}/sendMessage" \
        -d "parse_mode=html" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$1" \
        | tee /dev/null
}

# SEND FILE (POST)
# ================
#  $1 = file
#  $2 = caption
#
_send_file() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${api}/sendDocument" \
        -F "document=@$1" \
        -F "caption=$2" \
        -F "chat_id=$TELEGRAM_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        | tee /dev/null
}


###########################
### KERNEL BUILD STATUS ###
###########################

# START BUILD STATUS
_send_start_build_status() {
    if [[ $BUILD_STATUS == True ]]
    then _send_msg "${STATUS_MSG//_/-}"
    fi
}


# SUCCESS BUILD STATUS
_send_success_build_status() {
    if [[ $BUILD_STATUS == True ]]
    then
        msg="$MSG_NOTE_SUCCESS $BUILD_TIME"
        _send_msg "${KERNEL_NAME//_/-} | $msg"
    fi
}


# ZIP CREATION STATUS
_send_zip_creation_status() {
    if [[ $BUILD_STATUS == True ]]
    then _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_ZIP"
    fi
}


# ZIP SIGNING STATUS
_send_zip_signing_status() {
    if [[ $BUILD_STATUS == True ]]
    then _send_msg "${KERNEL_NAME//_/-} | $MSG_NOTE_SIGN"
    fi
}


# FAIL BUILD STATUS WITH LOGFILE
_send_failed_build_logs() {
    if [[ $START_TIME ]] && [[ $BUILD_STATUS == True ]] && \
        { [[ ! $BUILD_TIME ]] || [[ $RUN_AGAIN == True ]]; }
    then
        _get_build_time
        _send_file "$LOG" \
            "v${LINUX_VERSION//_/-} | $MSG_TG_FAILED $BUILD_TIME"
    fi
}


# UPLOAD THE KERNEL
_upload_signed_build() {
    if [[ $BUILD_STATUS == True ]] && [[ $FLASH_ZIP == True ]]
    then
        file=${BUILD_DIR}/${KERNEL_NAME}-${DATE}-signed.zip
        _note "${MSG_NOTE_UPLOAD}: ${file##*/}..."
        MD5=$(md5sum "$file" | cut -d' ' -f1)
        caption="${MSG_TG_CAPTION}: $BUILD_TIME"
        _send_file \
            "$file" "$caption | MD5 Checksum: ${MD5//_/-}"
    fi
}


# HTML START BUILD STATUS MESSAGE
_set_html_status_msg() {
    if [[ -z $PLATFORM_VERSION ]]
    then android_version="AOSP Unified"
    else android_version="AOSP $PLATFORM_VERSION"
    fi
    export STATUS_MSG="

<b>${MSG_TG_HTML[0]} :</b>  <code>${CODENAME}</code>
<b>${MSG_TG_HTML[1]} :</b>  <code>v${LINUX_VERSION}</code>
<b>${MSG_TG_HTML[2]} :</b>  <code>${KERNEL_VARIANT}</code>
<b>${MSG_TG_HTML[3]} :</b>  <code>${BUILDER}</code>
<b>${MSG_TG_HTML[4]} :</b>  <code>${CORES} Core(s)</code>
<b>${MSG_TG_HTML[5]} :</b>  <code>${COMPILER} ${TCVER}</code>
<b>${MSG_TG_HTML[6]} :</b>  <code>${HOST}</code>
<b>${MSG_TG_HTML[7]} :</b>  <code>${TAG}</code>
<b>${MSG_TG_HTML[8]} :</b>  <code>${android_version}</code>"
}

