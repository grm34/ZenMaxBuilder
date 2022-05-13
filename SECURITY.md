<a href="https://kernel-builder.com" target="blank\_">
<img height="100" alt="ZenMaxBuilder" src="https://raw.githubusercontent.com/grm34/ZenMaxBuilder/zmb/docs/assets/images/zmb.png" />
</a>
<br>

# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :x:                |
| 2.x     | :white_check_mark: |

| Branch  | Supported             |
| ------- | --------------------- |
| zmb     | :white_check_mark:    |
| dev     | :x:                   |
| testing | :construction_worker: |

## Reporting a Vulnerability

Please open an issue: [Bug Report Section](https://github.com/grm34/ZenMaxBuilder/issues/new/choose)

## Statistics

ZMB has been coded largely on a smartphone, so the length of the lines is greatly reduced for better visibility to ensure the best support and maintenance, which explains such a large number of lines.

| File            | path | language |                 about |
| :-------------- | :--: | :------: | --------------------: |
| main.sh         | src  |   bash   |          main process |
| manager.sh      | src  |   bash   |      global functions |
| options.sh      | src  |   bash   |  command line options |
| requirements.sh | src  |   bash   |  install requirements |
| questioner.sh   | src  |   bash   | questions to the user |
| maker.sh        | src  |   bash   |     make kernel build |
| zip.sh          | src  |   bash   |  create flashable zip |
| telegram.sh     | src  |   bash   |     Telegram feedback |

| File            |    blank |  comment |     code |
| :-------------- | -------: | -------: | -------: |
| main.sh         |       27 |       54 |      189 |
| questioner.sh   |       36 |       71 |      183 |
| manager.sh      |       32 |       80 |      178 |
| maker.sh        |       26 |       63 |      137 |
| options.sh      |       21 |       54 |      118 |
| requirements.sh |       11 |       38 |       90 |
| telegram.sh     |       23 |       42 |       77 |
| zip.sh          |       14 |       47 |       57 |
| --------        | -------- | -------- | -------- |
| SUM:            |      190 |      449 |     1029 |
