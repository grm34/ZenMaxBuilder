# Android Kernel Builder

<a href="https://app.codiga.io/public/project/23638/ZenMaxBuilder/dashboard">
<img src="https://api.codiga.io/project/23638/score/svg" alt="Codescore">
</a>

<a href="https://app.codiga.io/public/project/23638/ZenMaxBuilder/dashboard">
<img src="https://api.codiga.io/project/23638/status/svg" alt="Codequality">
</a>

<a href="https://www.codefactor.io/repository/github/grm34/zenmaxbuilder">
<img src="https://www.codefactor.io/repository/github/grm34/zenmaxbuilder/badge" alt="Codefactor">
</a>
<br>

<a href="https://mit-license.org/">
<img src="https://img.shields.io/badge/license-MIT-blue.svg?logo=keepassxc" alt="License: MIT">
</a>

<a href="https://github.com/grm34/ZenMaxBuilder/issues">
<img src="https://img.shields.io/github/issues/grm34/ZenMaxBuilder.svg?logo=git" alt="Issues">
</a>

<a href="https://github.com/grm34/ZenMaxBuilder/fork">
<img src="https://img.shields.io/github/forks/grm34/ZenMaxBuilder.svg?logo=github" alt="Forks">
</a>

<a href="https://github.com/grm34/ZenMaxBuilder/stargazers">
<img src="https://img.shields.io/github/stars/grm34/ZenMaxBuilder.svg?logo=github-sponsors" alt="Stars">
</a>

## About

ZenMaxBuilder (ZMB) is an Android Kernel Builder written in bash, which can be runned on any Linux System (feel free to Pull Request for Windows support). By default it uses Proton-Clang, Eva-GCC or Proton-GCC but you can use any toolchains you like. Find all your compilations and working folders in one place, edit and maintain your kernels faster. Full logs with the possibility to restart the build after error. Automatic creation of a flashable signed ZIP (with AK3 and AOSP Keys). Real time status feedback with ZIP sending on any group or Telegram channel. And more. The perfect tool to compile on the fly and keep fresh and clean kernel paths.

## Requirements

Dependencies will be prompted to install or you can manually install them.

    bash git zip llvm lld clang expect openjdk (java)

## Usage

:arrow_right: Clone and enter ZMB repository

    git clone https://github.com/grm34/ZenMaxBuilder.git
    cd ZenMaxBuilder

:arrow_right: Create a copy of [settings.cfg](https://github.com/grm34/ZenMaxBuilder/blob/zmb/etc/settings.cfg) to set your settings (optional)

    cp etc/settings.cfg etc/user.cfg
    vi etc/user.cfg

:arrow_right: Start ZMB and follow instructions

    bash zmb --start

## Options

    Usage: bash zmb [OPTION] [ARGUMENT] (e.q. bash zmb --start)

    Options
        -h, --help                      show this message and exit
        -s, --start                     start new kernel compilation
        -u, --update                    update script and toolchains
        -l, --list                      show list of your kernels
        -t, --tag            [v4.19]    show the latest Linux tag
        -m, --msg          [message]    send message on Telegram
        -f, --file            [file]    send file on Telegram
        -z, --zip     [Image.gz-dtb]    create flashable zip

## Working structure

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

## Screenshot

![screenshot](https://raw.githubusercontent.com/grm34/ZenMaxBuilder/zmb/docs/assets/images/screenshot.png)

## Warning

ZMB is a tool to facilitate the compilation of the Android kernel, it does not modify the source and does not correct possible modifications that must be made to Makefile. Sources are often configured for a specific compilation (firmware, modules, ...) and little changes are often necessary. For a kernel building support, you can ask for help on [Telegram](https://t.me/ZenMaxBuilder).

## License

    MIT License

    Copyright (c) 2021-2022 @grm34 Neternels Team

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
- Eva-GCC: [@mvaisakh](https://github.com/mvaisakh)
- AnyKernel3: [@osm0sis](https://github.com/osm0sis)

## Links

- Codiga Code Review:
  [link](https://app.codiga.io/public/project/23638/ZenMaxBuilder/dashboard)
- Codefactor Code Review:
  [link](https://www.codefactor.io/repository/github/grm34/zenmaxbuilder)
- Website: [https://kernel-builder.com](https://kernel-builder.com)
