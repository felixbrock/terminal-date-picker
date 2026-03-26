# terminal-date-picker

A small `fzf`-based terminal date picker that copies the selected date to your clipboard.

![alt text](image.png)

## Install packages

Requirements:

- `bash`
- `python3`
- `fzf`
- Clipboard support:
  - Linux: `wl-copy`, `xclip`, or `xsel`
  - macOS: `pbcopy` is built in

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
