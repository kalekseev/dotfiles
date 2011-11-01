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
