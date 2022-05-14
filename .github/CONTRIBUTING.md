<a href="https://kernel-builder.com" target="blank\_">
<img height="100" alt="ZenMaxBuilder" src="https://raw.githubusercontent.com/grm34/ZenMaxBuilder/zmb/docs/assets/images/zmb.png" />
</a>
<br>

# Thank you for taking the time to contribute to ZMB ♥

## Contributing

If you want to contribute to ZenMaxBuilder project and make it better, your help is very welcome. Contributing is also a great way to learn more about social coding on Github, new technologies and their ecosystems and how to make constructive, helpful bug reports, feature requests and the noblest of all contributions: a good, clean pull request.

ZMB has been coded largely on a smartphone, so the length of the lines is greatly reduced for better visibility to ensure the best support and maintenance.

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
| settings.cfg    | etc  |   text   |         user settings |
| excluded.cfg    | etc  |   text   | vars to exclude (LOG) |
| zipsigner.jar   | bin  |   java   |  AOSP Keys Zip Signer |

## Reporting Issues

Found a problem? Want a new feature? Have a question? First of all see if your issue, question or idea has [already been reported](https://github.com/grm34/ZenMaxBuilder/issues). If don't, just open a [new clear and descriptive issue](https://github.com/grm34/ZenMaxBuilder/issues/new/choose).

## Help us translate ZenMaxBuilder

If you know another language and are willing to help translate ZMB, here are the steps to get started:

- Follow pull request guidelines as described below.
- Create a new file for your language in `lang` folder.
- Name this file with the code of your language.
- Copy all the content of `lang/en.cfg` in to it.
- Implement your translations\*
- Create a new pull request to submit your language.

\* ZMB being launched from a terminal, please try to respect the length of the lines (max 70).

| language | flag | translator | progress |
| :------- | ---: | ---------: | -------: |
| English  |   🇬🇧 |     @grm34 |     100% |
| Spanish  |   🇪🇸 |     @grm34 |     100% |
| French   |   🇫🇷 |     @grm34 |     100% |
| German   |   🇩🇪 |    @Besix2 |     100% |

## How to make a clean pull request

- Create a personal fork of the project on Github.
- Clone the fork on your local machine. Your remote repo on Github is called `origin`.
- Add the original repository as a remote called `upstream`.
- If you created your fork a while ago be sure to pull `upstream` changes into it.
- Create a new branch to work on!
- Implement/fix your feature, comment your code.
- Follow the code style of the project, including indentation.
- Squash your commits into a single commit with git's [interactive rebase](https://help.github.com/en/github/using-git/about-git-rebase).
- Push your branch to your fork on Github, the remote `origin`.
- From your fork open a pull request in the correct branch.
  Target the project's `dev` branch!
- Further changes are requested so just push them to your branch.
- Once the pull request is approved and merged you can pull the changes
  from `upstream` to your local repo and delete your extra branch(es).

And last but not least: `Always write your commit messages in the present tense` Your commit message should describe what the commit, when applied, does to the code – not what you did to the code.
