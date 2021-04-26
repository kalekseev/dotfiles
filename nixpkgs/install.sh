#!/usr/bin/env bash
set -e

SOURCE=$PWD/overlays
cd "$HOME/.config/nixpkgs/overlays"
ln -fs "$SOURCE"/my-packages.nix .
exec nix-env -f '<nixpkgs>' -r -iA userPackages
