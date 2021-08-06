# cmdline
Various command line scripts, mainly for daily use of git-bash or bash

## Usage

For instance in a .bashrc (msys/git-bash, linux or mac):
```shell
source ~/cmdline/source-core.sh
source ~/cmdline/source-git.sh
enable_native_symlinks
export PROMPT_COMMAND='setprompt'

export HISTCONTROL=ignoreboth # ignoredups,ignoreboth,erasedups,ignorespace
shopt -s histappend
```