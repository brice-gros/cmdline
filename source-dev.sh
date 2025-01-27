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
      if ! test -d "$NVM_DIR" ; then
        pushd ~
        git clone https://github.com/nvm-sh/nvm.git .nvm
        cd ~/.nvm
        git checkout v0.40.1
        popd
      fi
      test -s "$NVM_DIR/nvm.sh" && source "$NVM_DIR/nvm.sh" --no-use # This loads nvm but does not select a version
      test -s "$NVM_DIR/bash_completion" && source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    fi
}


ruby_unbuffered() {
  $(which ruby) -e "STDOUT.sync=true" -e "STDIN.sync=true" -e "STDERR.sync=true" -e "load(\$0=ARGV.shift)" $@ #unbuffered output
}

python_unbuffered() {
  $(which python) -u $@ #unbuffered output
}

_get_windows_python() {
  if is_msys ; then
    # list all python found from windows cmd
    PYTHONS=$(cmd.exe //Q //C "where python")
    # get git bash root in windows path
    GIT_BASE=$(cd / ; pwd -W)
    # iterate over PYTHONS and print only paths with the version number in it and which is not in GIT_BASE
    PY=$( (for PYTHON in $PYTHONS; do 
        echo $PYTHON | sed 's/\r//g' | sed 's/\\/\//g'
    done) | grep -v $GIT_BASE | grep -E '[0-9]+' | head -n 1
    )
    echo $PY
  fi
}

use_default_python() {
    if is_msys ; then
      if [[ $1 == 2* ]]; then
        export PATH=/c/Python27/Scripts:/c/Python27:$PATH
      elif [[ $1 == 3* ]]; then
        PYTHON_BASE=$(_get_windows_python)
        if test -z "$PYTHON_BASE" ; then
          echo "==> No Suitable Windows Python found"
        else
          PYTHON_BASE=$(dirname "$PYTHON_BASE")
          PYTHON_BASE=$(cd $PYTHON_BASE ; pwd)
          export PATH=$PYTHON_BASE/Scripts:$PYTHON_BASE:$PATH
          if [ ! -L $PYTHON_BASE/python3.exe ]; then
            ln -s $PYTHON_BASE/python.exe $PYTHON_BASE/python3.exe
          fi
        fi
      fi
      #alias python3=py_unbuffered
    fi
}

use_pipenv_in_project() {
  export PIPENV_VENV_IN_PROJECT=1
}

use_wsl2_ubuntu() {
  if is_windows_system ; then
    if ! test -f ~/.wslgconfig ; then
      echo '[system-distro-env]' > ~/.wslgconfig
      echo 'WESTON_RDP_FRACTIONAL_HI_DPI_SCALING=true' >> ~/.wslgconfig
      echo '#WESTON_RDP_DEBUG_DESKTOP_SCALING_FACTOR=500' >> ~/.wslgconfig
    fi
  fi
}

wsl2_shrink_vdisk() {
  # inspired from https://stephenreescarter.net/how-to-shrink-a-wsl2-virtual-disk/
  vmname=$1
  diskpath=$(find "$USERPROFILE/AppData/Local/Packages" -type f -ipath *$vmname*/LocalState/*.vhdx | sed "s/\\\\/\\\\\\\\/g" | sed "s/\\//\\\\\\\\/g")
  echo "# Using disk : $diskpath"
  echo -e "
  select vdisk file='$diskpath'
  compact vdisk
  exit
  " > /tmp/wsl2_shrink
  wsl --terminate $vmname
  wsl --shutdown
  diskpart -s /tmp/wsl2_shrink
}