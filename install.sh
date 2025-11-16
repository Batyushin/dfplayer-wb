#!/bin/bash

set -e

echo "DFPlayer MQTT Auto-Installer for Wiren Board"
echo "===================================================="

# Проверка root
if [ "$EUID" -ne 0 ]; then
    echo "Ошибка: Запустите от root"
    exit 1
fi

# Папка установки
INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
RULES_FILE="/etc/wb-rules/DFPlayer.js"

# --- 1. Скрипт dfplayer_mqtt.sh ---
echo "[1/5] Установка скрипта..."
cat > $INSTALL_DIR/dfplayer_mqtt.sh << 'EOF'
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
            printf "\x7E\xFF\x06\x06\x00\x00\x$(printf '%02X' $VOL)\x$(printf '%02X' $H)\x$(printf '%02X' $L)\xEF" > $PORT
            ;;
        *) echo "Unknown: $CMD" ;;
    esac
done
EOF
chmod +x $INSTALL_DIR/dfplayer_mqtt.sh

# --- 2. systemd сервис ---
echo "[2/5] Установка сервиса..."
cat > $SERVICE_DIR/dfplayer-mqtt.service << 'EOF'
[Unit]
Description=DFPlayer MQTT Listener
After=network.target mosquitto.service

[Service]
Type=simple
ExecStart=/usr/local/bin/dfplayer_mqtt.sh
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dfplayer-mqtt.service

# --- 3. WB Rules ---
echo "[3/5] Установка правил..."
cat > $RULES_FILE << 'EOF'
log("DFPlayer MQTT loaded");

defineVirtualDevice("dfplayer", {
    title: "DFPlayer Mini",
    cells: {
        Play:    { type: "pushbutton", order: 1 },
        Pause:   { type: "pushbutton", order: 2 },
        Stop:    { type: "pushbutton", order: 3 },
        Next:    { type: "pushbutton", order: 4 },
        Prev:    { type: "pushbutton", order: 5 },
        VolUp:   { type: "pushbutton", order: 6 },
        VolDown: { type: "pushbutton", order: 7 },
        Volume:  { type: "range", min: 0, max: 30, value: 15, order: 8 }
    }
});

function send(cmd) {
    publish("dfplayer/cmd", cmd, 0, true);
}

defineRule("play",   { whenChanged: "dfplayer/Play",    then: function() { send("play"); } });
defineRule("pause",  { whenChanged: "dfplayer/Pause",   then: function() { send("pause"); } });
defineRule("stop",   { whenChanged: "dfplayer/Stop",    then: function() { send("stop"); } });
defineRule("next",   { whenChanged: "dfplayer/Next",    then: function() { send("next"); } });
defineRule("prev",   { whenChanged: "dfplayer/Prev",    then: function() { send("prev"); } });
defineRule("vol_up", { whenChanged: "dfplayer/VolUp",   then: function() { send("vol_up"); } });
defineRule("vol_down", { whenChanged: "dfplayer/VolDown", then: function() { send("vol_down"); } });

defineRule("volume", {
    whenChanged: "dfplayer/Volume",
    then: function(v) {
        v = Math.floor(v);
        if (v < 0) v = 0; if (v > 30) v = 30;
        send("volume:" + v);
    }
});
EOF

# --- 4. Перезапуск ---
echo "[4/5] Перезапуск сервисов..."
systemctl restart dfplayer-mqtt.service
wb-rules restart

# --- 5. Готово ---
echo "[5/5] УСТАНОВКА ЗАВЕРШЕНА!"
echo ""
echo "Устройство: DFPlayer Mini"
echo "Топик: dfplayer/cmd"
echo ""
echo "Проверь: mosquitto_pub -t dfplayer/cmd -m play"
echo "Логи: journalctl -u dfplayer-mqtt.service -f"
