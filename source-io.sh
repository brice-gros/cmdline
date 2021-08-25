#!/usr/bin/sh
# expected to be sourced 

colorlog () {
    sed --unbuffered \
        -e 's/\(.*SUCCE.*\)/\o033[32m\1\o033[39m/i' \
        -e 's/\(.*FAIL.*\)/\o033[31m\1\o033[39m/i' \
        -e 's/\(.*WARN.*\)/\o033[33m\1\o033[39m/i' \
        -e 's/\(.*ERROR.*\)/\o033[31m\1\o033[39m/i'
}
