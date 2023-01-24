#!/usr/bin/sh
# expected to be sourced 


use_perl() {
    if is_windows_system ; then
        # perl installed via chocolatey `choco install -y strawberryperl`
        export PATH=/c/Strawberry/perl/site/bin:/c/Strawberry/perl/bin:$PATH
    fi
}

use_nvm() {  
    # ensure loading nvm.sh and bash completion, installed using https://github.com/nvm-sh/nvm
    # NOTE on Windows use `choco install nvm` which do not requires this: https://github.com/coreybutler/nvm-windows    
    if ! is_windows_system ; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" --no-use # This loads nvm but does not select a version
        [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    fi
}


ruby_unbuffered() {
  $(which ruby) -e "STDOUT.sync=true" -e "STDIN.sync=true" -e "STDERR.sync=true" -e "load(\$0=ARGV.shift)" $@ #unbuffered output
}

python_unbuffered() {
  $(which python) -u $@ #unbuffered output
}

use_default_python() {
    if is_msys ; then
      if [[ $1 == 2* ]]; then
        export PATH=/c/Python27/Scripts:/c/Python27:$PATH
      elif [[ $1 == 3* ]]; then
        export PATH=/c/Python$1/Scripts:/c/Python$1:$PATH
        if [ ! -L /c/Python$1/python3.exe ]; then
          ln -s /c/Python$1/python.exe /c/Python$1/python3.exe
        fi
      fi
      #alias python3=py_unbuffered
    fi
}

use_pipenv_in_project() {
  export PIPENV_VENV_IN_PROJECT=1
}

shrink_wsl2_vdisk() {
  # inspired from https://stephenreescarter.net/how-to-shrink-a-wsl2-virtual-disk/
  vmname=$1
  diskpath=$(find "$USERPROFILE/AppData/Local/Packages" -type f -ipath *$vmname*/LocalState/*.vhdx | sed "s/\\\\/\\\\\\\\/g" | sed "s/\\//\\\\\\\\/g")
  echo "# Using disk : $diskpath"
  echo -e "
  select vdisk file='$diskpath'
  compact vdisk
  exit
  " > /tmp/wsl2_shrink
  wsl –terminate $vmname
  wsl –shutdown
  diskpart -s /tmp/wsl2_shrink
}