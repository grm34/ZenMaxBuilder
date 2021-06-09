#!/usr/bin/bash
# shellcheck disable=SC2034

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


_ask_for_kernel_dir() {
    if [ "${KERNEL_DIR}" == default ]; then
        until [ -d "${KERNEL_DIR}" ]; do
            _prompt "Enter kernel path (e.q. /home/user/mykernel)"
            read -r -e KERNEL_DIR
        done
    fi
}


_ask_for_toolchain() {
    _confirm "Do you wish to use default compiler (${DEFAULT_COMPILER})?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            _note "Select Toolchain compiler:"
            TOOLCHAINS=(PROTON GCC PROTONxGCC)
            until [[ ${COMPILER} =~ ^[1-3]$ ]]; do
                _select PROTON GCC PROTONxGCC
                read -r COMPILER
            done
            COMPILER=${TOOLCHAINS[${COMPILER}-1]}
            ;;
        *)
            COMPILER=${DEFAULT_COMPILER}
    esac
}


_ask_for_codename() {
    if [ "${CODENAME}" == default ]; then
        _prompt "Enter android device codename (e.q. X00TD)"
        read -r CODENAME
    fi
}


_ask_for_defconfig() {
    until [ -f "${KERNEL_DIR}"/arch/arm64/configs/"${DEFCONFIG}" ]; do
        _prompt "Enter defconfig name (e.q. neternels_defconfig)"
        read -r DEFCONFIG
    done
}


_ask_for_menuconfig() {
    _confirm "Do you wish to edit kernel with menuconfig"
    case ${CONFIRM} in
        n|N|no|No|NO)
            MENUCONFIG=False
            ;;
        *)
            MENUCONFIG=True
    esac
}


_ask_for_cores() {
    _confirm "Do you wish to use all availables CPU Cores?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            until [[ ${CORES} =~ ^[1-9]{1}[0-9]{0,1}$ ]]; do
                _prompt "Enter amount of cores to use"
                read -r CORES
            done
            ;;
        *)
            CORES=$(nproc --all)
    esac
}


_ask_for_telegram() {
    _confirm "Do you wish to send build status to NetErnels Team?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            BUILD_STATUS=False
            ;;
        *)
            BUILD_STATUS=True
    esac
}
