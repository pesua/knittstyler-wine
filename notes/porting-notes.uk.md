# KnittStyler на Ubuntu через Wine

> Робочі нотатки перенесення (жовтень 2026). Опис для користувачів: [README.uk.md](../README.uk.md).

Перенесення програми **KnittStyler** (Trian Solutions, збірка 2006 року) з віртуалки VirtualBox `knitter` (Windows XP 32-bit) на Ubuntu. Програма готує візерунки й передає їх на в'язальні машини Silver Reed через COM-порт.

## Коротко

- **Програма:** `KnittStyler.exe`, Delphi 6/7 (VCL), 32-bit. Використовує тільки системні бібліотеки Windows: user32, gdi32, comctl32, winmm, winspool, ole32. Сторонніх DLL і драйверів немає, захисту від копіювання не знайдено.
- **Мова інтерфейсу:** російська. Переклади лежать у файлах `KnittStyler.RUS`, `.ENG`, `.JPN`, а вибір мови задано в реєстрі: `HKCU\Software\Borland\Locales` = `RUS`. Рядки збережені в кодуванні ANSI, тому Wine треба запускати з кодовою сторінкою 1251, тобто з локаллю `ru_RU.UTF-8`.
- **COM-порт:** звичайний Win32 API (`CreateFileA`, `SetCommState`). Список портів програма бере з `HKLM\HARDWARE\DEVICEMAP\SERIALCOMM`, вибраний порт зберігає в `HKCU\Software\TRIAN Solutions\KnittStyler\ACOMPort`. У віртуалці стояв `COM5`, у бандлі задано `COM1`.
- **Звук:** 5 WAV-ресурсів усередині exe, відтворюються через `PlaySound`: `SNDALLDONE`, `SNDCHANGECOLOR`, `SNDCHANGENEEDLENUMBER`, `SNDCHANGESETTINGS`, `SNDDATATRANSMITTED`. Копії лежать у `notes/sounds/` (локально; не в репозиторії). Які звуки ввімкнені, задає `SoundEvents` (бітова маска; `31` означає всі п'ять).
- **Принтер:** при старті програма вимагає принтер за замовчуванням, інакше показує «There is no default printer currently selected». Wine бере принтери з CUPS, тому в системі має бути хоч один принтер, наприклад віртуальний `printer-driver-cups-pdf`. Принтер-заглушка в реєстрі Wine не працює: програма тоді пише «Printer selected is not valid».
- **Довідка:** `Knittstyler_RUS.chm` і HTML-посібник у вбудованому Internet Explorer (`TWebBrowser`). У Wine для цього потрібен wine-gecko.
- **Машини** (рядки в exe): Silver Reed SK-830/FPR-70, SK-840/SRP-60N, SK-860/SR-860, кабель «Silver-KS COM/CEN». У реєстрі віртуалки `Machine=102`, `NeedleBed=200`.

## Структура

| Шлях | Зміст | У git |
|---|---|---|
| `bundle/` | Те, що переноситься на іншу машину | частково |
| `bundle/knittstyler` | Скрипт запуску (див. нижче) | так |
| `bundle/config/*.reg` | Налаштування програми з віртуалки та реєстрація шрифту | так |
| `bundle/share/` | Іконка | так |
| `bundle/app/KnittStyler/` | Файли програми; сюди ж програма зберігає візерунки | ні |
| `bundle/redist/` | `wine-gecko-*-x86.msi` | ні |
| `bundle/locale/` | Скомпільована локаль `ru_RU.UTF-8`, щоб не потрібен був root | ні |
| `bundle/prefix/` | Wine-префікс, створюється при першому запуску | ні |
| `original/` | Сирі копії з диска віртуалки: `C:\KnittStyler`, `C:\ks_test`, гілки реєстру | ні |
| `scripts/` | Підготовка: витягування з ВМ, експорт реєстру, пакування | так |
| `dist/` | Готові архіви для перенесення | ні |
| `notes/` | Витягнуті матеріали | так |

## Як працює скрипт запуску

Скрипт `bundle/knittstyler` не залежить від того, де лежить тека бандла.

1. Знаходить 32-бітний завантажувач Wine. Порядок пошуку: `KS_WINE`, `bundle/wine/bin/wine` (місце для майбутньої портативної збірки), `/usr/bin/wine32`, `/usr/lib/wine/wine`, `/opt/wine-stable/bin/wine`, `/usr/bin/wine`.
2. Вмикає `ru_RU.UTF-8`: системну локаль, якщо вона є, інакше `bundle/locale`, а якщо й та не завантажується, генерує локаль через `localedef` у `~/.local/share/knittstyler/locale`.
3. При першому запуску, або з ключем `--setup`, створює 32-bit префікс (`WINEARCH=win32`). Далі ставить wine-gecko тієї версії, яку вимагає встановлений Wine (за потреби завантажує її), копіює шрифт `KnitStyler.ttf` та імпортує `config/*.reg`.
4. Робить `C:\KnittStyler` посиланням на `bundle/app/KnittStyler`. Завдяки цьому дані користувача залишаються в бандлі, а префікс можна перестворювати без втрат.
5. Прив'язує COM1 до кабелю: `KS_SERIAL` або перший пристрій з `/dev/serial/by-id/*`, `/dev/ttyUSB*`, `/dev/ttyACM*`. Прив'язка записується в `HKLM\Software\Wine\Ports`. Також скрипт перевіряє доступ до пристрою (група `dialout`).
6. Лог Wine пише у `~/.cache/knittstyler/wine.log`.

Префікс не переноситься, а збирається на місці. Причина в тому, що він прив'язаний до імені користувача, до шляхів `/home/...` і до версії Wine, а на віддаленій машині стоїть старіша Ubuntu.

## Стан

| Питання | Стан |
|---|---|
| Файли й реєстр перенесено з віртуалки | Зроблено |
| Префікс збирається скриптом (Wine 10.0, Ubuntu 26.04) | Зроблено, ≈7 с; архів перевірено з чистого місця |
| Кирилиця та кодова сторінка 1251 без root | Зроблено (ACP=1251, OEMCP=866) |
| wine-gecko | Зроблено (2.47.4) |
| Головне вікно, вкладки «Рисование» і «Вязание» | Працюють, останній візерунок відновлюється з `autosave.ks` |
| COM-порт | Працює до рівня байтів: на «Старт» програма відкриває COM1 і шле `07 F8 00 FF` ([notes/com-start-no-adapter.log](com-start-no-adapter.log)). Без машини: «Код ошибки 2048. Адаптер не подсоединен!» |
| Звук | Тракт Wine → winepulse → PipeWire працює (winecfg «Test Sound», потік `running`). Звуки самої програми звучать під час в'язання, з машиною ще не перевірено |
| Принтер | Не обов'язковий: після OK програма працює. Без принтера в CUPS повідомлення може сховатися під заставкою; скрипт попереджає один раз |
| Справжній кабель і машина | Перевірити на віддаленій машині |
| Віддалена машина (старіша Ubuntu, старіший Wine) | Відкладено |
| Ярлик у меню (`install-desktop.sh`), архів (`scripts/pack-bundle.sh`) | Зроблено |

## Відомі особливості

- **Повідомлення про принтер під заставкою.** Заставка має стиль «завжди зверху», а повідомлення ні, тому у звичайному режимі воно може відкритися під заставкою і не потрапити в Alt+Tab. Заставка зникає тільки після OK. Найпростіше рішення: будь-який принтер у CUPS (`printer-driver-cups-pdf`). У режимі віртуального робочого столу Wine повідомлення лежить поверх заставки.
- **Зайві COM-порти.** Wine сам створює COM1–COM32 на `/dev/ttyS*`, і програма показує їх у списку. Прибрати їх через `HKLM\Software\Wine\Ports` з порожніми значеннями не можна: Wine перепризначає звільнені порти на COM33+. Програма працює з COM1, який скрипт прив'язує до кабелю.
- **Версія Windows** у префіксі за замовчуванням Windows 10; програма працює так. Якщо з'являться проблеми, можна спробувати XP через `knittstyler --winecfg`.

## Як тестувати без монітора

Під Wayland XTest (xdotool) не доходить до вікон Wine. Для тестів: `Xvfb :77`, окремий префікс (`KS_PREFIX=...`) з віртуальним робочим столом Wine (`HKCU\Software\Wine\Explorer` `Desktop=Default`, `...\Explorer\Desktops` `Default=1600x1000`), далі `DISPLAY=:77 xdotool` та `import -window root`. Без віртуального робочого столу у Xvfb немає менеджера вікон, і кліки по вкладках не працюють. Віртуальний COM-порт: `socat pty,link=A,raw,echo=0 pty,link=B,raw,echo=0`, `KS_SERIAL=A`, читати з `B`.

## На віддаленій машині

```
tar xzf knittstyler-YYYYMMDD.tar.gz
sudo dpkg --add-architecture i386 && sudo apt update && sudo apt install wine wine32:i386
sudo usermod -aG dialout $USER          # перезайти
sudo apt purge brltty modemmanager      # захоплюють USB-COM адаптери
knittstyler/install-desktop.sh          # ярлик у меню
knittstyler/knittstyler                 # перший запуск збирає префікс
```
Для старішої Ubuntu ще треба перевірити: наявність `wine32` (32-bit завантажувач), потрібну цьому Wine версію Gecko (скрипт завантажить її сам, якщо є інтернет) і сумісність `bundle/locale` з тамтешньою glibc (інакше скрипт сам згенерує локаль через `localedef`).

## Відтворення

```
scripts/extract-from-vm.sh /KnittStyler original/KnittStyler   # диск ВМ монтується тільки для читання
python3 -m venv venv && venv/bin/pip install regipy
venv/bin/python scripts/hive-to-reg.py original/registry/NTUSER-*.DAT HKEY_CURRENT_USER out.reg \
  'Software\TRIAN Solutions' 'Software\Borland\Locales'
```
