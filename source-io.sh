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


list_hardware_ip () {
  if is_windows_system; then
    ipconfig | grep --color=never -A6 -E 'adapter (Ethernet|WiFi)' | grep -vE '(Media|IPv6|DNS|Mask|Gateway|^[[:space:]]+$)'  | sed -z 's/\n//g' | sed 's/--/\n/g' | cut -s -d':' -f1,3 | grep -oE 'adapter.+' | cut -d' ' '-f2-'
  elif is_darwin; then
    ifconfig | grep --color=never -E "inet [0-9.]+"
  else
    ip -4 a | grep --color=never -E "(eth|eno|wl)[a-z0-9]+$" | cut -d' ' -f6,13
  fi
}

start_audiostream_server () {
  # https://freedesktop.org/wiki/Software/PulseAudio/Documentation/User/Network/#directconnection
  if is_windows_system; then
    if test -e $(which pulseaudio) ; then
      hascookie=$(test -e ~/.pulse-cookie && echo 0 || echo 1)
      pulseaudio.exe --daemonize=1 --load="module-esound-protocol-tcp auth-anonymous=1" --load="module-native-protocol-tcp" "--log-target=file:$USERPROFILE/.pulse/$(uname -n)-runtime/pulse.log" &
      echo $! > ~/.pulse/$(uname -n)-runtime/nxpid
      if test $hascookie -eq 1 ; then
        echo 'WARNING: Make sure the cookie file was copied to client, use:     `scp ~/.pulse-cookie <client-ip>:.config/pulse/cookie`'
      fi
    else
      echo 'ERROR: pulseaudio required. Install using:    `winpty choco install -y pulseaudio`'
      echo 'ERROR: on linux client side: set the ip address for `default-server` entry into `/etc/pulse/client.conf`'
    fi
  fi
}

stop_audiostream_server () {
  if is_windows_system; then
    if test -e ~/.pulse/$(uname -n)-runtime/nxpid; then
      kill -TERM $(cat ~/.pulse/$(uname -n)-runtime/nxpid)
      rm ~/.pulse/$(uname -n)-runtime/nxpid
    fi
  fi
}

restart_audiostream_server () {
  # https://freedesktop.org/wiki/Software/PulseAudio/Documentation/User/Network/#directconnection
  if is_windows_system; then
    stop_audiostream_server
    start_audiostream_server
  fi
}