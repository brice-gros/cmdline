#!/usr/bin/sh
# expected to be sourced 


is_cygwin() {
  if echo $(uname) | grep -iq cygwin; then
    return 0
  fi
  return 1
}

is_msys() {
  if echo $(uname) | grep -iqE 'MINGW|MSYS'; then
    return 0
  fi
  return 1
}

is_linux() {
  if echo $(uname) | grep -iq linux; then
    return 0
  fi
  return 1
}

is_darwin() {
  if echo $(uname) | grep -iq darwin; then
    return 0
  fi
  return 1
}


get_system() {
  if is_cygwin ; then
    echo "cygwin"
  elif is_msys ; then
    echo "msys"
  elif is_linux ; then
    echo "linux"
  elif is_darwin ; then
    echo "darwin"
  else
    echo $(uname)
  fi
}

is_windows_system() {
  if is_cygwin ; then
    return 0
  elif is_msys ; then
    return 0
  fi
  return 1
}

# https://unix.stackexchange.com/questions/18212/bash-history-ignoredups-and-erasedups-setting-conflict-with-common-history#18443
setup_history() {
  export HISTCONTROL=ignoreboth # ignoredups,ignoreboth,erasedups,ignorespace
  HISTSIZE=10000                     # custom history size
  HISTFILESIZE=1000000               # custom history file size
  # beware `shopt` is bash specific:
  shopt -s histappend
}

