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

remove_osx_browser_download_quarantine_flag () {
  xattr -d com.apple.quarantine "$1"
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

# Utility to install packages for capture2ocr function
_capture2ocr_install () {
  if is_windows_system; then
    winget install capture2text
  elif is_linux; then
    # https://askubuntu.com/questions/1038099/capture2text-alternative-capture-text-from-screen-directly-in-ubuntu-mate
    sudo apt-get install tesseract-ocr imagemagick xsel
  fi
}

capture2ocr() {
  if is_windows_system; then
    # todo find cmdline args
    >/dev/null capture2text & 
  elif is_linux; then
    # https://antofthy.gitlab.io/software/capture_ocr.sh.txt
    convert x: -normalize png:- | tesseract --dpi 300 stdin stdout | xsel -ib && xsel -ob | code - &
    # can be added as a shortcut calling `/bin/bash -i -c capture2ocr`
  fi
}

authorize_x_access_through_ssh() {
  # in case of error: 'Authorization required, but no authorization protocol specified'
  if is_linux; then
    # https://www.reddit.com/r/linux4noobs/comments/lu1plx/comment/hwkdvlf/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
    # can be if X11 or Xwayland used
    # pgrep Xorg
    # pgrep Xwayland
    # if -a not supported, should use cat /proc/$(pgrep X)/cmdline
    cp $(pgrep X -a | grep -oE '\-auth [a-zA-Z0-9/.-]+' | cut -d' ' -f2) ~/.Xauthority
    DISPLAY=:0 xhost +si:localuser:root
  else
    echo 'Not implemented: read_screen_edid()'
  fi
}

read_screen_edid() {
  if is_linux; then
    # example of locations:
    #  - /sys/devices/platform/gpu/drm/card1/card1-HDMI-A-1/edid
    #  - /sys/devices/platform/axi/axi:gpu/drm/card1/card1-HDMI-A-1/edid
    #  - /sys/devices/pci0000:64/0000:64:00.0/0000:65:00.0/drm/card1/card1-HDMI-A-1/edid
    # using edid-decode here, but parse-edid works as well
    find /sys/devices/ -iname edid -exec bash -c 'echo ====== {} && cat {} | edid-decode && echo ===== && echo' \;
  else
    echo 'Not implemented: read_screen_edid()'
  fi
}

find_file_handle() {
  if is_linux; then
    sudo find /proc -type l,f -path "/proc/*/fd/*" -exec bash -c "file {} | grep -F '$1'" \;
  else
    echo 'Not implemented: find_file_handle()'
  fi
}
