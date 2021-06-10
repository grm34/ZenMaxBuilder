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


_create_flashable_zip() {
    _note "Creating ${LINUX_VERSION}-${CODENAME}-NetErnels-${DATE}.zip..."

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
${LINUX_VERSION}-${CODENAME}-NetErnels/g" init.spectrum.rc
    fi

    # Create anykernel.sh
    if [[ -f anykernel-real.sh ]]; then
        _check cp -af anykernel-real.sh anykernel.sh
    fi

    # Set anykernel.sh
    _check sed -i "s/kernel.string=.*/kernel.string=NetErnels-${CODENAME}/g" \
        anykernel.sh
    _check sed -i "s/kernel.for=.*/kernel.for=${KERNEL_VARIANT}/g" \
        anykernel.sh
    _check sed -i "s/kernel.compiler=.*/kernel.compiler=${COMPILER}/g" \
        anykernel.sh
    _check sed -i "s/kernel.made=.*/kernel.made=${BUILDER}/g" anykernel.sh
    _check sed -i "s/kernel.version=.*/kernel.version=$LINUX_VERSION/g" \
        anykernel.sh
    _check sed -i "s/message.word=.*/message.word=NetEnerls ~ \
Development is Life ~ t.me\/neternels/g" anykernel.sh
    _check sed -i "s/build.date=.*/build.date=$DATE/g" anykernel.sh
    _check sed -i "s/device.name1=.*/device.name1=$CODENAME/g" anykernel.sh
    _check sed -i "s/device.name2=.*/device.name2=$CODENAME/g" anykernel.sh
    _check sed -i "s/device.name3=.*/device.name3=$CODENAME/g" anykernel.sh
    _check sed -i "s/device.name4=.*/device.name4=$CODENAME/g" anykernel.sh
    _check sed -i "s/device.name5=.*/device.name5=$CODENAME/g" anykernel.sh

    # Create flashable zip
    _check zip -r9 NetErnels-"${CODENAME}"-"${LINUX_VERSION}"-"${DATE}".zip \
./* -x .git README.md ./*placeholder

    # Back to script dir
    cd "${DIR}" || (_error "${DIR} not found!"; _exit)
}


_sign_flashable_zip() {
    _note "Signing Zip file with AOSP keys..."
    if [[ ${BUILD_STATUS} == True ]]; then
        _send_msg "<b>${CODENAME}-${LINUX_VERSION}</b> | \
<code>Signing Zip file with AOSP keys</code>"
    fi
    _check java -jar "${DIR}"/AnyKernel/zipsigner-3.0.jar \
"${DIR}"/AnyKernel/NetErnels-"${CODENAME}"-"${LINUX_VERSION}"-"${DATE}".zip \
"${DIR}"/builds/NetErnels-"${CODENAME}"-"${LINUX_VERSION}"-"${DATE}"\
-signed.zip
}