# https://stackoverflow.com/a/29835459
current_script_dir() {
  if [ $# -ne 1 ]; then
    echo 'One argument required, please pass ${BASH_SOURCE[0]} in bash or $0 in a POSIX Shell'
  else
    $( cd "$( dirname "$1")" && pwd )
  fi
}

# https://stackoverflow.com/a/29835459
current_script_real_dir() {
  if [ $# -ne 1 ]; then
    echo 'One argument required, please pass ${BASH_SOURCE[0]} in bash or $0 in a POSIX Shell'
  else
    $( cd "$( dirname $(readlink -f "$1"))" && pwd )
  fi
}

date_time_utc_iso8601() {
  #date  --iso-8601=seconds --utc
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

settitle() {
  echo -ne "\e]0;$1\a"
}

setcoloredprompt() {
  # record last command's return code
  rc=$?

  if ! declare -f __git_ps1 > /dev/null ; then
    # real implementation is: https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
    __git_ps1() {
      branchname=$(git branch --show-current 2> /dev/null)
      if test $? -eq 0 ; then
        echo -n " ($branchname)"
      else
        echo -n ''
      fi
    }
  fi
  
  # git bash default works well with black background:
  # export PS1="\[\033]0;$TITLEPREFIX:$PWD\007\]\n\[\033[32m\]\u@\h \[\033[35m\]$MSYSTEM \[\033[33m\]\w\[\033[36m\]`__git_ps1`\[\033[0m\]\n$ "
  # this one works well with black/grey/white background: (Note that \e == \033 == \x1b)
  systemname=$(uname)
  if is_msys ; then
    systemname=$MSYSTEM
  fi

  export PS1="\n#exitcode:\[\e[31;1m\]$rc\[\e[0m\]\n\[\e[43m\]`date_time_utc_iso8601 |cut -d '+' -f 1`\[\e[0m\]\n\[\e[32m\]\u@\h \[\e[35m\]$systemname \[\e[31m\]\w\[\e[36m\]`__git_ps1`\[\e[0m\]\n$ "
}

settitlepath() {
  # from git bash default originally:
  # export PS1="\[\033]0;$TITLEPREFIX:$PWD\007\]\n$PS1"
  systemname=$(uname)
  if is_msys ; then
    systemname=$MSYSTEM
  fi
  export PS1="\[\e]0;$systemname \u@\h \w\a\]\n$PS1"
}

setprompt() {
  setcoloredprompt
  settitlepath
}

bell() {
  #pure windows : rundll32 user32.dll,MessageBeep
  tput bel
}

say() {
  # https://stackoverflow.com/a/39647762
  if is_darwin ; then
    say $@
  elif is_linux ; then
    spd-say $@
  else
    PowerShell -Command "Add-Type –AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('$@');"
  fi
}

ECHOEVAL=1
echo_eval_on() {
  ECHOEVAL=1
}

echo_eval_off() {
  ECHOEVAL=0
}

echo_eval() {
  if [ $ECHOEVAL -eq 1 ] ; then
    echo ">>  " $@
  fi  
  eval $@
}

get_real_path() (
  if which realpath ; then
    realpath $@
  else
    # https://stackoverflow.com/a/18443300
    OURPWD=$PWD
    cd "$(dirname "$1")"
    LINK=$(readlink "$(basename "$1")")
    while [ "$LINK" ]; do
      cd "$(dirname "$LINK")"
      LINK=$(readlink "$(basename "$1")")
    done
    REALPATH="$PWD/$(basename "$1")"
    cd "$OURPWD"
    echo "$REALPATH"
  fi
)

is_actual_dir() {
  # usage: is_actual_dir /path/to/dir/to/test
  if test -d "$1" ; then
    echo $(cd $1 && test `pwd` = `pwd -P`)
    return 0
  else
    return 1
  fi
}

is_ssh_key_password_protected() {
    id_rsa_path="$1"
    if SSH_ASKPASS=/bin/false ssh-keygen -y -f $id_rsa_path < /dev/null >&/dev/null ; then
        return 1
    else
        return 0
    fi
}

is_admin() {
  isadmin=1
  if is_windows_system; then
    # https://stackoverflow.com/a/16285248/6265375
    net session >&/dev/null
    isadmin=$?
  else
    # assume sudo available
    sudo -l >&/dev/null
    isadmin=$?
  fi
  [ $isadmin -eq 0 ] && echo admin || echo user >&2
  return $isadmin
}


enable_native_symlinks() {
  # force cygwin or msys to make NTFS symbolic links
  # http://stackoverflow.com/a/18659632
  # https://cygwin.com/cygwin-ug-net/using.html#pathnames-symlinks
  # - Cygwin creates symbolic links potentially in multiple different ways:
  #   - The default symlinks are plain files containing a magic cookie followed by the path to which the link points. [...]
  #   - The shortcut style symlinks [*.lnk] [...] is created if the environment variable CYGWIN [...] is set to contain the string winsymlinks or winsymlinks:lnk. [...]
  #   - Native Windows symlinks [...] are only created if the user explicitely requests creating them. This is done by setting the environment variable CYGWIN to contain the string winsymlinks:native or winsymlinks:nativestrict. [...]
  # It allows to use `ln -s` instead of `cmd /c mklink`
  # Works for users with require SeCreateSymbolicLinkPrivilege right on windows run secpol.msc then go Security Settings/Local Policies/User Rights Assignment/"Create symbolic links" (cf. http://superuser.com/a/125981)
  # So work for admin by default! or for user with Windows 10 (since Creator Update) in Developer mode
  if is_cygwin ; then
    export CYGWIN="winsymlinks:nativestrict $CYGWIN"
  elif is_msys ; then
    export MSYS="winsymlinks:nativestrict $MSYS"
  fi
}

killall() {
  if is_windows_system ; then
    for i in $(ps -W | grep "$@" | grep -Eo '^([[:space:]]+[0-9]+){4}' | grep -Eo '[0-9]+$'); do
      taskkill -F -PID $i
    done
  else
    killall -I "$@"
  fi
}

local_setup() {
  cmdline_basepath=$1
  # Add extern subfolder to path
  if is_windows_system ; then
    export PATH=/c/Windows/System32/OpenSSH:$PATH
  else
    export PATH=$PATH:$cmdline_basepath/extern
  fi
}
