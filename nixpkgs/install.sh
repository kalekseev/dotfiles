#!/usr/bin/env bash

mkdir -p ~/.config
cd ~/.config/
ln -s ~/dotfiles/nixpkgs .
exec nix-env -f '<nixpkgs>' -r -iA userPackages
