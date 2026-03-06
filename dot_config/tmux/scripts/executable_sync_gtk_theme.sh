#!/usr/bin/env bash

colors_file="$HOME/.config/tmux/colors.conf"

fg_hex=$(grep '@thm_fg' "$colors_file" | cut -d'"' -f2 | tr -d '#')

if [ -z "$fg_hex" ]; then
  exit 0
fi

red=$(printf "%d" 0x${fg_hex:0:2})
green=$(printf "%d" 0x${fg_hex:2:2})
blue=$(printf "%d" 0x${fg_hex:4:2})

brightness=$(echo "scale=0; ($red * 299 + $green * 587 + $blue * 114) / 1000" | bc)

if [ "$brightness" -lt 128 ]; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
else
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
fi
