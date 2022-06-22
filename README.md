# 🆉🅴🅽🅼🅰🆇🅱🆄🅸🅻🅳🅴🆁 📲

<a href="https://app.codiga.io/public/project/23638/ZenMaxBuilder/dashboard">
  <img src="https://api.codiga.io/project/23638/score/svg" alt="Codescore">
</a>

<a href="https://app.codiga.io/public/project/23638/ZenMaxBuilder/dashboard">
  <img src="https://api.codiga.io/project/23638/status/svg" alt="Codequality">
</a>

<a href="https://www.codefactor.io/repository/github/grm34/zenmaxbuilder">
  <img src="https://www.codefactor.io/repository/github/grm34/zenmaxbuilder/badge" alt="Codefactor">
</a>

<a href="https://github.com/grm34/ZenMaxBuilder/fork">
  <img src="https://img.shields.io/github/forks/grm34/ZenMaxBuilder.svg?logo=github" alt="Forks">
</a>

<a href="https://github.com/grm34/ZenMaxBuilder/stargazers">
  <img src="https://img.shields.io/github/stars/grm34/ZenMaxBuilder.svg?logo=github-sponsors" alt="Stars">
</a>
<br>

<a href="https://mit-license.org/">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg?logo=keepassxc" alt="License: MIT">
</a>

<a href="https://github.com/grm34/ZenMaxBuilder/issues">
  <img src="https://img.shields.io/github/issues/grm34/ZenMaxBuilder.svg?logo=git" alt="Issues">
</a>

<a href="https://github.com/grm34/ZenMaxBuilder/commits">
  <img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/y/grm34/zenmaxbuilder?label=commits&logo=github">
</a>

<a href="https://github.com/grm34/ZenMaxBuilder/commits">
  <img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/grm34/ZenMaxBuilder?&logo=Github">
</a>
<br>

<details>
  <summary>Some tested distros</summary>

<a href="https://ubuntu.com">
  <img src="https://img.shields.io/badge/Ubuntu-✅-blue.svg?logo=ubuntu" alt="distro">
</a>

<a href="https://archlinux.org">
  <img src="https://img.shields.io/badge/ArchLinux-✅-blue.svg?logo=archlinux" alt="distro">
</a>

<a href="https://www.debian.org">
  <img src="https://img.shields.io/badge/Debian-✅-blue.svg?logo=debian" alt="distro">
</a>

<a href="https://getfedora.org">
  <img src="https://img.shields.io/badge/Fedora-✅-blue.svg?logo=fedora" alt="distro">
</a>

<a href="https://manjaro.org">
  <img src="https://img.shields.io/badge/Manjaro-✅-blue.svg?logo=manjaro" alt="distro">
</a>
<br>

<a href="https://linuxmint.com">
  <img src="https://img.shields.io/badge/Linux Mint-✅-blue.svg?logo=linuxmint" alt="distro">
</a>

<a href="https://www.redhat.com">
  <img src="https://img.shields.io/badge/RedHat-❔-blue.svg?logo=redhat" alt="distro">
</a>

<a href="https://www.gentoo.org">
  <img src="https://img.shields.io/badge/Gentoo-❔-blue.svg?logo=gentoo" alt="distro">
</a>

<a href="https://www.centos.org">
  <img src="https://img.shields.io/badge/CentOS-❔-blue.svg?logo=centos" alt="distro">
</a>

<a href="https://www.opensuse.org">
  <img src="https://img.shields.io/badge/OpenSuse-❔-blue.svg?logo=opensuse" alt="distro">
</a>
<br>

<a href="https://www.kali.org">
  <img src="https://img.shields.io/badge/Kali Linux-✅-blue.svg?logo=kalilinux" alt="distro">
</a>

<a href="https://www.blackarch.org">
  <img src="https://img.shields.io/badge/BlackArch-✅-blue.svg?logo=archlinux" alt="distro">
</a>

<a href="https://termux.com">
  <img src="https://img.shields.io/badge/Termux-⚠️-blue.svg?logo=android" alt="distro">
</a>

<a href="https://www.freebsd.org">
  <img src="https://img.shields.io/badge/FreeBSD-❔-blue.svg?logo=freebsd" alt="distro">
</a>
<br>

<a href="https://www.microsoft.com/en-us/windows">
  <img src="https://img.shields.io/badge/Windows-❌-blue.svg?logo=windows" alt="distro">
</a>

<a href="https://www.apple.com/macos">
  <img src="https://img.shields.io/badge/MacOS-❌-blue.svg?logo=macos" alt="distro">
