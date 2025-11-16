# DFPlayer Mini для Wiren Board (WB Rules + MQTT)

**Управление DFPlayer Mini через Wiren Board без Node-RED**  
Работает на **WB 7+**, использует **MQTT + внешний скрипт**.

---

## Особенности
- ✅ **Без `shell()` в WB Rules**  
- ✅ **Автоустановка одной командой**  
- ✅ **UART 9600 8N1 raw**  
- ✅ **Кнопки + громкость (0–30)**  
- ✅ **Ответ DFPlayer виден через `cat -v /dev/ttyS7`**

---

## Установка (1 команда)

```bash
curl -sSL https://raw.githubusercontent.com/Batyushin/dfplayer-wb/main/install.sh | bash
