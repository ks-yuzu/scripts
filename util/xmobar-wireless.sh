#!/bin/sh

iwconfig eth2 2>&1 | grep -q 'no wireless extensions' && {
  echo wired
  exit 0
}

# TODO: perl にする
# TODO: 短縮したら '...' とする
essid=`nmcli -t -f active,ssid dev wifi | egrep '^yes' | cut -d':' -f2 | cut -c 1-17`
stngth=`nmcli -t -f active,ssid,signal dev wifi|grep yes|cut -d':' -f3`
bars=`expr $stngth / 10`

case $bars in
  0)  bar='[<fc=red>----------</fc>]' ;;
  1)  bar='[<fc=red>|---------</fc>]' ;;
  2)  bar='[<fc=red>||--------</fc>]' ;;
  3)  bar='[<fc=red>|||-------</fc>]' ;;
  4)  bar='[<fc=orange>||||------</fc>]' ;;
  5)  bar='[<fc=orange>|||||-----</fc>]' ;;
  6)  bar='[<fc=orange>||||||----</fc>]' ;;
  7)  bar='[<fc=green>|||||||---</fc>]' ;;
  8)  bar='[<fc=green>||||||||--</fc>]' ;;
  9)  bar='[<fc=green>|||||||||-</fc>]' ;;
  10) bar='[<fc=green>||||||||||</fc>]' ;;
  *)  bar='[----!!----]' ;;
esac

echo $essid $bar

exit 0
