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
        [ -s "$NVM_DIR/nvm.sh" ] && time echo-eval source "$NVM_DIR/nvm.sh" --no-use # This loads nvm but does not select a version
        [ -s "$NVM_DIR/bash_completion" ] && time echo-eval source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    fi
}