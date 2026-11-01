| Source | Config | Binds |
|---|---|---|
| sxhkd | `~/.config/sxhkd/sxhkdrc` | 8 |
| st | `~/st/config.h` | 5 |
| XKB | `setxkbmap -query, /etc/X11/xorg.conf.d/00-keyboard.conf` | 1 |
| zsh | `~/.zshrc` | 3 |

## sxhkd

`~/.config/sxhkd/sxhkdrc`

| Keybind | Action | Description |
|---|---|---|
| `Alt + Shift + Enter` | `this is changed` | changed for a test |
| `Alt + Backspace` | `bspc rule -a "firefox" -o state=floating rectangle=1300x950+2640+260 && firefox -new-window "https://www.myhopefm.net/player/" & bspc rule -a "*" -o state=floating rectangle=1300x950+1180+260 && st -e bash -c '~/.local/bin/you-are-better-than-this; read'` |  |
| `Alt + \` | `bspc rule -a "*" -o state=floating rectangle=800x700+800+300 && st -t qnote -e qnote` |  |
| `Ctrl + Space` | `polybar-msg cmd toggle` |  |
| `Alt + ]` | `bspc desktop -f next` |  |
| `Alt + [` | `bspc desktop -f prev` |  |
| `Super + Space` | `super space changed here 1234` | changed also here |
| `Alt + CapsLock` | `firefox -new-window "https://grok.com"; sleep 2; xdotool key Caps_Lock; xdotool key ctrl+shift+j` |  |

## st

`~/st/config.h`

| Keybind | Action | Description |
|---|---|---|
| `Alt + =` | `zoom +4` | changed to be 4 zoom |
| `Alt + -` | `zoom -1` |  |
| `Alt + Home` | `zoomreset` |  |
| `Ctrl + C` | `clipcopy` | couple |
| `Shift + Insert` | `clippaste` | only a couple here |

## XKB

`setxkbmap -query, /etc/X11/xorg.conf.d/00-keyboard.conf`

| Keybind | Action | Description |
|---|---|---|
| `Ctrl + Alt + Backspace` | `terminate:ctrl_alt_bksp` | Key sequence to kill the X server |

## zsh

`~/.zshrc`

| Keybind | Action |
|---|---|
| `Alt + R` | `autosuggest-accept` |
| `Alt + G` | `beginning-of-line` |
| `Alt + K` | `end-of-line` |

