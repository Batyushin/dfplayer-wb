// === DFPlayer via MQTT ===
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
    log("MQTT → dfplayer/cmd: " + cmd);
    publish("dfplayer/cmd", cmd, 0, true);  // retain = true
}

// Кнопки
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
