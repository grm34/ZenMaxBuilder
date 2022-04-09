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

API="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN"


# Send message [POST]
_send_msg() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${API}/sendMessage" \
        -d "parse_mode=html" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$1" \
        | tee /dev/null
}


# Send file [POST]
_send_file() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${API}/sendDocument" \
        -F "document=@$1" \
        -F "caption=$2" \
        -F "chat_id=$TELEGRAM_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        | tee /dev/null
}


########################
### External Options ###
########################


# [OPTION] Send message
_send_msg_option() {
    if [[ $TELEGRAM_CHAT_ID ]] && \
        [[ $TELEGRAM_BOT_TOKEN ]]
    then
        _note "${MSG_NOTE_SEND}..."
        _send_msg "${OPTARG//_/-}"
    else
        _error "$MSG_ERR_API"
    fi
}


# [OPTION] Send file
_send_file_option() {
    if [[ -f $OPTARG ]]
    then
        if [[ $TELEGRAM_CHAT_ID ]] && \
            [[ $TELEGRAM_BOT_TOKEN ]]
        then
            _note "${MSG_NOTE_UPLOAD}: ${OPTARG##*/}..."
            _send_file "$OPTARG"
        else
            _error "$MSG_ERR_API"
        fi
    else
        _error "$MSG_ERR_FILE ${RED}${OPTARG}"
    fi
}


#########################
### Make build status ###
#########################


# New build triggered
_send_make_build_status() {
    if [[ $BUILD_STATUS == True ]]
    then
        _send_msg "<b>${MSG_TG_NEW}</b> $STATUS_MSG"
    fi
}


# Success build
_send_success_build_status() {
    if [[ $BUILD_STATUS == True ]]
    then
        MSG="$MSG_NOTE_SUCCESS ${M}m${S}s"
        _send_msg "${KERNEL_NAME//_/-} | $MSG"
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
        END_TIME=$(TZ=$TIMEZONE date +%s)
        BUILD_TIME=$((END_TIME - START_TIME))
        M=$((BUILD_TIME / 60))
        S=$((BUILD_TIME % 60))
        sed -r \
            "s/\x1B\[(([0-9]+)(;[0-9]+)*)?[m,K,H,f,J]//g" \
            "$LOG" > "${LOG##*/}"
        MSG="$MSG_TG_FAILED ${M}m${S}s"
        _send_file \
            "${DIR}/${LOG##*/}" "v${LINUX_VERSION//_/-} | $MSG"
    fi
}


# Upload build
_upload_signed_build() {
    if [[ $BUILD_STATUS == True ]] && \
        [[ $FLASH_ZIP == True ]]
    then
        FILE=${BUILD_DIR}/${KERNEL_NAME}-${DATE}-signed.zip
        _note "${MSG_NOTE_UPLOAD}: ${FILE##*/}..."
        MD5=$(md5sum "$FILE" | cut -d' ' -f1)
        CAPTION="${MSG_TG_CAPTION}: ${M}m${S}s"
        _send_file \
            "$FILE" "$CAPTION | MD5 Checksum: ${MD5//_/-}"
    fi
}


# HTML Starting message
_set_html_status_msg() {
    export STATUS_MSG="

<b>${MSG_TG_HTML[0]} :</b>  <code>${CODENAME//_/-}</code>
<b>${MSG_TG_HTML[1]} :</b>  <code>v${LINUX_VERSION//_/-}</code>
<b>${MSG_TG_HTML[2]} :</b>  <code>${KERNEL_VARIANT//_/-}</code>
<b>${MSG_TG_HTML[3]} :</b>  <code>${BUILDER//_/-}</code>
<b>${MSG_TG_HTML[4]} :</b>  <code>${CORES//_/-}</code>
<b>${MSG_TG_HTML[5]} :</b>  <code>${COMPILER//_/-}</code>
<b>${MSG_TG_HTML[6]} :</b>  <code>${HOST//_/-}</code>
<b>${MSG_TG_HTML[7]} :</b>  <code>${TAG//_/-}</code>
<b>${MSG_TG_HTML[8]} :</b>  <code>${PLATFORM_VERSION//_/-}</code>"
}

