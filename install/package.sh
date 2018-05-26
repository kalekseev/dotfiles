#!/bin/bash

echo "Install packages"
packages=("tmux"  "xclip"  "git"  "zsh" "mercurial")

if dpkg -l "${packages[@]}" | grep "^ii" > /dev/null 2>&1; then
    sudo apt install --yes "${packages[@]}"
else
    echo "Everything installed"
fi

echo "done"
