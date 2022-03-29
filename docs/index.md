---
{ % seo % }
---

# Neternels Builder

![Proton-Clang](https://img.shields.io/badge/Proton--Clang-⛓-yellow)
![Eva-GCC](https://img.shields.io/badge/Eva--GCC-⛓-blue)
![Proton-GCC](https://img.shields.io/badge/Proton--GCC-⛓-red)

![codequality](https://api.codiga.io/project/23638/score/svg)
![codescore](https://api.codiga.io/project/23638/status/svg)
![codefactor](https://www.codefactor.io/repository/github/grm34/neternels-builder/badge)

## Requirements

Dependencies will be prompted to install or you can manually install them.

    bash git zip llvm lld clang expect openjdk (java)

## Usage

1. `git clone https://github.com/grm34/Neternels-Builder.git`
2. `cd Neternels-Builder`
3. Edit
   [config.sh](https://github.com/grm34/Neternels-Builder/blob/main/config.sh)
   to set your settings (optional)
4. `bash Neternels-Builder --start`

## Options

    Usage: bash Neternels-Builder [OPTION] [ARGUMENT]

    Options
        -h, --help                     show this message and exit
        -s, --start                    start new kernel compilation
        -u, --update                   update script and toolchains
        -l, --list                     show list of your kernels
        -t, --tag     [v4.19]          show the latest Linux tag
        -m, --msg     [message]        send message on Telegram
        -f, --file    [file]           send file on Telegram
        -z, --zip     [Image.gz-dtb]   create flashable zip

## Working structure

    Neternels-Builder/
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

![screenshot](https://raw.githubusercontent.com/grm34/Neternels-Builder/main/docs/assets/images/screenshot.png)

## Credits

- Neternels Team: [https://neternels.org](https://neternels.org)
- Proton-Clang: [@kdrag0n](https://github.com/kdrag0n)
- Eva-GCC: [@mvaisakh](https://github.com/mvaisakh)
- AnyKernel3: [@osm0sis](https://github.com/osm0sis)

## Links

- Source Code: [github](https://github.com/grm34/Neternels-Builder)
- Codiga Code Review:
  [link](https://app.codiga.io/public/project/23638/Neternels-Builder/dashboard)
- Codefactor Code Review:
  [link](https://www.codefactor.io/repository/github/grm34/neternels-builder)
