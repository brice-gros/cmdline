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
    local id_rsa_path="$1"
    if SSH_ASKPASS=/bin/false ssh-keygen -y -f $id_rsa_path < /dev/null &> /dev/null ; then
        return 1
    else
        return 0
    fi
}
