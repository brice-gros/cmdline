#!/usr/bin/sh
# expected to be sourced 

## git helpers
# Note that most of this git related function could be register into git config
# for instance:
# - git_checkout_submodule_included:
# git config --global alias.checkout-submodule-included '!f(){ git checkout "$@" && git submodule update --recursive; }; f'
# - git_graph
# git config --global alias.graph log --graph --decorate

# Clone a repository without checkout and create an empty branch checkout as detached HEAD (https://stackoverflow.com/a/54408181)
# so `git worktree add` can be used to safely checkout branches as subfolders
git_clone_for_worktree() {
    url=$1
    target=$(basename $1 .git)
    git clone --no-checkout $url $target
    pushd $target
    git checkout $(git commit-tree $(git hash-object -t tree /dev/null) < /dev/null)
    popd
}

# Allows to run a command on all worktree subfolders
# executing `git worktrees status` will execute git status on all worktree subfolders
# note that passing quoted arguments requires double quoting such as `git worktrees config --add alias.test "'plip plop'"`
# See https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit for color code usage
git_worktrees() {
  if [ $# != 0 ]; then
    find . -type f -name .git -exec bash -c "echo -e '\n\\033[1;33m========\n==' \$(basename \$(dirname {})) && git -C \$(dirname {}) $1 $2 $3 $4 $5 $6 $7 $8 $9" \;
  else
    echo "Usage: git worktrees <command>"
  fi
}

# Prune not-ahead local branches whose remote branch was removed
# i.e. to be used after `git remote prune origin` or `git fetch -p`
# use -D instead of -d to force remove if branch contains changes
git_local_prune() {
  local delete_args="-d"
  if [ $# != 0 ]; then
  delete_args=$@
  fi
  echo_eval "git branch -vv --color=never | grep -F --color=never ': gone]' | grep --color=never -oE '^[\*[:space:]]*[^[:space:]]+' | grep --color=never -oE '[^\*]*' | xargs -r git branch $delete_args"
}

git_current_branch() {
  echo_eval "git rev-parse --abbrev-ref HEAD"
}

git_branch_info() {
  echo_eval "git branch -vv --no-color | grep [[:space:]]$(git rev-parse --abbrev-ref HEAD)[[:space:]]"
}

git_hash() {
  echo_eval "git log -1 --format=%H $@"
}

git_fetch_prune_all() {
  echo_eval "git fetch -p"  
  
  local delete_args="-d"
  if [ $# != 0 ]; then
  delete_args=$@
  fi
  git_local_prune $delete_args
}

remove_quotes() {
  echo $@ | sed -e 's/^"//'  -e 's/"$//'
}

git_diff_ui() {
  for f in "$@" 
  do
    n=$(remove_quotes $f)
    git difftool -y "$n" &
  done
}

git_diff_ui_head() {
  for f in "$@"
  do 
    n=$(remove_quotes $f)
    git difftool -y "$n" &
  done
}

git_status_modified_only() {
  git status --porcelain | grep -E "^ M" | cut -c4-
}

git_status_staged_only() {
  git status --porcelain | grep -E "^M " | cut -c4-
}

git_status_staged_modified() {
  git status --porcelain | grep -E "^MM" | cut -c4-
}

git_diff_ui_uncommitted() {
  IFS_orig=$IFS
  IFS=$'\n'
  git-diff-ui-head $(git-status-modified-only) $(git-status-staged-only) $(git-status-staged-modified)
  IFS=$IFS_orig
}

git_rename_branch_remote_n_local() {
  if [ $# !=  2 ]; then
    echo Usage:   git-rename-branch-remote-n-local old_branch_name new_branch_name
    return
  fi
  echo -ne "Going to remotely and locally rename branch (1) as (2):\n(1)\t$1\n(2)\t$2\nAre you sure [y]?"
  read -s -n 1 is_sure
  if [ "$is_sure" != "y" ]; then 
    return
  fi
  echo
  echo_eval "git branch -m $1 $2"
  echo_eval "git push origin $2"
  echo_eval "git push origin :$1"
}

git_unapply_index() {
    echo_eval git diff --no-color --staged | $(which git) apply --reverse # using which git since git alias doesn't play well with pipes
}

git_revert_workdir_all() {
    echo_eval git stash save --include-untracked --keep-index
    echo_eval git stash drop
    git-unapply-index
}

git_revert_workdir_keep_untrack() {
    echo_eval git checkout .
  git-unapply-index
}

git_show_files_only() {
  echo_eval git show --name-only --pretty="format:" $@
}

git_fetch_submodule_included() {
  echo_eval "git fetch --recurse-submodules $@"
}


git_pull_submodule_included() {
  echo_eval "git pull $@ && git submodule update --recursive"
}

git_checkout_submodule_included() {
  echo_eval "git checkout $@ && git submodule update --recursive"
}

git_log_plain() {
  echo "http://stackoverflow.com/a/5720575" 
}

git_graph() {
  echo_eval git log --graph --decorate $@
}

git_chmod_staged() {
  # set permissions to staged files (http://stackoverflow.com/a/21694391)
  # usage:  git-chmod-staged u+x file.sh file2.py
  echo_eval git update-index --chmod=$@
}

git_ls_staged() {
  # see permissions of staged files (http://stackoverflow.com/a/21694391)
  # usage:  git-ls-staged file.sh file2.py
  echo_eval git ls-files --stage $@
}

git_describe() {
  # gives: <latestTag>[-commitCount-gGitShortHash][-dirty]
  git describe --tags --always --dirty="-dirty"
}

git_rewrite_branch_users() {
  if test -z "$1" || test -z "$2"  ; then
    echo "Usage: git_rewrite_branch_users <User name> <User email>"
    return 1
  fi
  read -n 1 -p "YOU ARE GOING TO REWRITE THE HISTORY OF THE BRANCH WITH AUTHOR AND COMMITER: '$1 <$2>'. Continue? Y/N :  " answeredinput
  if test "$answeredinput" = "Y" ; then
    git filter-branch -f --env-filter "
      GIT_AUTHOR_NAME='$1'
      GIT_AUTHOR_EMAIL='$2'
      GIT_COMMITTER_NAME='$1'
      GIT_COMMITTER_EMAIL='$2'
    " HEAD
  fi
}

is_git_root() {
  if is_windows_system ; then
    pwd_physical_native=$(pwd -W)
  else
    pwd_physical_native=$(pwd -P)
  fi
  if test "$pwd_physical_native" = "$(git rev-parse --show-toplevel)" ; then
    return 0
  else
    return 1
  fi
}

is_git_submodule() {
    # Find the root of this git repo, then check if its parent dir is also a repo
    1>/dev/null pushd $1 || return 1
    if is_git_root ; then
      1>/dev/null cd .. || popd || return 1
      if is_git_root ; then
        1>/dev/null popd || return 1
        return 0
      fi
    fi
    1>/dev/null popd || return 1
}

is_git_root() {
  if is_windows_system ; then
    pwd_physical_native=$(pwd -W)
  else
    pwd_physical_native=$(pwd -P)
  fi
  if test "$pwd_physical_native" = "$(git rev-parse --show-toplevel)" ; then
    return 0
  else
    return 1
  fi
}

git_submodule_rm() {
  if ! test -d "$1" ; then
    echo "Usage: git_submodule_rm <path>"
    return 1
  fi

  if ! is_git_root ; then
    echo "Not running from the root of the working tree."
    return 1
  fi
  
  if ! is_git_submodule "$1" ; then
    echo "Not a direct submodule (no recursion)"
    return 1
  fi

  echo "Removing submodule"
  # using ${1%/} to remove trailing slashes
  git config -f .gitmodules --remove-section submodule.${1%/}
  git config -f .git/config --remove-section submodule.${1%/}
  git rm --cached ${1%/}
  return 0
}

git_daemon_subfolders() {
    # TODO test this command

    # From http://git-scm.com/book/en/Git-on-the-Server-Git-Daemon)
    # For all repositories you want to be able to push into, do the following command only the first time.
    # __Note__ you'll need to do a 'reset hard' once back to the remote office desktop 
    # (which will actually be the local office desktop) in order to see the changes in the working directory.
    # Uncommitted/Unstaged changes in the working directory on the local office desktop 
    # will be staged when the commits from the laptop are pushed.
    # Not doing the reset hard won't apply the changes made to the branch from the laptop, so you are at risk to overwrite these changes.
    # The same applies if you commit the 'uncommitted/unstaged' staged changes.
    # Good news, both versions will be in the history. Bad news, rollback will be needed.
    for repo in "$@" ; do
      git config --file $repo/.git/config receive.denyCurrentBranch warn
    done
    # run git daemon with : 
    # --base-path=. to limit the server to subfolders
    # --export-all to pull from all underlying repo
    # --enable=receive-pack to allow to push
    git daemon --reuseaddr --base-path=. --export-all --verbose --enable=receive-pack

    for repo in "$@" ; do
      git config --file $repo/.git/config receive.denyCurrentBranch warn
    done
}

alias git-plog="git log --pretty=format:'%C(yellow)%h %C(white)%b %C(green)<%an>%n        %C(cyan)^^^^ %s' -20"
alias git-prlog="git-plog --first-parent"

# Utility to create git aliases for all git functions in this file
_update_git_alias() {
  if [ $# == 0 ]; then
    if test -e ~/cmdline/.gitconfig ; then
      aliasto=~/cmdline/.gitconfig
    fi
  else
    aliasto=$1
  fi

  # if aliasto is not set leave the function
  if test -z "$aliasto" ; then
    echo "Usage: _update_git_alias [path_to_gitconfig=~/cmdline/.gitconfig]"
  else
    for fname in $(declare -F | grep -oE ' git_[a-z0-9_]+$') ; do
      gitname=$(echo $fname | cut -d "_" -f 2- | cut -d "_" -f 1- | sed s/_/-/g)
      git config --file $aliasto alias.$gitname '!f() { bash -c "source ~/cmdline/source-core.sh ; source ~/cmdline/source-git.sh ; '$fname' $@ " ; }; f'
    done
  fi
}