</a>
</details>

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Options](#options)
- [Working Structure](#working-structure)
- [Toolchains](#toolchains)
- [Screenshots](#screenshots)
- [More information](#more-information)
- [Common warnings and errors](#common-warnings-and-errors)
- [Reporting Issues](#reporting-issues)
- [Contributing](#contributing)
- [Help us Translate ZenMaxBuilder](#help-us-translate-zenmaxbuilder)
- [License](#license)
- [Credits](#credits)

## Overview

ZenMaxBuilder (ZMB) is a Linux kernel builder written in Bash and oriented for android devices but as well compatible for other platforms. It can be launched on any compatible Linux system (feel free to Pull Request for win/mac support). By default it uses AOSP-Clang, Eva-GCC, Proton-Clang, Neutron-Clang or Lineage-GCC but you can use any Clang or GCC toolchain you like (with LLVM and binutils included).

Find all your compilations and working folders in one place, update and maintain your kernels faster. Full logs with the possibility to restart the build after error. Automatic creation of a flashable signed ZIP for android devices (with AK3 and AOSP Keys). Real time status feedback with build sending on any group or Telegram channel. And more. The perfect tool to compile on the fly and keep fresh and clean kernel paths.

## Requirements

- A compatible Linux system
- The kernel source code of your device/os
- A minimum of knowledge in kernel compilation
- Patience

The installation of the missing dependencies will be offered by ZenMaxBuilder, asking you first one by one (no packages are installed without your prior consent).

And of course, you can install them manually with your favorite package manager :

    bash sed wget git curl zip tar jq expect make cmake automake autoconf llvm lld lldb clang gcc binutils bison perl gperf gawk flex bc python3 zstd openssl

The optional flashable zip signature with AOSP Keys requires java (JDK) which is not proposed to install by ZenMaxBuilder (openjdk recommended).

## Installation

Install ZenMaxBuilder (will be installed in your `HOME`) :

    wget https://kernel-builder.com/zmb && bash zmb install; rm zmb

Uninstall ZenMaxBuilder :

    bash ~/ZenMaxBuilder/docs/zmb uninstall
    rm -rf ~/ZenMaxBuilder

## Configuration

Create a copy of [settings.cfg](https://github.com/grm34/ZenMaxBuilder/blob/zmb/etc/settings.cfg) to set your settings (optional) :

    cp ~/ZenMaxBuilder/etc/settings.cfg ~/ZenMaxBuilder/etc/user.cfg
    vi ~/ZenMaxBuilder/etc/user.cfg

Start ZMB and follow instructions :

    zmb --start

## Options

    Usage: zmb [OPTION] [ARGUMENT] (e.g. zmb --info zenfone pro)

    Options
        -h, --help                      show this message and exit
        -s, --start                     start new kernel compilation
        -u, --update                    update script and toolchains
        -v, --version                   show toolchains versions
        -l, --list                      show list of your kernels
        -t, --tag          [v4.19]      show the latest Linux tag
        -i, --info        [device]      mobile device specifications
        -m, --msg        [message]      send message on Telegram
        -f, --file          [file]      send file on Telegram
        -z, --zip          [image]      create new kernel zip
        -p, --patch                     apply a patch to a kernel
        -r, --revert                    revert a patch to a kernel
        -d, --debug                     start compilation in debug mode

## Working Structure

    ZenMaxBuilder/
    |
    |---- builds/               # Flashable kernel zips
    |     |---- DEVICE1/
    |     |---- DEVICE2/
    |
    |---- logs/                 # Compilation build logs
    |     |---- DEVICE1/
    |     |---- DEVICE2/
    |
    |---- out/                  # Kernel working directories
    |     |---- DEVICE1/
    |     |---- DEVICE2/

## Toolchains

ZMB uses prebuilt toolchains by default (built on x86-64 `interpreter: lib64/ld-linux-x86-64.so.2`).

In case you need others or have already compiled/downloaded some, just move them to the `toolchains` folder and name them `aosp-clang` for example (see [settings.cfg](https://github.com/grm34/ZenMaxBuilder/blob/zmb/etc/settings.cfg)).

- [AOSP-Clang](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/) `Android Clang/LLVM Prebuilts by Google`
- [Binutils](https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/) `Android GCC/LLVM Prebuilts by Google`
- [Eva-GCC](https://github.com/mvaisakh/gcc-build) `Bleeding Edge GCC Prebuilts by mvaisakh`
- [Neutron-Clang](https://gitlab.com/dakkshesh07/neutron-clang) `Bleeding Edge LLVM Prebuilts by dakkshesh07`
- [Proton-Clang](https://github.com/kdrag0n/proton-clang) `Android Clang/LLVM Prebuilts by kdrag0n`
- [Lineage-GCC](https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9) `Android GCC Prebuilts by LineageOS`
- Proton-GCC `Proton-Clang vs Eva-GCC`
- Neutron-GCC `Neutron-Clang vs Eva-GCC`
- Host-Clang `system host Clang/LLVM`

## Screenshots

<details>
  <summary>Clic to expand</summary>

  ![screenshot](https://raw.githubusercontent.com/grm34/ZenMaxBuilder/zmb/docs/assets/images/screenshot.png)
  ![help](https://raw.githubusercontent.com/grm34/ZenMaxBuilder/zmb/docs/assets/images/help.png)
  ![devices](https://raw.githubusercontent.com/grm34/ZenMaxBuilder/zmb/docs/assets/images/devices.png)
  ![telegram](https://raw.githubusercontent.com/grm34/ZenMaxBuilder/zmb/docs/assets/images/telegram.png)
</details>

## More information

ZMB is a tool to facilitate the compilation of the Linux kernel, it does not modify the source, does not adds possible patchset and does not fixes specific drivers or compilation warnings.

The only change made is the addition of the selected toolchain compiler in the main Makefile, all others options from ZMB settings will be passed directly to make as command-line arguments :

    # AOSP-Clang
    CROSS_COMPILE ?= aarch64-linux-android-
    CC             = clang

    # Proton-Clang / Neutron-Clang
    CROSS_COMPILE ?= aarch64-linux-gnu-
    CC             = clang

    # Eva-GCC
    CROSS_COMPILE ?= aarch64-elf-
    CC             = aarch64-elf-gcc

    # Lineage-GCC
    CROSS_COMPILE ?= aarch64-linux-android-
    CC             = aarch64-linux-android-gcc

## Common warnings and errors

- An error occurs while installing a dependency : disable `AUTO_DEPENDENCIES` in `user.cfg` and install them manually.

- `OS not found, some dependencies may be required` : occurs while your package manager cannot be found, you have to intall the dependencies manually (an issue is welcome to add support).

- `invalid kernel directory` : occurs while the `ARCH` option is not matching the selected kernel directory (or while `KERNEL_DIR` is not correctly set), edit `user.cfg` accordingly.

- `your system does not support this prebuilt of` : occurs while the included prebuilt toolchains are not compatible with your system, you can disable `HOST_LINKER` in `user.cfg` but the build will fail in most cases. System compatible toolchains are required or you can try host compiler option.

- `CROSS_COMPILE not found in Makefile` : occurs while your source is configured to pass `CROSS_COMPILE` to `make` as command-line argument. You can ignore this warning except if you deactivated `MAKE_CMD_ARGS`.

- `CROSS_COMPILE may not be set correctly in Makefile` : occurs while another compiler is defined in the main `Makefile`. You can ignore this warning and answer `yes` while ZMB asking to set it up for you.

- `failed to add toolchain bin to the PATH` : occurs while the `PATH` is not correctly set, please open an issue.

- An error occurs while getting the kernel version : in most cases your source is not configured to be built with the selected toolchain compiler. Try another compiler or answer `yes` while purposed and edit your `Makefile` accordingly.

- `kernel version not found` : same as above or issue with your source.

## Reporting Issues

Found a problem? Want a new feature? Have a question? First of all see if your issue, question or idea has [already been reported](https://github.com/grm34/ZenMaxBuilder/issues). If don't, just open a [new clear and descriptive issue](https://github.com/grm34/ZenMaxBuilder/issues/new/choose).

## Contributing

If you want to contribute to ZenMaxBuilder project and make it better, your help is very welcome: [Contributing Guidelines](https://github.com/grm34/ZenMaxBuilder/blob/zmb/.github/CONTRIBUTING.md).

## Help us Translate ZenMaxBuilder

| language | flag | translator | progress |
| :------- | ---: | ---------: | -------: |
| English  |   🇬🇧 |     @grm34 |     100% |
| Spanish  |   🇪🇸 |     @grm34 |     100% |
| French   |   🇫🇷 |     @grm34 |     100% |
| German   |   🇩🇪 |   @0n1cOn3 |     100% |

## License

    MIT License

    Copyright (c) 2021-2022 darkmaster @grm34 Neternels Team

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge,
    publish, distribute, sublicense, and/or sell copies of the Software,
    and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Credits

- Neternels Team: [https://neternels.org](https://neternels.org)
- Proton-Clang: [@kdrag0n](https://github.com/kdrag0n)
- Neutron-Clang: [@dakkshesh07](https://gitlab.com/dakkshesh07)
- Eva-GCC: [@mvaisakh](https://github.com/mvaisakh)
- Lineage-GCC: [@LineageOS](https://github.com/LineageOS)
- AnyKernel3: [@osm0sis](https://github.com/osm0sis)
- ZipSigner: [@osm0sis](https://github.com/osm0sis) [@topjohnwu](https://github.com/topjohnwu)
- Patches: [@Kali-Linux](https://gitlab.com/kalilinux) [@cyberknight777](https://github.com/cyberknight777)

### Buy me a beer ?

    LTC: MHjiEKDw7SAtx6HzSeFEWTfEUiVUak2wUD
    BTC: 356URzmeVn8AF8WxMtqipP2qQ3gwZQHdRi
    BCH: 1MrG2pNek2v1nM2JShjW6gnxvS9sdxaytw
    DOGE: DEMJp1QLze6n76h2f4KH6a55UBETuZHdMp
    GTC: 0x349319b09D93EE3576F99622fDEE1388f42a82B0
    ETH: 0x445bd5EF7f36CF09135F23dd9E85B8De9fab2199
