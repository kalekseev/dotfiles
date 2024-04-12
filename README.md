# Nix System Configurations


## MacOS

Install: 

- install Nix https://github.com/DeterminateSystems/nix-installer
- install homebrew (MacOS) https://brew.sh
- `nix run nix-darwin -- switch --flake github:kalekseev/dotfiles#macbook-pro-m1`


Applying updates:

    cd
    git clone https://github.com/kalekseev/dotfiles.git
    # edit ~/dotfiles/
    darwin-rebuild switch --flake ~/dotfiles#macbook-pro-m1


## Packages

- neovim - `nix run github:kalekseev/dotfiles#neovim`
