#!/usr/bin/bash
# shellcheck disable=SC2034

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


_ask_for_kernel_dir() {
    if [[ ${KERNEL_DIR} == default ]]; then
        until [[ -d ${KERNEL_DIR} ]]; do
            _prompt "Enter kernel path (e.q. /home/user/mykernel)"
            read -r -e KERNEL_DIR
        done
    fi
}


_ask_for_toolchain() {
    _confirm "Do you wish to use default compiler? (${DEFAULT_COMPILER})"
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
    if [[ ${CODENAME} == default ]]; then
        _prompt "Enter android device codename (e.q. X00TD)"
        read -r CODENAME
    fi
}


_ask_for_defconfig() {
    cd "${KERNEL_DIR}"/arch/arm64/configs/ || (_error "${KERNEL_DIR}"; _exit)
    until [[ -f ${DEFCONFIG} ]]; do
        _prompt "Enter defconfig name (e.q. neternels_defconfig)"
        read -r -e DEFCONFIG
    done
    cd "${DIR}" || (_error "${DIR} not found!"; _exit)
}


_ask_for_menuconfig() {
    _confirm "Do you wish to edit kernel with menuconfig?"
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
    _confirm "Do you wish to send build status to Telegram?"
    case ${CONFIRM} in
        n|N|no|No|NO)
            BUILD_STATUS=False
            ;;
        *)
            BUILD_STATUS=True
    esac
}
