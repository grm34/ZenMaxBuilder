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
#   $1 = kernel name
#   $2 = kernel image
#   $3 = build folder
# ======================
_zip() {
    _note "$MSG_NOTE_ZIP ${1}.zip..."

    # Send zip status on Telegram
    _send_zip_creation_status

    # Move image to AK3 folder
    _check cp "$2" "$ANYKERNEL_DIR"

    # CD to AK3 folder
    cd "$ANYKERNEL_DIR" || (
        _error "$MSG_ERR_DIR ${RED}AnyKernel"
        _exit
    )

    # Set AK3 configuration
    if [[ $START_TIME ]]
    then
        _set_ak3_conf
    fi

    # Create zip
    _check unbuffer zip -r9 "${1}.zip" \
        ./* -x .git README.md ./*placeholder 2>&1

    # Move zip to builds folder
    if [[ ! -d $3 ]]
    then
        _check mkdir "$3"
    fi
    _check mv "${1}.zip" "$3"

    # Back to script dir
    cd "$DIR" || (
        _error "$MSG_ERR_DIR ${RED}${DIR}"
        _exit
    )
}


# Signing ZIP with AOSP Keys
# ==========================
#   $1 = kernel name
# ==========================
_sign_zip() {
    _note "${MSG_NOTE_SIGN}..."

    # Send signing status on Telegram
    _send_zip_signing_status

    # Sign zip
    _check unbuffer java -jar \
        "${DIR}/bin/zipsigner-3.0.jar" \
        "${1}.zip" "${1}-signed.zip" 2>&1
}


# [AK3]
# Set init.spectrum.rc
# Set anykernel.sh
_set_ak3_conf() {

    # init.spectrum.rc
    if [[ -f ${KERNEL_DIR}/${SPECTRUM} ]]
    then
        _check cp -af \
            "${KERNEL_DIR}/${SPECTRUM}" \
            init.spectrum.rc
        kn=$KERNEL_NAME
        _check sed -i \
            "s/*.spectrum.kernel.*/*.spectrum.kernel ${kn}/g" \
            init.spectrum.rc
    fi

    # anykernel.sh
    _check sed -i \
        "s/kernel.string=.*/kernel.string=${TAG}-${CODENAME}/g" \
        anykernel.sh
    _check sed -i \
        "s/kernel.for=.*/kernel.for=${KERNEL_VARIANT}/g" \
        anykernel.sh
    _check sed -i \
        "s/kernel.compiler=.*/kernel.compiler=${COMPILER}/g" \
        anykernel.sh
    _check sed -i \
        "s/kernel.made=.*/kernel.made=${BUILDER}/g" \
        anykernel.sh
    _check sed -i \
        "s/kernel.version=.*/kernel.version=${LINUX_VERSION}/g" \
        anykernel.sh
    _check sed -i \
        "s/message.word=.*/message.word=Netenerls Team/g" \
        anykernel.sh
    _check sed -i \
        "s/build.date=.*/build.date=${DATE}/g" \
        anykernel.sh
    _check sed -i \
        "s/device.name1=.*/device.name1=${CODENAME}/g" \
        anykernel.sh
}


# [OPTION]
# Create Flashable ZIP
# Sign ZIP wuth AOSP Keys
_create_zip_option() {
    if [[ -f $OPTARG ]] && [[ ${OPTARG##*/} == Image* ]]
    then
        _clean_anykernel
        _zip "${OPTARG##*/}-${DATE}-${TIME}" "$OPTARG" \
            "${DIR}/builds/default"
        _sign_zip "${OPTARG##*/}-${DATE}-${TIME}"
        _clean_anykernel
    else
        _error "$MSG_ERR_IMG ${RED}${OPTARG}"
    fi
}

