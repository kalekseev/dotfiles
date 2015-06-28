#!/bin/bash

echo "Linking dotjs"

cd ~
src=~/Dropbox/.stuff/css
dst=~/.css

if [ ! -L "$dst" ]; then
  ln -sf "$src" "$dst"
fi

src=~/Dropbox/.stuff/js
dst=~/.js

if [ ! -L "$dst" ]; then
  ln -sf "$src" "$dst"
fi

echo "done"
