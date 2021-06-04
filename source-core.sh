#!/usr/bin/sh
# expected to be sourced 


is_cygwin() {
  if echo $(uname) | grep -iq cygwin; then
    return 0
  fi
  return 1
}

is_msys() {
  if echo $(uname) | grep -iq MINGW; then
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

settitle() {
  echo -ne "\e]0;$1\a"
}

setcoloredprompt() {
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
  # mine works well with black/grey/white background: (Note that \e == \033)
  export PS1="\[\e[32m\]\u@\h \[\e[35m\]$MSYSTEM \[\e[31m\]\w\[\e[36m\]`__git_ps1`\[\e[0m\]\n$ "
}

settitlepath() {
  # from git bash default originally:
  # export PS1="\[\033]0;$TITLEPREFIX:$PWD\007\]\n$PS1"
  if is_msys ; then
    export PS1="\[\e]0;$MSYSTEM \u@\h \w\a\]\n$PS1"
  else
    export PS1="\[\e]0;$(uname) \u@\h \w\a\]\n$PS1"
  fi
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
echo-eval-on() {
  ECHOEVAL=1
}

echo-eval-off() {
  ECHOEVAL=0
}

echo-eval() {
  if [ $ECHOEVAL -eq 1 ] ; then
    echo ">>  " $@
  fi  
  eval $@
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
  # force cygwin to make NTFS symbolic links
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