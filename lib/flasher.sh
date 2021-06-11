#!/usr/bin/bash

#    Copyright (c) 2021 darkmaster @grm34 Neternels Team
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


_create_flashable_zip() {
    _note "Creating ${TAG}-${CODENAME}-${LINUX_VERSION}-${DATE}.zip..."

    # Send build status to Telegram
    if [[ ${BUILD_STATUS} == True ]]; then
        _send_msg "<b>${CODENAME}-${LINUX_VERSION}</b> | \
<code>Started flashable zip creation</code>"
    fi

    # Move GZ-DTB to AnyKernel folder
    _check cp "$OUT_DIR"/arch/arm64/boot/Image.gz-dtb "${DIR}"/AnyKernel/

    # CD to AnyKernel folder
    cd "${DIR}"/AnyKernel || (_error "AnyKernel not found!"; _exit)

    # Create init.spectrum.rc
    if [[ -f ${KERNEL_DIR}/init.ElectroSpectrum.rc ]]; then
        _check cp -af "${KERNEL_DIR}"/init.ElectroSpectrum.rc init.spectrum.rc
        _check sed -i "s/persist.spectrum.kernel.*/persist.spectrum.kernel \
${TAG}-${CODENAME}-${LINUX_VERSION}/g" init.spectrum.rc
    fi

    # Create anykernel.sh
    if [[ -f anykernel-real.sh ]]; then
        _check cp -af anykernel-real.sh anykernel.sh
    fi

    # Set anykernel.sh
    _check sed -i "s/kernel.string=.*/kernel.string=${TAG}-${CODENAME}/g" \
        anykernel.sh
    _check sed -i "s/kernel.for=.*/kernel.for=${KERNEL_VARIANT}/g" \
        anykernel.sh
    _check sed -i "s/kernel.compiler=.*/kernel.compiler=${COMPILER}/g" \
        anykernel.sh
    _check sed -i "s/kernel.made=.*/kernel.made=${BUILDER}/g" anykernel.sh
    _check sed -i "s/kernel.version=.*/kernel.version=${LINUX_VERSION}/g" \
        anykernel.sh
    _check sed -i "s/message.word=.*/message.word=NetEnerls ~ \
Development is Life ~ t.me\/neternels/g" anykernel.sh
    _check sed -i "s/build.date=.*/build.date=$DATE/g" anykernel.sh
    _check sed -i "s/device.name1=.*/device.name1=${CODENAME}/g" anykernel.sh

    # Create flashable zip
    _check zip -r9 "${TAG}"-"${CODENAME}"-"${LINUX_VERSION}"-"${DATE}".zip \
./* -x .git README.md ./*placeholder

    # Back to script dir
    cd "${DIR}" || (_error "${DIR} not found!"; _exit)
}


_sign_flashable_zip() {
    _note "Signing Zip file with AOSP keys..."

    # Send build status to Telegram
    if [[ ${BUILD_STATUS} == True ]]; then
        _send_msg "<b>${CODENAME}-${LINUX_VERSION}</b> | \
<code>Signing Zip file with AOSP keys</code>"
    fi

    # Sign flashable zip
    _check java -jar "${DIR}"/AnyKernel/zipsigner-3.0.jar \
"${DIR}"/AnyKernel/"${TAG}"-"${CODENAME}"-"${LINUX_VERSION}"-"${DATE}".zip \
"${DIR}"/builds/"${TAG}"-"${CODENAME}"-"${LINUX_VERSION}"-"${DATE}"\
-signed.zip
}
