#!/usr/bin/env bash
set -e

mkdir -p ~/.config
cd ~/.config/
ln -s ~/dotfiles/nixpkgs .
exec nix-env -f '<nixpkgs>' -r -iA userPackages
