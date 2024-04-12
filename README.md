# Nix System Configurations


## MacOS

Setup steps: 

- Install Nix https://github.com/DeterminateSystems/nix-installer
- Install Homebrew https://brew.sh
- `nix --experimental-features nix-command run nix-darwin -- switch --flake github:kalekseev/dotfiles#macbook-pro-m1`


Applying changes:

    cd
    git clone https://github.com/kalekseev/dotfiles.git
    # edit ~/dotfiles/
    darwin-rebuild switch --flake ~/dotfiles#macbook-pro-m1

Updating deps (flake.lock):

    nix flake update

## Packages

- neovim - `nix run github:kalekseev/dotfiles#neovim`
