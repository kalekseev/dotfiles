#!/bin/bash

base16_shell_dir=~/.config/base16-shell
base16_xresources_dir=~/.config/base16-xresources

if [ -e "$base16_shell_dir" ]; then
    cd "$base16_shell_dir" && git pull && echo "base16-shell repo updated"
else
    git clone https://github.com/chriskempson/base16-shell.git "$base16_shell_dir"
fi

if [ -e "$base16_xresources_dir" ]; then
    cd "$base16_xresources_dir" && git pull && echo "base16-xresources repo updated"
else
    git clone https://github.com/chriskempson/base16-xresources.git "$base16_xresources_dir"
fi

echo "done"
