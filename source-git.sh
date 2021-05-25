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

# Prune not-ahead local branches whose remote branch was removed
# i.e. to be used after `git remote prune origin` or `git fetch -p`
# use -D instead of -d to force remove if branch contains changes
git_local_prune() {
  local delete_args="-d"
  if [ $# != 0 ]; then
  delete_args=$@
  fi
  echo-eval "git branch -vv --color=never | grep -F --color=never ': gone]' | grep --color=never -oE '^[\*[:space:]]*[^[:space:]]+' | grep --color=never -oE '[^\*]*' | xargs --no-run-if-empty git branch $delete_args"
}

git_current_branch() {
  echo-eval "git rev-parse --abbrev-ref HEAD"
}

git_branch() {
  echo-eval "git branch -vv --no-color | grep [[:space:]]$(git rev-parse --abbrev-ref HEAD)[[:space:]]"
}

git_hash() {
  echo-eval "git log -1 --format=%H $@"
}

git_fetch_prune_all() {
  echo-eval "git fetch -p"  
  
  local delete_args="-d"
  if [ $# != 0 ]; then
  delete_args=$@
  fi
  git-local-prune $delete_args
}

remove_quotes() {
  echo $@ | sed -e 's/^"//'  -e 's/"$//'
}

git_diff_ui() {
  for f in "$@" 
  do
    n=$(remove-quotes $f)
    git difftool -y "$n" &
  done
}

git_diff_ui_head() {
  for f in "$@"
  do 
    n=$(remove-quotes $f)
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
  echo-eval "git branch -m $1 $2"
  echo-eval "git push origin $2"
  echo-eval "git push origin :$1"
}

git_unapply_index() {
    echo-eval git diff --no-color --staged | $(which git) apply --reverse # using which git since git alias doesn't play well with pipes
}

git_revert_workdir_all() {
    echo-eval git stash save --include-untracked --keep-index
    echo-eval git stash drop
    git-unapply-index
}

git_revert_workdir_keep_untrack() {
    echo-eval git checkout .
  git-unapply-index
}

git_show_files_only() {
  echo-eval git show --name-only --pretty="format:" $@
}

git_fetch_submodule_included() {
  echo-eval "git fetch --recurse-submodules $@"
}


git_pull_submodule_included() {
  echo-eval "git pull $@ && git submodule update --recursive"
}

git_checkout_submodule_included() {
  echo-eval "git checkout $@ && git submodule update --recursive"
}

git_log_plain() {
  echo "http://stackoverflow.com/a/5720575" 
}

git_graph() {
  echo-eval git log --graph --decorate $@
}

git_chmod_staged() {
  # set permissions to staged files (http://stackoverflow.com/a/21694391)
  # usage:  git-chmod-staged u+x file.sh file2.py
  echo-eval git update-index --chmod=$@
}

git_ls_staged() {
  # see permissions of staged files (http://stackoverflow.com/a/21694391)
  # usage:  git-ls-staged file.sh file2.py
  echo-eval git ls-files --stage $@
}

git_describe() {
  # gives: <latestTag>[-commitCount-gGitShortHash][-dirty]
  git describe --tags --always --dirty="-dirty"
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
