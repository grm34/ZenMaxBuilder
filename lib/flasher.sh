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


_create_flashable_zip() {
    _note "Creating ${BUILD_NAME}-${DATE}.zip..."

    # Create init.spectrum.rc
    if [[ -f ${KERNEL_DIR}/${SPECTRUM} ]]; then
        cp -af "${KERNEL_DIR}/${SPECTRUM}" init.spectrum.rc
        B=${BUILD_NAME}
        sed -i \
            "s/persist.spectrum.kernel.*/persist.spectrum.kernel ${B}/g" \
            init.spectrum.rc
    fi

    # Move Kernel Image to AnyKernel folder
    cp "${KERNEL_IMG}" "${ANYKERNEL_DIR}"

    # CD to AnyKernel folder
    cd "${ANYKERNEL_DIR}" || (_error "AnyKernel dir not found !"; _exit)

    # Set anykernel.sh
    sed -i "s/kernel.string=.*/kernel.string=${TAG}-${CODENAME}/g" \
        anykernel.sh
    sed -i "s/kernel.for=.*/kernel.for=${KERNEL_VARIANT}/g" \
        anykernel.sh
    sed -i "s/kernel.compiler=.*/kernel.compiler=${COMPILER}/g" \
        anykernel.sh
    sed -i "s/kernel.made=.*/kernel.made=${BUILDER}/g" anykernel.sh
    sed -i "s/kernel.version=.*/kernel.version=${LINUX_VERSION}/g" \
        anykernel.sh
    sed -i "s/message.word=.*/message.word=Netenerls Team/g" anykernel.sh
    sed -i "s/build.date=.*/build.date=$DATE/g" anykernel.sh
    sed -i "s/device.name1=.*/device.name1=${CODENAME}/g" anykernel.sh

    # Create flashable zip
    unbuffer zip -r9 "${BUILD_NAME}-${DATE}.zip" ./* \
        -x .git README.md ./*placeholder 2>&1

    # Move zip to builds folder and clean
    mv "${BUILD_NAME}-${DATE}.zip" "${BUILD_DIR}"

    # Back to script dir
    cd "${DIR}" || (_error "${DIR} dir not found !"; _exit)
}


_sign_flashable_zip() {
    _note "Signing Zip file with AOSP keys..."

    # Send build status to Telegram
    _send_signing_zip_status

    # Sign flashable zip
    unbuffer java -jar "${DIR}/lib/tools/zipsigner-3.0.jar" \
        "${BUILD_DIR}/${BUILD_NAME}-${DATE}.zip" \
        "${BUILD_DIR}/${BUILD_NAME}-${DATE}-signed.zip" 2>&1
}


_create_zip_option() {
    if [[ -f ${OPTARG} ]]; then
        _clean_anykernel
        _note "Creating ${OPTARG}-{DATE}_${TIME}.zip..."

        # Move GZ-DTB to AnyKernel folder
        cp "${OPTARG}" "${ANYKERNEL_DIR}"

        # CD to AnyKernel folder
        cd "${ANYKERNEL_DIR}" || \
            (_error "AnyKernel dir not found !"; _exit)

        # Create flashable zip
        zip -r9 "${OPTARG##*/}-${DATE}-${TIME}.zip" ./* \
            -x .git README.md ./*placeholder

        # Sign flashable zip
        _note "Signing Zip file with AOSP keys..."
        java -jar "${DIR}/lib/tools/zipsigner-3.0.jar" \
            "${OPTARG##*/}-${DATE}_${TIME}.zip" \
            "${OPTARG##*/}-${DATE}_${TIME}-signed.zip"

        # Move zip to builds folder
        if [[ ! -d ${DIR}/builds/default ]]; then
            mkdir "${DIR}/builds/default"
        fi
        mv "${OPTARG##*/}-${DATE}_${TIME}-signed.zip" \
            "${DIR}/builds/default"

        # Back to script dir
        _clean_anykernel
        cd "${DIR}" || (_error "${DIR} dir not found !"; _exit)

    else
        # Display error while not valid
        _error "${OPTARG} not a valid kernel image !"
    fi
}
