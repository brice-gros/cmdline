#!/usr/bin/sh
# expected to be sourced 

colorlog () {
    # sed --unbuffered
    sed -u \
        -e 's/\(.*FAIL.*\)/\x1b[31m\1\x1b[39m/i' \
        -e 's/\(.*ERROR.*\)/\x1b[31m\1\x1b[39m/i' \
        -e 's/\(.*WARN.*\)/\x1b[33m\1\x1b[39m/i' \
        -e 's/\(.*SUCCE.*\)/\x1b[32m\1\x1b[39m/i'
}


list_hardware_ip() {
  if is_windows_system; then
    ipconfig | grep --color=never -A6 -E 'adapter (Ethernet|WiFi)' | grep -vE '(IPv6|DNS|^[[:space:]]+$)' | sed -z 's/\n//g' | sed 's/--/\n/g' | cut -s -d':' -f1,3 | grep -oE 'adapter.+' | cut -d' ' '-f2-'
  else
    ip -4 a | grep --color=never -E "(eth|eno|wl)[a-z0-9]+$" | cut -d' ' -f6,13
  fi
}
