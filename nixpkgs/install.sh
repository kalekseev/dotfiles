#!/usr/bin/env bash
set -e

SOURCE=$PWD/overlays
mkdir -p "$HOME/.config/nixpkgs/overlays"
cd "$HOME/.config/nixpkgs/overlays"
ln -fs "$SOURCE"/* .
exec nix-env -f '<nixpkgs>' -r -iA userPackages
