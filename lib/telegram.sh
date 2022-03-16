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

API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"


_send_msg() {
    curl --progress-bar -o /dev/null -fL \
        -X POST "${API}/sendMessage" \
        -d "parse_mode=html" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${1}" \
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


########################
### External Options ###
########################


_send_msg_option() {
    if [[ ${TELEGRAM_CHAT_ID} ]] && [[ ${TELEGRAM_BOT_TOKEN} ]]; then
        _note "Sending message on Telegram...";
        _send_msg "${OPTARG//_/-}"
    else
        _error "you must configure Telegram API settings first !"
    fi
}


_send_file_option() {
    if [[ -f ${OPTARG} ]]; then
        if [[ ${TELEGRAM_CHAT_ID} ]] && [[ ${TELEGRAM_BOT_TOKEN} ]]; then
            _note "Uploading ${OPTARG} on Telegram..."
            _send_file "${OPTARG}"
        else
            _error "you must configure Telegram API settings first !"
        fi
    else
        _error "${OPTARG} file not found !"
    fi
}


#########################
### Make build status ###
#########################


_send_make_build_status() {
    if [[ ${BUILD_STATUS} == True ]]; then
        MSG="<b>Android Kernel Build Triggered</b> ${STATUS_MSG}"
        _send_msg "${MSG}"
    fi
}


_send_zip_creation_status() {
    if [[ ${BUILD_STATUS} == True ]]; then
        _send_msg "${BUILD_NAMETemp//_/-} | Started flashable zip creation"
    fi
}


_send_signing_zip_status() {
    if [[ ${BUILD_STATUS} == True ]]; then
        _send_msg "${BUILD_NAMETemp//_/-} | Signing Zip file with AOSP keys"
    fi
}


_upload_build_on_telegram() {
    if [[ ${BUILD_STATUS} == True ]] && [[ ${FLASH_ZIP} == True ]]; then
        _note "Uploading build on Telegram..."
        FILE="${BUILD_DIR}/${BUILD_NAME}-${DATE}-signed.zip"
        MD5=$(md5sum "${FILE}" | cut -d' ' -f1)
        CAPTION="Build took: ${M} minutes and ${S} seconds"
        _send_file "${FILE}" "${CAPTION} | MD5 Checksum: ${MD5//_/-}"
    fi
}


_send_build_failed_logs() {
    if [[ ${START_TIME} ]] && [[ ! $BUILD_TIME ]] && \
            [[ ${BUILD_STATUS} == True ]]; then
        END_TIME=$(TZ=${TIMEZONE} date +%s)
        BUILD_TIME=$((END_TIME - START_TIME))
        M=$((BUILD_TIME / 60))
        S=$((BUILD_TIME % 60))
        sed 's/\x1b\[[^\x1b]*m//g' "${LOG}" > buildlog
        MSG="Build Failed to Compile After ${M} minutes and ${S} seconds"
        _send_file "${DIR}/buildlog" "v${LINUX_VERSION//_/-} | ${MSG}"
    fi
}


_set_telegram_status_msg() {
    export STATUS_MSG="

<b>Android Device :</b>  <code>${CODENAME//_/-}</code>
<b>Kernel Version :</b>  <code>v${LINUX_VERSION//_/-}</code>
<b>Kernel Variant :</b>  <code>${KERNEL_VARIANT//_/-}</code>
<b>Host Builder :</b>  <code>${BUILDER//_/-}</code>
<b>Host Core Count :</b>  <code>${CORES//_/-}</code>
<b>Compiler Used :</b>  <code>${COMPILER//_/-}</code>
<b>Operating System :</b>  <code>${HOST//_/-}</code>
<b>Build Tag :</b>  <code>${TAG//_/-}</code>
<b>Android :</b>  <code>${PLATFORM_VERSION//_/-}</code>"
}
