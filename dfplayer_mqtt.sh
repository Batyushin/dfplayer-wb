#!/bin/bash
PORT="/dev/ttyS7"
BROKER="localhost"
TOPIC="dfplayer/cmd"

stty -F $PORT 9600 cs8 -parenb -cstopb -echo raw

mosquitto_sub -h $BROKER -t "$TOPIC" | while read CMD; do
    case "$CMD" in
        play)   printf '\x7E\xFF\x06\x0D\x00\x00\x00\xFE\xEE\xEF' > $PORT ;;
        pause)  printf '\x7E\xFF\x06\x0E\x00\x00\x00\xFE\xED\xEF' > $PORT ;;
        stop)   printf '\x7E\xFF\x06\x16\x00\x00\x00\xFE\xE5\xEF' > $PORT ;;
        next)   printf '\x7E\xFF\x06\x01\x00\x00\x00\xFE\xFA\xEF' > $PORT ;;
        prev)   printf '\x7E\xFF\x06\x02\x00\x00\x00\xFE\xF9\xEF' > $PORT ;;
        vol_up) printf '\x7E\xFF\x06\x04\x00\x00\x00\xFE\xF7\xEF' > $PORT ;;
        vol_down) printf '\x7E\xFF\x06\x05\x00\x00\x00\xFE\xF6\xEF' > $PORT ;;
        volume:*) 
            VOL="${CMD#volume:}"
            VOL="${VOL%%[^0-9]*}"
            [ -z "$VOL" ] && VOL=15
            [ "$VOL" -lt 0 ] && VOL=0
            [ "$VOL" -gt 30 ] && VOL=30
            SUM=$((0xFF + 0x06 + 0x06 + 0x00 + 0x00 + VOL))
            CS=$(( (-SUM) & 0xFFFF ))
            H=$((CS >> 8)); L=$((CS & 0xFF))
            printf "\x7E\xFF\x06\x06\x00\x00\x$(printf '%02X' $VOL)\x$(printf '%02X' $H)\x$(printf '%02X' $L)\xEF" > $P>
            ;;
        *) echo "Unknown: $CMD" ;;
    esac
done

