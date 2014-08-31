#!/bin/bash

echo "Linking dotfiles"
cd ~

for file in ~/dotfiles/_*; do
    f=$(basename $file)
    f="$HOME/${f/_/.}"
    if [ ! -L "$f" ]; then
        ln -sf "$file" "$f"
        echo "$f ---> $file"
    fi
done

echo "done"
