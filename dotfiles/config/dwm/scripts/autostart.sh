#!/bin/sh

slstatus &

# polkit
lxpolkit &

# background
feh --bg-scale ~/Pictures/wallpapers/* &

# sxhkd
# (re)load sxhkd for keybinds
if hash sxhkd >/dev/null 2>&1; then
  pkill sxhkd
  sleep 0.5
  sxhkd -c "$HOME/.config/dwm/sxhkd/sxhkdrc" &
fi

dunst -config ~/.config/dwm/dunst/dunstrc &
#picom --config ~/.config/dwm/picom/picom.conf -b &

# hide cursor when idle (mitigates dwm sloppy-focus typing-in-wrong-window)
# optional — install with `apt install unclutter`
if command -v unclutter >/dev/null 2>&1; then
  unclutter -idle 1 -root &
fi

# First-login welcome (shown once, dismissable)
#if [ ! -f "$HOME/.cache/dwm/welcomed" ]; then
#  mkdir -p "$HOME/.cache/dwm"
#  touch "$HOME/.cache/dwm/welcomed"
#  (
#    sleep 3
#    notify-send -u normal -t 15000 \
#      "Welcome to dwm" \
#      "Press Super + / anytime to see all keybindings.&#10;See ~/QUICKSTART-dwm.md for a cheat sheet."
#  ) &
#fi
