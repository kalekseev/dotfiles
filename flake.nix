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
    vim-coverage-py.url = "github:kalekseev/vim-coverage.py/0cabe076776640988c245a9eb640da2e6f4b2bc4";
    vim-coverage-py.flake = false;
    vim-qfreplace.url = "github:thinca/vim-qfreplace/db1c4b0161931c9a63942f4f562a0d0f4271ac14";
    vim-qfreplace.flake = false;
    webster-dictionary.url = "https://github.com/websterParser/WebsterParser/releases/download/v2.0.2/websters-1913.dictionary.zip";
    webster-dictionary.flake = false;
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      flake-utils,
      ...
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          nix = {
            package = pkgs.nix;
            settings = {
              "extra-experimental-features" = [
                "nix-command"
                "flakes"
              ];
            };
          };

          system.activationScripts.postUserActivation.text = ''
            printf >&2 'setting up dictionaries...\n'
            mkdir -p ~/Library/Dictionaries
            ${pkgs.rsync}/bin/rsync \
              --archive \
              --copy-links \
              --delete-during \
              --delete-missing-args \
              ${inputs.webster-dictionary}/* \
              ~/Library/Dictionaries/"Webster's Unabridged Dictionary (1913).dictionary"
          '';

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          nix.settings.trusted-users = [
            "root"
            "konstantin"
          ];

          # Create /etc/zshrc that loads the nix-darwin environment.
          programs.zsh.enable = true; # default shell on catalina
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 4;

          system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;
          system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
          system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
          system.defaults.NSGlobalDomain.KeyRepeat = 2;
          system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
          system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
          system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
          system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
          system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
          system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
          system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;

          system.defaults.dock.autohide = true;
          system.defaults.dock.orientation = "left";
          system.defaults.dock.showhidden = true;

          system.defaults.finder.AppleShowAllExtensions = true;
          system.defaults.finder.QuitMenuItem = true;
          system.defaults.finder.FXEnableExtensionChangeWarning = false;

          system.defaults.trackpad.Clicking = true;
          # system.defaults.trackpad.TrackpadThreeFingerDrag = true;

          system.keyboard.enableKeyMapping = true;
          system.keyboard.remapCapsLockToControl = true;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          nixpkgs.config.allowUnfree = true;

          # nixpkgs.overlays = [ ];
          # macos
          security.pam.enableSudoTouchIdAuth = true;

          fonts.packages = [ pkgs.nerd-fonts.hack ];

          homebrew = {
            enable = true;
            global.autoUpdate = true;
            onActivation.cleanup = "zap";
            casks = [
              "bitwarden"
              "firefox"
              "google-chrome"
              "iina"
              "imazing"
              "nordvpn"
              "obsidian"
              "onedrive"
              "orbstack"
              "outline-manager"
              "qlvideo"
              "raycast"
              "rectangle"
              "samsung-portable-ssd-t7"
              "spotify"
              "tailscale"
              "telegram"
              "transmission"
              "vmware-fusion"
              "zed"
              "zoom"
              "microsoft-teams"
            ];
          };
        };

      homeManagerConfig = {
        home-manager.useGlobalPkgs = true;
        home-manager.backupFileExtension = "hmb";
        home-manager.useUserPackages = true;
        users.users.konstantin = {
          name = "konstantin";
          home = "/Users/konstantin";
        };
        home-manager.users.konstantin =
          { pkgs, ... }:
          {
            home.packages = [
              ((import ./packages/neovim/neovim.nix) { inherit pkgs inputs; }).neovim
              pkgs.aws-vault
              pkgs.aider-chat
              pkgs.uv
              pkgs.dotnet-sdk_8
              pkgs.fd
              pkgs.ffmpeg
              pkgs.ollama
              pkgs.rustup
              pkgs.sd
              pkgs.timewarrior
              pkgs.tree
              # pkgs.testdisk
              pkgs.watch
              pkgs.yubikey-manager
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
              ".psqlrc".source = ./configs/psqlrc;
              ".config/ghostty/config".source = ./configs/ghostty.toml;
            };

            programs.zsh = {
              enable = true;
              initExtra = ''
                portkill() { kill -15 $(lsof -ti :''${1:-8000} -sTCP:LISTEN) }
                mkcd() { mkdir -p "$1" && cd "$1" }
                cdsitepackages() {
                    cd $(python -c 'import site; print(site.getsitepackages()[0])')
                }
                bindkey "^[[1;3C" forward-word
                bindkey "^[[1;3D" backward-word
              '';
            };

            programs.direnv = {
              enable = true;
              enableZshIntegration = true;
              config = {
                hide_env_diff = true;
              };
              nix-direnv.enable = true;
            };
            programs.atuin.enable = true;
            programs.atuin.settings = {
              sync = {
                records = true;
              };
              enter_accept = true;
              auto_sync = true;
              search_mode_shell_up_key_binding = "prefix";
              history_filter = [ "chamber write " ];
            };
            programs.bat = {
              enable = true;
              config.theme = "TwoDark";
            };
            programs.gh.enable = true;
            programs.htop.enable = true;
            programs.jq.enable = true;
            programs.starship = {
              enable = true;
              settings = {
                format = "$all$timew";

                python = {
                  format = ''via [''${symbol}''${pyenv_prefix}(''${version} )]($style)'';
                  disabled = true;
                };

                nodejs = {
                  disabled = true;
                };

                package = {
                  disabled = true;
                };

                custom = {
                  timew = {
                    command = "echo $(timew|head -1|cut -d ' ' -f2-)";
                    when = " timew ";
                    format = "tracking [$output]($style) ";
                    style = "yellow";
                  };
                };
              };
            };
            programs.ripgrep.enable = true;

            programs.git = {
              enable = true;
              ignores = [
                "*.local"
                "*.pyc"
                ".DS_Store"
                ".direnv"
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
              includes = [ { path = "~/.gitconfig.local"; } ];
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
            # programs.kitty = {
            #   enable = true;
            #   extraConfig = builtins.readFile ./configs/kitty.conf;
            # };

            programs.tmux = {
              enable = true;
              sensibleOnTop = false;
              baseIndex = 1;
              escapeTime = 10;
              historyLimit = 10000;
              mouse = true;
              keyMode = "vi";
              customPaneNavigationAndResize = true;
              prefix = "C-a";
              terminal = "screen-256color";
              aggressiveResize = true;
              extraConfig = builtins.readFile ./configs/tmux.conf;
              plugins = [
                pkgs.tmuxPlugins.cpu
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
      # $ darwin-rebuild build --flake .#macbook-pro-m3
      darwinConfigurations."macbook-pro-m3" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          homeManagerConfig
        ];
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = {
          neovim = ((import ./packages/neovim/neovim.nix) { inherit pkgs inputs; }).neovim;
        };
      }
    );
}
