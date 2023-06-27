# example https://github.com/DieracDelta/vimconf_talk/blob/5_ci/flake.nix
{
  description = "My neovim flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs
          {
            inherit system;
            overlays = [
              (final: prev: { neovim = ((import ./nixpkgs/overlays/neovim.nix) final prev).userPackages.neovim; })
              (final: prev: { tmux = ((import ./nixpkgs/overlays/tmux.nix) final prev).userPackages.tmux; })
            ];
            config = { allowUnfree = true; };
          };
      in
      {
        packages = {
          inherit (pkgs)
            neovim
            tmux;
        };
      });
}
