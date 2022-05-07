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


# Flashable ZIP Creation
# ======================
# - send status on Telegram
# - move image to AK3 folder
# - set AK3 configuration
# - create Flashable ZIP
# - move ZIP to builds folder
#   ----------------
#   $1 = kernel name
#   $2 = kernel image
#   $3 = build folder
#
_zip() {
    _note "$MSG_NOTE_ZIP ${1}.zip..."
    _send_zip_creation_status
    _check cp "$2" "$ANYKERNEL_DIR"
    _cd "$ANYKERNEL_DIR" "$MSG_ERR_DIR ${RED}AnyKernel"
    if [[ $START_TIME ]]; then _set_ak3_conf; fi

    _check unbuffer zip -r9 "${1}.zip" \
        ./* -x .git README.md ./*placeholder 2>&1

    if [[ ! -d $3 ]]; then _check mkdir "$3"; fi
    _check mv "${1}.zip" "$3"
    _cd "$DIR" "$MSG_ERR_DIR ${RED}$DIR"
}


# Signing ZIP with AOSP Keys
# ==========================
# - send signing status on Telegram
# - sign ZIP with AOSP Keys (JAVA)
#   ----------------
#   $1 = kernel name
#
_sign_zip() {
    _note "${MSG_NOTE_SIGN}..."
    _send_zip_signing_status
    _check unbuffer java -jar \
        "${DIR}/bin/zipsigner-3.0.jar" \
        "${1}.zip" "${1}-signed.zip" 2>&1
}


# AnyKernel Configuration
# =======================
# - edit anykernel.sh (SED)
# - edit init.spectrum.rc (SED)
#
_set_ak3_conf() {

    # init.spectrum.rc
    if [[ -f ${KERNEL_DIR}/$SPECTRUM ]]
    then
        _check cp -af \
            "${KERNEL_DIR}/$SPECTRUM" \
            init.spectrum.rc
        kn=$KERNEL_NAME
        _check sed -i \
            "s/*.spectrum.kernel.*/*.spectrum.kernel ${kn}/g" \
            init.spectrum.rc
    fi

    # anykernel.sh
    strings=(
        "s/kernel.string=.*/kernel.string=${TAG}-${CODENAME}/g"
        "s/kernel.for=.*/kernel.for=${KERNEL_VARIANT}/g"
        "s/kernel.compiler=.*/kernel.compiler=${COMPILER}/g"
        "s/kernel.made=.*/kernel.made=${BUILDER}/g"
        "s/kernel.version=.*/kernel.version=${LINUX_VERSION}/g"
        "s/message.word=.*/message.word=ZenMaxBuilder/g"
        "s/build.date=.*/build.date=${DATE}/g"
        "s/device.name1=.*/device.name1=${CODENAME}/g")
    for string in "${strings[@]}"
    do _check sed -i "$string" anykernel.sh
    done
}


# Clean AnyKernel folder
_clean_anykernel() {
    _note "${MSG_NOTE_CLEAN_AK3}..."
    for file in "${DIR}/${ANYKERNEL_DIR}"/*
    do
        case $file in (*.zip*|*Image*|*-dtb*|*spectrum.rc*)
            rm -f "${file}" || sleep 0.1
        esac
    done
}

