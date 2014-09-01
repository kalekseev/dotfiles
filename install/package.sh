#!/bin/bash

echo "Install packages"
packages=("wmctrl"  "tmux"  "xclip"  "rxvt-unicode"  "git"  "zsh")

if dpkg -l "${packages[@]}" | grep "^ii" > /dev/null 2>&1; then
    sudo apt-get install --yes "${packages[@]}"
else
    echo "Everything installed"
fi

echo "done"
