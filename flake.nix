{
  description = "kalekseev nix configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, flake-utils }:
    let
      configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        programs.zsh.enable = true; # default shell on catalina
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        nixpkgs.config.allowUnfree = true;

        # macos
        security.pam.enableSudoTouchIdAuth = true;

        fonts = {
          fontDir.enable = true;
          fonts = [
            (pkgs.nerdfonts.override { fonts = [ "Hack" ]; })
          ];
        };

      };
      homeManagerConfig = {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        users.users.konstantin = {
          name = "konstantin";
          home = "/Users/konstantin";
        };
        home-manager.users.konstantin = { pkgs, ... }: {
          home.packages = [
            ((import ./nixpkgs/overlays/neovim.nix) pkgs pkgs).userPackages.neovim
            ((import ./nixpkgs/overlays/tmux.nix) pkgs pkgs).userPackages.tmux
            pkgs.atuin
            pkgs.aws-vault
            pkgs.bat
            pkgs.bat
            pkgs.cachix
            pkgs.chromedriver
            pkgs.devenv
            pkgs.difftastic
            pkgs.direnv
            pkgs.dotnet-sdk_8
            pkgs.fd
            pkgs.ffmpeg
            pkgs.geckodriver
            pkgs.gh
            pkgs.git
            pkgs.git-lfs
            pkgs.htop
            pkgs.jq
            pkgs.opam
            pkgs.ripgrep
            pkgs.rustup
            pkgs.sd
            pkgs.sox
            pkgs.starship
            pkgs.timewarrior
            pkgs.tree
            pkgs.watch
          ];
          home.stateVersion = "24.05";
          # https://nix-community.github.io/home-manager/options.xhtml
          programs.kitty = {
            enable = true;
            extraConfig = builtins.readFile ./kitty.conf;
          };
        };
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#macbook-pro-m1
      darwinConfigurations."macbook-pro-m1" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration

          home-manager.darwinModules.home-manager
          homeManagerConfig
        ];
      };

    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = {
          neovim = ((import ./nixpkgs/overlays/neovim.nix) pkgs pkgs).userPackages.neovim;
        };
      });
}
