# cmdline
Various command line scripts, mainly for daily use of git-bash or bash

## Usage

For instance in a .bashrc (msys/git-bash, linux or mac):
```shell
source ~/cmdline/source-core.sh
source ~/cmdline/source-io.sh
source ~/cmdline/source-git.sh
source ~/cmdline/source-dev.sh

echo-eval enable_native_symlinks
echo-eval setup_history
export PROMPT_COMMAND='setprompt'

echo-eval use_perl
echo-eval use_nvm
```
