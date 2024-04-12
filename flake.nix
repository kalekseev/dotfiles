{
  description = "kalekseev nix configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      # problems:
      # https://github.com/NixOS/nix/issues/2982
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nix-darwin, nixpkgs, home-manager, flake-utils }:
    let
      configuration = { pkgs, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget

        # Auto upgrade nix package and the daemon service.
        services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        nix.settings.trusted-users = [ "root" "konstantin" ];

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

        homebrew = {
          enable = true;
          global.autoUpdate = true;
          onActivation.cleanup = "zap";
          casks = [
            "chatbox"
            "discord"
            "firefox"
            "google-chrome"
            "iina"
            "imazing"
            "onedrive"
            "orbstack"
            "qlvideo"
            "raycast"
            "rectangle"
            "skype"
            "spotify"
            "telegram"
            "transmission"
            "vmware-fusion"
            "yubico-yubikey-manager"
            "zoom"
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
            ((import ./packages/neovim/neovim.nix) pkgs).neovim
            pkgs.aws-vault
            pkgs.cachix
            pkgs.chromedriver
            pkgs.devenv
            pkgs.dotnet-sdk_8
            pkgs.fd
            pkgs.ffmpeg
            pkgs.geckodriver
            pkgs.rustup
            pkgs.sd
            pkgs.sox
            pkgs.timewarrior
            pkgs.tree
            pkgs.watch
          ];
          home.stateVersion = "24.05";

          home.sessionVariables = {
            PIP_REQUIRE_VIRTUALENV = "true";
            COMPOSE_DOCKER_CLI_BUILD = "true";
            DOCKER_BUILDKIT = "true";
            EDITOR = "nvim";
            DIRENV_LOG_FORMAT = "`tput setaf 11`%s`tput sgr0`";
            DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
          };

          home.shellAliases = {
            g = "git";
            gs = "git status";
            gp = "git push";
            gl = "git pull";
            gd = "git diff";
            vim = "nvim";
            da = "django-admin";
          };

          home.file = {
            ".psqlrc".source = ./_psqlrc;
          };

          programs.zsh = {
            enable = true;
            oh-my-zsh.enable = true;
            oh-my-zsh.plugins = [
              "macos"
              "virtualenv"
              "pip"
            ];
            initExtra = ''
              portkill() { kill -15 $(lsof -ti :''${1:-8000} -sTCP:LISTEN) }
              mkcd() { mkdir -p "$1" && cd "$1" }
              cdsitepackages() {
                  cd $(python -c 'import site; print(site.getsitepackages()[0])')
              }
            '';
          };

          programs.direnv.enable = true;
          programs.direnv.config = { hide_env_diff = true; };
          programs.atuin.enable = true;
          programs.bat.enable = true;
          programs.gh.enable = true;
          programs.htop.enable = true;
          programs.jq.enable = true;
          programs.starship.enable = true;
          programs.ripgrep.enable = true;

          programs.git = {
            enable = true;
            ignores = [
              "*.local"
              "*.pyc"
              ".DS_Store"
            ];
            aliases = {
              co = "checkout";
              fomo = "!git fetch && git rebase origin/master";
              hist = "log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short";
              up = "!git remote update -p && git merge --ff-only @{u}";
              # Show branches, verbosely, sorted by last touch, with commit messages.
              brv = "!f() { git branch --sort=-creatordate --color=always --format='%(color:reset)%(creatordate:short) %(color:bold white)%(align:2,right)%(upstream:trackshort)%(end)%(color:nobold) %(align:40,left)%(color:yellow)%(refname:short)%(end) %(color:reset)%(contents:subject)'; }; f";
            };
            difftastic = {
              enable = true;
              background = "light";
            };
            includes = [
              { path = "~/.gitconfig.local"; }
            ];
            extraConfig = {

              core.editor = "nvim";
              github.user = "kalekseev";
              color.ui = "auto";
              color.status = {
                added = "green";
                changed = "yellow";
                untracked = "cyan";
              };
              push.default = "current";
              pull.ff = "only";
              grep = {
                extendRegexp = true;
                lineNumber = true;
              };
              merge = {
                tool = "vimdiff";
                conflictstyle = "zdiff3";
              };
              mergetool = {
                prompt = false;
                keepBackup = false;
                vimdiff.cmd = "nvim -d $LOCAL $BASE $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";
                p4merge.cmd = "p4merge $BASE $LOCAL $REMOTE $MERGED";
              };
              init.defaultBranch = "main";
              diff.algorithm = "histogram";
              pager.difftool = true;
              rerere.enabled = true;
              branch.sort = "-committerdate";
              rebase = {
                autosquash = true;
                autostash = true;
              };
            };
            lfs.enable = true;
            lfs.skipSmudge = true;
          };
          # https://nix-community.github.io/home-manager/options.xhtml
          programs.kitty = {
            enable = true;
            extraConfig = builtins.readFile ./kitty.conf;
            shellIntegration.enableZshIntegration = false;
          };

          programs.tmux = {
            enable = true;
            baseIndex = 1;
            escapeTime = 10;
            historyLimit = 10000;
            mouse = true;
            prefix = "C-a";
            extraConfig = builtins.readFile ./tmux.conf;
            plugins = [
              pkgs.tmuxPlugins.cpu
              pkgs.tmuxPlugins.sensible
              pkgs.tmuxPlugins.yank
              pkgs.tmuxPlugins.copycat
              pkgs.tmuxPlugins.open
              pkgs.tmuxPlugins.resurrect
            ];
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
          neovim = ((import ./packages/neovim/neovim.nix) pkgs).neovim;
        };
      });
}
