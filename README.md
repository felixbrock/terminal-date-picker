# terminal-date-picker

A small `fzf`-based terminal date picker that copies the selected date to your clipboard.

![alt text](image.png)

## Features

- Fuzzy search dates as you type, for example `Wednesday` to narrow the list to Wednesdays.
- See which occurrence of the weekday a date is, such as `1st`, `2nd`, or `4th` Wednesday of the month.
- Preview the selected date in context with a three-month calendar view.
- Copy the selected date to the clipboard in `Thu 2026-03-26` format.
- Limit the picker to a custom year range when needed.

## Install packages

Requirements:

- `bash`
- `python3`
- `fzf`
- Clipboard support:
  - Linux: `wl-copy`, `xclip`, or `xsel`
  - macOS: `pbcopy` is built in
  - Termux: `termux-clipboard-set` (from `termux-api`)

## Linux

Install the required packages with your package manager:

```bash
# Debian/Ubuntu
sudo apt install bash python3 fzf wl-clipboard
```

```bash
# Arch Linux
sudo pacman -S bash python fzf wl-clipboard
```

If you are on X11 instead of Wayland, install `xclip` or `xsel` instead of `wl-clipboard`.

## macOS

Install dependencies with Homebrew:

```bash
brew install bash python fzf
```

`pbcopy` is included on macOS, so no extra clipboard package is required.

## Termux (Android)

Install dependencies with `pkg`:

```bash
pkg install bash python fzf termux-api
```

You also need the [Termux:API](https://wiki.termux.com/wiki/Termux:API) companion app installed on your device for `termux-clipboard-set` to work.

## Install date picker

After installing the dependencies above, install the script into a directory that is on your `PATH`.

Per-user:

```bash
mkdir -p ~/.local/bin
install -m 755 pick-date.sh ~/.local/bin/pick-date
```

System-wide:

```bash
sudo install -m 755 pick-date.sh /usr/local/bin/pick-date
```

Run it from anywhere:

```bash
pick-date
```

If `~/.local/bin` is not on your `PATH`, add this to your shell profile:

```bash
export PATH="$HOME/.local/bin:$PATH"
```
