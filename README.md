# Android Kernel Builder

![Proton-Clang](https://img.shields.io/badge/Proton--Clang-⛓-yellow)
![Eva-GCC](https://img.shields.io/badge/Eva--GCC-⛓-blue)
![Proton-GCC](https://img.shields.io/badge/Proton--GCC-⛓-red)

![codequality](https://api.codiga.io/project/23638/score/svg)
![codescore](https://api.codiga.io/project/23638/status/svg)
![codefactor](https://www.codefactor.io/repository/github/grm34/neternels-builder/badge)

Neternels-Builder is an Android Kernel Builder written in bash, which can be runned on any Linux System (feel free to Pull Request for Windows support). By default it uses Proton-Clang, Eva-GCC or Proton-GCC but you can use any toolchains you like by editing [config.sh](https://github.com/grm34/Neternels-Builder/blob/main/config.sh) file. The perfect tool to compile on the fly and keep fresh and clean kernel paths.

## Requirements

Dependencies will be prompted to install or you can manually install them.

    bash git zip llvm lld clang expect openjdk (java)

## Usage

1. `git clone https://github.com/grm34/Neternels-Builder.git`
2. `cd Neternels-Builder`
3. Edit [config.sh](https://github.com/grm34/Neternels-Builder/blob/main/config.sh) to set your settings (optional)
4. ` bash Neternels-Builder`

## Options

    Usage: bash Neternels-Builder [OPTION] [ARGUMENT]

    Options
        -h, --help                     show this message and exit
        -u, --update                   update script and toolchains
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

## Staying Up-To-Date

1. Fork Neternels-Builder repo on GitHub
2. `git clone https://github.com/<yourname>/Neternels-Builder`
3. `git remote add upstream https://github.com/grm34/Neternels-Builder`
4. `git checkout -b <devicename>`
5. Set up your <devicename> [config.sh](https://github.com/grm34/Neternels-Builder/blob/main/config.sh) then commit those changes
6. `git push --set-upstream origin <devicename>`
7. `git checkout main` then repeat steps 4-6 for any other devices you support

Then you should be able to `git pull upstream main` from your main branch and either merge or cherry-pick the new Neternels-Builder commits into your device branches as needed.

##  Credits

* Neternels Team: [https://neternels.org](https://neternels.org)
* Proton-Clang: [@kdrag0n](https://github.com/kdrag0n)
* Eva-GCC: [@mvaisakh](https://github.com/mvaisakh)
* AnyKernel3: [@osm0sis](https://github.com/osm0sis)

## Links

* Codiga Code Review: [link](https://app.codiga.io/public/project/23638/Neternels-Builder/dashboard)
* Codefactor Code Review: [link](https://www.codefactor.io/repository/github/grm34/neternels-builder)
* Website: [https://kernel-builder.com](https://kernel-builder.com)
