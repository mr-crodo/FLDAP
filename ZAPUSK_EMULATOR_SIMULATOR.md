Можно. Android Studio и Xcode как IDE открывать не нужно. Но уточнение “как есть”: для iPhone по Wi-Fi без Xcode в реальности почти всегда невозможно, потому что установка/подпись iOS-приложения завязана на Xcode и Apple signing. На Android — полностью реально, включая Wi-Fi.

Android emulator (без Android Studio)

1. Список эмуляторов:

```bash
flutter emulators
```

2. Запуск:

```bash
flutter emulators --launch Pixel_9a
```

Если `--launch` падает, запуск напрямую:

```bash
~/Library/Android/sdk/emulator/emulator -avd Pixel_9a -no-snapshot-load
```

3. Проверка, что поднялся:

```bash
adb devices
flutter devices
```

4. Запуск приложения:

```bash
flutter run -d emulator-5554
```

iOS simulator (без открытия Xcode)

1. Открыть Simulator.app:

```bash
open -a Simulator
```

2. Посмотреть список симуляторов:

```bash
xcrun simctl list devices
```

3. Запустить нужный (boot по UDID):

```bash
xcrun simctl boot <UDID>
```

4. Запуск Flutter на симулятор:

```bash
flutter run -d "iPhone 15 Pro"
```

Android реальный девайс по Wi-Fi (без Android Studio)

Условие: телефон и Mac в одной сети Wi-Fi, на телефоне включён Developer options → Wireless debugging.

Вариант A (современный, Android 11+): Wireless Debugging (mDNS / pairing)

1. На телефоне: Developer options → Wireless debugging → Pair device with pairing code
   Появятся “Pairing code”, IP и 2 порта: pairing port и adb port.

2. На Mac:

```bash
adb pair <IP>:<PAIR_PORT>
# введи pairing code
```

3. Подключись:

```bash
adb connect <IP>:<ADB_PORT>
```

4. Проверь:

```bash
adb devices
flutter devices
```

5. Запусти:
   Если Flutter показывает длинный ID вида `_adb-tls-connect._tcp`, запускай прямо по нему:

```bash
flutter run -d adb-XXXXXXXX._adb-tls-connect._tcp
```

Либо по IP:port, если он появился как device id:

```bash
flutter run -d <IP>:<ADB_PORT>
```

Вариант B (старый): ADB over TCP/IP (если доступен на твоём девайсе/прошивке)
Нужен один раз USB:

```bash
adb tcpip 5555
adb connect <PHONE_IP>:5555
adb devices
flutter run -d <PHONE_IP>:5555
```

iPhone реальный девайс по Wi-Fi (без Xcode)

Здесь ограничения Apple:

1. Запуск на реальный iPhone из терминала возможен:

```bash
flutter run -d <iphone_id>
```

НО:

* для первого запуска проекта на iPhone почти всегда нужно настроить signing (Team/Bundle ID) в Xcode хотя бы один раз;
* “по Wi-Fi” для разработки обычно тоже настраивается через Xcode (Wi-Fi debugging / “Connect via network”);
* без Xcode как минимум на этапе initial signing и trust это обычно не взлетает.

Если ты уже раньше запускал этот же проект на этот же реальный iPhone (signing настроен, trust сделан), тогда часто сработает просто:

```bash
flutter devices
flutter run -d <id_iphone>
```

Но именно “подключить по Wi-Fi с нуля” без Xcode — практически нет.

Чтобы дать тебе точную команду для твоего текущего телефона (Android) и твоего iPhone, достаточно двух выводов:

```bash
flutter devices
adb devices
```

По Android я сразу скажу, какой именно `-d` использовать (IP:port или mDNS id). По iPhone — подтвердим, это симулятор или реальное устройство и есть ли шанс без открытия Xcode.
