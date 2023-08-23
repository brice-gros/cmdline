# cmdline
Various command line scripts, mainly for daily use of git-bash or bash

## Usage

For instance in a .bashrc (msys/git-bash, linux or mac):
```shell
source ~/cmdline/source-core.sh
source ~/cmdline/source-io.sh
source ~/cmdline/source-git.sh
source ~/cmdline/source-dev.sh

echo_eval enable_native_symlinks
echo_eval setup_history
export PROMPT_COMMAND='setprompt'

echo_eval local_setup
echo_eval setup_git_alias
echo_eval use_perl
echo_eval use_nvm
echo_eval use_default_python 310
echo_eval use_pipenv_in_project
echo_eval list_hardware_ip
```
