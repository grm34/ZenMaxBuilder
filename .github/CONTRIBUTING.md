# 🆉🅴🅽🅼🅰🆇🅱🆄🅸🅻🅳🅴🆁 📲

## Contributing

If you want to contribute to ZenMaxBuilder (ZMB) project and make it better, your help is very welcome.

### Help us translate ZenMaxBuilder

If you know another language and are willing to help translate ZMB, here are the steps to get started:

- Follow pull request guidelines as described below.
- Create a new file for your language in `lang` folder.
- Name this file with the code of your language.
- Copy all the content of `lang/en.cfg` in to it.
- Implement your translations\*
- Create a new pull request to submit your language.

\* ZMB being launched from a terminal, please respect line length (max 72).

| language | flag | translator | progress |
| :------- | ---: | ---------: | -------: |
| English  |   🇬🇧 |     @grm34 |     100% |
| Spanish  |   🇪🇸 |     @grm34 |     100% |
| French   |   🇫🇷 |     @grm34 |     100% |
| German   |   🇩🇪 |   @0n1cOn3 |     100% |

### How to make a clean pull request

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
  Target the project's `zmb` branch!
- Further changes are requested so just push them to your branch.
- Once the pull request is approved and merged you can pull the changes
  from `upstream` to your local repo and delete your extra branch(es).

And last but not least: `Always write your commit messages in the present tense` Your commit message should describe what the commit, when applied, does to the code – not what you did to the code.
