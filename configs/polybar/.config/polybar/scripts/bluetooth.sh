#!/bin/sh
# https://github.com/msaitz/polybar-bluetooth/blob/master/bluetooth.sh

if [ $(bluetoothctl show | grep "Powered: yes" | wc -c) -eq 0 ]
then
  echo "%{F#66ffffff}"
else
  if [ $(echo info | bluetoothctl | grep 'Device' | wc -c) -eq 0 ]
  then 
    echo ""
  fi
  echo "%{F#D8DEE9}"
fi
