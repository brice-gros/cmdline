#!/usr/bin/sh
# expected to be sourced 

colorlog () {
    # sed --unbuffered
    sed -u \
        -e 's/\(.*SUCCE.*\)/\x1b[32m\1\x1b[39m/i' \
        -e 's/\(.*FAIL.*\)/\x1b[31m\1\x1b[39m/i' \
        -e 's/\(.*WARN.*\)/\x1b[33m\1\x1b[39m/i' \
        -e 's/\(.*ERROR.*\)/\x1b[31m\1\x1b[39m/i'
}
