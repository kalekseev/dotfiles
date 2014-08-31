#!/bin/bash

echo "Linking fonts"

cd ~
src=~/Dropbox/.stuff/fonts
dst=~/.fonts

if [ ! -L "$dst" ]; then
  ln -sf "$src" "$dst"
fi

echo "done"
