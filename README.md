# KnittStyler on Linux (Wine)

Scripts that run **KnittStyler**, the Windows program for Silver Reed knitting machines, on Ubuntu under Wine, with the machine cable on a USB serial adapter.

[Українська версія](README.uk.md)

This repository contains no part of KnittStyler. You need your own installed copy of the program.

## Status

Tested on Ubuntu 26.04 with Wine 10.0 (distribution packages).

| Feature | State |
|---|---|
| Interface, Cyrillic text, all tabs | Works |
| Serial port | The program opens COM1 and sends its handshake to the adapter. Checked with a virtual serial port; a real machine is not tested yet |
| Sounds | Wine audio output works through PipeWire/PulseAudio. The program plays its sounds while knitting; not yet heard with a real machine |
| Built-in manual | Works with wine-gecko, which the launcher installs |
| Printing | Uses any printer set up in CUPS |

Reports from other machines and Ubuntu versions are welcome in the issues.

## Requirements

- Ubuntu or Debian, x86-64, with Wine able to run 32-bit programs, plus `git` to get the scripts and `wget` to download wine-gecko on first start:
  ```
  sudo dpkg --add-architecture i386 && sudo apt update
  sudo apt install wine wine32:i386 git wget
  ```
  Wine pulls in its sound and USB libraries itself. Keep apt's recommended packages (the default): `libcups2:i386`, which Wine needs to see printers, comes in only as a recommendation of `wine32`.
- Access to serial ports for your user (log out and back in afterwards):
  ```
  sudo usermod -aG dialout $USER
  ```
- Recommended: remove two packages that grab USB serial adapters. `brltty` takes CH340/CH341 adapters away, and `modemmanager` sends modem commands to new serial devices.
  ```
  sudo apt purge brltty modemmanager
  ```
- Optional, nothing breaks without them:
  - `printer-driver-cups-pdf`: a PDF printer (see [Known issues](#known-issues));
  - `zenity`: message windows when KnittStyler is started from the menu (present on Ubuntu with GNOME);
  - `cups-client`: lets the launcher warn when no printer is set up;
  - `icoutils` and `desktop-file-utils`: program icon and menu refresh for `install-desktop.sh`;
  - `fonts-noto-cjk`: only for the Japanese interface.
- Helper scripts only: `scripts/extract-from-vm.sh` needs `virtualbox` and `ntfs-3g`; `scripts/hive-to-reg.py` needs `regipy` (`pip install regipy`).

## Installation

1. Get the scripts:
   ```
   git clone https://github.com/pesua/knittstyler-wine.git
   cd knittstyler-wine
   ```
2. Copy in your KnittStyler. The launcher needs the program folder of an installed copy, `C:\KnittStyler` on Windows:
   ```
   bundle/knittstyler --import /path/to/KnittStyler
   ```
   If the program lives in a VirtualBox VM, `scripts/extract-from-vm.sh` copies the folder out of the VM disk without starting the VM (see the script header).
3. Add a menu entry (optional):
   ```
   bundle/install-desktop.sh
   ```
4. Start KnittStyler from the menu or with `bundle/knittstyler`. The first start creates the Wine prefix and downloads wine-gecko (about 55 MB); it takes about a minute.

## Knitting machine cable

The launcher connects the program's COM1 to the first serial adapter it finds: `/dev/serial/by-id/*`, then `/dev/ttyUSB*`, then `/dev/ttyACM*`. Keep COM1 selected in the program settings.

To pin a specific adapter, copy `bundle/config/knittstyler.conf.example` to `bundle/config/knittstyler.conf` and set `KS_SERIAL`. A `/dev/serial/by-id/...` path keeps working when the adapter moves to another USB port.

## Moving to another computer

`scripts/pack-bundle.sh` packs `bundle/` with your program copy and patterns into `dist/knittstyler-YYYYMMDD.tar.gz`. On the other computer, install the requirements, unpack the archive and run `knittstyler/install-desktop.sh` or `knittstyler/knittstyler`.

The Wine prefix is not packed. The launcher builds a new one on the target computer with its own Wine version and user name. Patterns saved in KnittStyler live in `bundle/app/KnittStyler` and travel with the archive.

## Known issues

- **"There is no default printer currently selected" at start-up.** The program asks for a default printer and shows this message when none is set up. Clicking OK is enough; the program then works normally. The message box can open hidden under the butterfly splash screen, which stays on top until the box is closed. Any printer in CUPS removes the message; `sudo apt install printer-driver-cups-pdf` adds a PDF printer.
- **COM2 to COM32 in the port list.** Wine creates these ports for `/dev/ttyS*` on its own. Use COM1.
- **Interface language.** The default is Russian. `bundle/config/knittstyler-defaults.reg` selects `RUS`, `ENG` or `JPN`; run `bundle/knittstyler --setup` after changing it.

## How it works

- **Wine prefix.** A 32-bit prefix (`WINEARCH=win32`) in `bundle/prefix`, built from scratch on first start, so it always matches the local Wine.
- **Locale.** KnittStyler is an ANSI Delphi program with Russian text, so Wine has to run with code page 1251. The launcher starts Wine under `ru_RU.UTF-8`. When the system lacks that locale, it compiles one with `localedef` into the bundle, without root.
- **Manual.** The launcher reads the wine-gecko version the installed Wine expects, downloads it and installs it into the prefix.
- **Program files.** `C:\KnittStyler` in the prefix is a link to `bundle/app/KnittStyler`, so rebuilding the prefix (`--setup`) keeps the program and the patterns.
- **Serial port.** The adapter is assigned to COM1 through `HKLM\Software\Wine\Ports`.
- **Settings.** `bundle/config/*.reg` files are imported in name order when the prefix is built. A personal `knittstyler-user.reg` placed there overrides the defaults; `scripts/hive-to-reg.py` exports one from a Windows registry hive.

## Troubleshooting

- Wine output goes to `~/.cache/knittstyler/wine.log`.
- `bundle/knittstyler --setup` rebuilds the Wine prefix; program files and patterns stay.
- `bundle/knittstyler --winecfg` opens Wine settings for the prefix (audio test, Windows version).
- `WINEDEBUG=+comm,+serial bundle/knittstyler` logs serial port calls.

## Repository layout

| Path | Contents |
|---|---|
| `bundle/knittstyler` | Launcher |
| `bundle/install-desktop.sh` | Menu entry |
| `bundle/config/` | Registry defaults, font registration, config example |
| `bundle/app/KnittStyler/` | Your copy of the program (not in git) |
| `scripts/` | Copying the program out of a VirtualBox disk, registry export, packing |
| `notes/` | Porting notes (in Ukrainian) and a serial capture |

## Legal

KnittStyler is proprietary software by TRIAN Solutions, sold with Silver Reed knitting machine adapters. This project is not affiliated with TRIAN Solutions or Silver Reed. It contains only scripts and settings and does not distribute any part of KnittStyler; use it with a copy you are licensed to use.

## License

[MIT](LICENSE)
