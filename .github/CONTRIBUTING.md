# 🆉🅴🅽🅼🅰🆇🅱🆄🅸🅻🅳🅴🆁 📲

## Contributing

If you want to contribute to ZenMaxBuilder (ZMB) project and make it better, your help is very welcome.

### Important

ZenMaxBuilder being translated into several languages, all translations are assigned as variables from a CFG file. You don't have to worry about the different translations, just add your variables in `lang/en.cfg` (which is the main language file) and run the dedicated script that will translate and add the new variables in the different translation files.

    bash src/translate.sh

In case you'll add some language strings, please respect naming convention :

    # Note:      MSG_NOTE_*
    # Warning:   MSG_WARN_*
    # Error:     MSG_ERR_*
    # ...

### How to make a clean pull request

- Create a personal fork of the project on Github.
- Clone the fork on your local machine.
- Add the original repository as a remote called `upstream`.
- If you created your fork a while ago be sure to pull `upstream` changes into it.
- Create a new branch to work on!
- Implement/fix your feature, comment your code.
- Follow the code style of the project, including indentation.
- Push your branch to your fork on Github, the remote `origin`.
- From your fork open a pull request in the correct branch.
- Target the project's `zmb` branch!
- Further changes are requested so just push them to your branch.
- Once the pull request is approved and merged you can pull the changes
  from `upstream` to your local repo and delete your extra branch(es).

### Help us translate ZenMaxBuilder

If you know another language and are willing to help translate ZMB, here are the steps to get started:

- Follow pull request guidelines as described above.
- Create a new file for your language in `lang` folder.
- Name this file with the code of your language.

`MANUAL TRANSLATION`
- Copy all the content of `lang/en.cfg` into it.
- Implement your translations. \*
- Create a new pull request to submit your language.

`AUTO TRANSLATION`
- run `bash src/translate.sh`
- Check for errors/typo. \*
- Create a new pull request to submit your language.

\* ZMB being launched from a terminal, please respect line length (max 72).

| language | flag | translator | progress |
| :------- | ---: | ---------: | -------: |
| English  |   🇬🇧 |     @grm34 |     100% |
| Spanish  |   🇪🇸 |     @grm34 |     100% |
| French   |   🇫🇷 |     @grm34 |     100% |
| German   |   🇩🇪 |   @0n1cOn3 |     100% |

