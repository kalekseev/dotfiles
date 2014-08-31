#!/bin/bash

echo "Install packages"
packages=("wmctrl"  "tmux"  "xclip"  "rxvt-unicode"  "git"  "zsh")

if dpkg -l "${packages[@]}" | grep "^ii" > /dev/null 2>&1; then
    echo "Everything installed"
else
    sudo apt-get install --yes "${packages[@]}"
fi

echo "done"
