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


# Find out missing requirements
# =============================
# - set the DEP manager for each Linux distribution
# - get the install command of the current OS DEP manager
# - GCC will not be installed on TERMUX (not fully supported)
# - install missing dependencies
#
_install_dependencies() {
    if [[ $AUTO_DEPENDENCIES == True ]]
    then
        declare -A pms=(
            [apt]="sudo apt install -y"
            [pkg]="_ pkg install -y"
            [pacman]="sudo pacman -S --noconfirm"
            [yum]="sudo yum install -y"
            [emerge]="sudo emerge -1 -y"
            [zypper]="sudo zypper install -y"
            [dnf]="sudo dnf install -y"
        )
        pm_list=(pacman yum emerge zypper dnf pkg apt)
        for manager in "${pm_list[@]}"
        do
            if which "$manager" &>/dev/null
            then
                IFS=" "
                pm="${pms[$manager]}"
                read -ra pm <<< "$pm"
                unset IFS
                break
            fi
        done
        if [[ ${pm[3]} ]]
        then
            for DEP in "${DEPENDENCIES[@]}"
            do
                if [[ ${pm[0]} == _ ]] && [[ $DEP == gcc ]]
                then continue
                else
                    DEP=${DEP/llvm/llvm-ar}
                    DEP=${DEP/binutils/ld}
                    if ! which "${DEP}" &>/dev/null
                    then
                        DEP=${DEP/llvm-ar/llvm}
                        DEP=${DEP/ld/binutils}
                        _ask_for_install_pkg "$DEP"
                        if [[ $INSTALL_PKG == True ]]
                        then
                            eval "${pm[0]/_}" "${pm[1]}" \
                                 "${pm[2]}" "${pm[3]}" "$DEP"
                        fi
                    fi
                fi
            done
        else _error "$MSG_ERR_OS"
        fi
    fi
}


# Github Clone process
# ====================
#  $1 = repo branch
#  $2 = repo url
#  $3 = repo folder
#
_clone_tc() {
    if [[ ! -d $3 ]]
    then
        _ask_for_clone_toolchain "${3##*/}"
        if [[ $CLONE_TC == True ]]
        then git clone --depth=1 -b "$1" "$2" "$3"
        fi
    fi
}


# Install selected compiler
_clone_toolchains() {
    case $COMPILER in

        # Proton-Clang or Proton-GCC
        "$PROTON_CLANG_NAME"|"$PROTON_GCC_NAME")
            _clone_tc "$PROTON_BRANCH" \
                "$PROTON_URL" "$PROTON_DIR"
            ;;
        # Eva-GCC or Proton-GCC
        "$EVA_GCC_NAME"|"$PROTON_GCC_NAME")
            _clone_tc "$GCC_ARM_BRANCH" \
                "$GCC_ARM_URL" "$GCC_ARM_DIR"
            _clone_tc "$GCC_ARM64_BRANCH" \
                "$GCC_ARM64_URL" "$GCC_ARM64_DIR"
            ;;
        # Lineage-GCC
        "$LOS_GCC_NAME")
            _clone_tc "$LOS_ARM_BRANCH" \
                "$LOS_ARM_URL" "$LOS_ARM_DIR"
            _clone_tc "$LOS_ARM64_BRANCH" \
                "$LOS_ARM64_URL" "$LOS_ARM64_DIR"
    esac
}


# Install AK3
_clone_anykernel() {
    if [[ ! -d $ANYKERNEL_DIR ]]
    then
        _ask_for_clone_anykernel
        if [[ $CLONE_AK == True ]]
        then
            git clone -b "$ANYKERNEL_BRANCH" \
                "$ANYKERNEL_URL" "$ANYKERNEL_DIR"
        fi
    fi
}

