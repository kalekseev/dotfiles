# Nix System Configurations


## MacOS

Setup steps: 

- Install Nix https://github.com/DeterminateSystems/nix-installer
- Install Homebrew https://brew.sh
- Setup home manager `nix --experimental-features "nix-command flakes" run nix-darwin -- switch --flake github:kalekseev/dotfiles#macbook-pro-m3`


Applying changes:

    git clone https://github.com/kalekseev/dotfiles.git
    # edit dotfiles/
    darwin-rebuild switch --flake dotfiles#macbook-pro-m3

Updating deps (flake.lock):

    nix flake update

## Packages

- neovim - `nix run github:kalekseev/dotfiles#neovim`
