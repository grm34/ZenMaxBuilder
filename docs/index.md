---
{ % seo % }
---

# 🆉🅴🅽🅼🅰🆇🅱🆄🅸🅻🅳🅴🆁 📲

<img src="https://api.codiga.io/project/23638/score/svg" alt="Codescore"><img src="https://api.codiga.io/project/23638/status/svg" alt="Codequality"><img src="https://www.codefactor.io/repository/github/grm34/zenmaxbuilder/badge" alt="Codefactor"><img src="https://img.shields.io/github/forks/grm34/ZenMaxBuilder.svg?logo=github" alt="Forks"><img src="https://img.shields.io/github/stars/grm34/ZenMaxBuilder.svg?logo=github-sponsors" alt="Stars">
<br>
<img src="https://img.shields.io/badge/license-MIT-blue.svg?logo=keepassxc" alt="License: MIT"><img src="https://img.shields.io/github/issues/grm34/ZenMaxBuilder.svg?logo=git" alt="Issues"><img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/y/grm34/zenmaxbuilder?label=commits&logo=github"><img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/grm34/ZenMaxBuilder?style=flat-square&logo=Github">

<br>
## Table of Contents

- [Overview](https://kernel-builder.com#overview)
- [Requirements](https://kernel-builder.com#requirements)
- [Usage](https://kernel-builder.com#usage)
- [Options](https://kernel-builder.com#options)
- [Working Structure](https://kernel-builder.com#working-structure)
- [Toolchains](https://kernel-builder.com#toolchains)
- [Screenshots](https://kernel-builder.com#screenshots)
- [Warning](https://kernel-builder.com#warning)
- [Reporting Issues](https://kernel-builder.com#reporting-issues)
- [Contributing](https://kernel-builder.com#contributing)
- [Help us Translate ZenMaxBuilder](https://kernel-builder.com#help-us-translate-zenmaxbuilder)
- [License](https://kernel-builder.com#license)
- [Credits](https://kernel-builder.com#credits)

<br>
## Overview

ZenMaxBuilder (ZMB) is an Android Kernel Builder written in Bash, which can be launched on any compatible Linux system (feel free to Pull Request for Windows support). By default it uses AOSP-Clang, Eva-GCC, Proton-Clang or Lineage-GCC but you can use any Clang or GCC toolchain you like (with LLVM and binutils included).

Find all your compilations and working folders in one place, update and maintain your kernels faster. Full logs with the possibility to restart the build after error. Automatic creation of a flashable signed ZIP (with AK3 and AOSP Keys). Real time status feedback with build sending on any group or Telegram channel. And more. The perfect tool to compile on the fly and keep fresh and clean kernel paths.

<br>
## Requirements

- A compatible Linux system
- The kernel source code of your device
- A minimum of knowledge in kernel compilation
- Patience

The installation of the missing dependencies will be offered by ZenMaxBuilder but you can also install them manually with your favorite package manager:

    bash sed wget git curl zip tar expect make cmake automake autoconf llvm lld lldb clang gcc binutils bison perl gperf gawk flex bc python3 zstd openssl

The optional flashable zip signature with AOSP Keys requires java (JDK) which is not proposed to install by ZenMaxBuilder (openjdk recommended).

<br>
## Usage

Clone and enter ZMB repository

    git clone https://github.com/grm34/ZenMaxBuilder;
    cd ZenMaxBuilder

Create a copy of [settings.cfg](https://github.com/grm34/ZenMaxBuilder/blob/zmb/etc/settings.cfg) to set your settings (optional)

    cp etc/settings.cfg etc/user.cfg;
    vi etc/user.cfg

Start ZMB and follow instructions

    bash zmb --start

<br>
## Options

    Usage: bash zmb [OPTION] [ARGUMENT] (e.g. bash zmb --start)

    Options
        -h, --help                      show this message and exit
        -s, --start                     start new kernel compilation
        -u, --update                    update script and toolchains
        -v, --version                   show toolchains versions
        -l, --list                      show list of your kernels
        -t, --tag            [v4.19]    show the latest Linux tag
        -m, --msg          [message]    send message on Telegram
        -f, --file            [file]    send file on Telegram
        -z, --zip     [Image.gz-dtb]    create flashable zip
        -p, --patch                     apply a patch to a kernel
        -r, --revert                    revert a patch to a kernel
        -d, --debug                     start compilation in debug mode

<br>
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

<br>
## Toolchains

- [AOSP-Clang](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/) `Android Clang/LLVM Prebuilts by Google`
- [Binutils](https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/) `Android GCC/LLVM Prebuilts by Google`
- [Eva-GCC](https://github.com/mvaisakh/gcc-build) `Bleeding Edge Bare Metal GCC Prebuilts by mvaisakh`
- [Proton-Clang](https://github.com/kdrag0n/proton-clang) `Android Clang/LLVM Prebuilts by kdrag0n`
- [Lineage-GCC](https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9) `Android GCC Prebuilts by LineageOS`
- Proton-GCC `Proton-Clang vs Eva-GCC`
- Host-Clang `system host clang`

<br>
## Screenshots

<details>
  <summary>Clic to expand</summary>
  <p><img alt="screenshot" src="https://raw.githubusercontent.com/grm34/ZenMaxBuilder/zmb/docs/assets/images/screenshot.png"></p>
  <p><img alt="help" src="https://raw.githubusercontent.com/grm34/ZenMaxBuilder/zmb/docs/assets/images/help.png"></p>
  <p><img alt="telegram" src="https://raw.githubusercontent.com/grm34/ZenMaxBuilder/zmb/docs/assets/images/telegram.jpg"></p>
</details>

<br>
## Warning

ZMB is a tool to facilitate the compilation of an Android kernel, it does not modify the source, does not adds possible patchset and does not fixes specific drivers or compilation warnings.

The only change made is the addition of the selected toolchain compiler in the main Makefile, all others options from ZMB settings will be passed directly to make as command-line argument:

    # Proton-Clang / Proton-GCC
    CROSS_COMPILE ?= aarch64-linux-gnu-
    CC             = clang

    # Eva-GCC
    CROSS_COMPILE ?= aarch64-elf-
    CC             = aarch64-elf-gcc

    # Lineage-GCC
    CROSS_COMPILE ?= aarch64-linux-android-
    CC             = aarch64-linux-android-gcc

<br>
## Reporting Issues

Found a problem? Want a new feature? Have a question? First of all see if your issue, question or idea has [already been reported](https://github.com/grm34/ZenMaxBuilder/issues). If don't, just open a [new clear and descriptive issue](https://github.com/grm34/ZenMaxBuilder/issues/new/choose).

<br>
## Contributing

If you want to contribute to ZenMaxBuilder project and make it better, your help is very welcome: [Contributing Guidelines](https://github.com/grm34/ZenMaxBuilder/blob/zmb/.github/CONTRIBUTING.md).

<br>
## Help us Translate ZenMaxBuilder

| language | flag | translator | progress |
| :------- | ---: | ---------: | -------: |
| English  |   🇬🇧 |     @grm34 |     100% |
| Spanish  |   🇪🇸 |     @grm34 |     100% |
| French   |   🇫🇷 |     @grm34 |     100% |
| German   |   🇩🇪 |    @Besix2 |     100% |

<br>
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

<br>
## Credits

- Neternels Team: [https://neternels.org](https://neternels.org)
- Proton-Clang: [@kdrag0n](https://github.com/kdrag0n)
- Eva-GCC: [@mvaisakh](https://github.com/mvaisakh)
- Lineage-GCC: [@LineageOS](https://github.com/LineageOS)
- AnyKernel3: [@osm0sis](https://github.com/osm0sis)
- ZipSigner: [@osm0sis](https://github.com/osm0sis) [@topjohnwu](https://github.com/topjohnwu)
- Patches: [@Kali-Linux](https://gitlab.com/kalilinux) [@cyberknight777](https://github.com/cyberknight777)

<br>
### Buy me a beer ?

    LTC: MHjiEKDw7SAtx6HzSeFEWTfEUiVUak2wUD
    BTC: 356URzmeVn8AF8WxMtqipP2qQ3gwZQHdRi
    BCH: 1MrG2pNek2v1nM2JShjW6gnxvS9sdxaytw
    DOGE: DEMJp1QLze6n76h2f4KH6a55UBETuZHdMp
    GTC: 0x349319b09D93EE3576F99622fDEE1388f42a82B0
    ETH: 0x445bd5EF7f36CF09135F23dd9E85B8De9fab2199
