#!/bin/bash
cd ~
for f in `ls ~/dotfiles`
do
    if [ -f ~/dotfiles/$f ]
    then
        rm .$f 2>/dev/null
        ln -s dotfiles/$f .$f
    fi
done

for d in urxvt
do
    rm .$d 2>/dev/null
    ln -s dotfiles/$d .$d
done

sudo apt-get install --yes wmctrl tmux xclip rxvt-unicode
xrdb .Xresources
