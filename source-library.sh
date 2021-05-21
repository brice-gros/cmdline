#!/usr/bin/sh
# expected to be sourced 
settitle() {
  echo -ne "\e]0;$1\a"
}
setcoloredprompt() {
  export PS1="\[\e[31m\]$(uname) \e[35m\]\u@\h \[\e[34m\]\w\[\e[0m\]\n$ "
}
settitlepath() {
  export PS1="\[\e]0;$(uname) \u@\h \w\a\]\n$PS1"
}

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