{ inputs }:
{ pkgs, ... }:
let
  isLinux = pkgs.stdenv.isLinux;
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "hmb";
  home-manager.useUserPackages = true;
  users.users.konstantin =
    {
      name = "konstantin";
    }
    // (
      if isLinux then
        {
          home = "/home/konstantin";
          isNormalUser = true;
          extraGroups = [
            "docker"
            "lxd"
            "wheel"
          ];
          shell = pkgs.zsh;
          hashedPassword = "$y$j9T$UIMF2LshkToIJfrHjvez//$J4uKw8olt5mReBll0EG5dVKEv6c..gitDtBhFnfjN33";
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5YD9sWEjZTxjZEiSE62Qk8SHYiVKrIRy/GCcMF0m8H kalekseev"
          ];
        }
      else
        {
          home = "/Users/konstantin";
        }

    );
  home-manager.users.konstantin =
    { pkgs, lib, ... }:
    (
      if isLinux then
        {
          # gpg --generate-key
          # pass init <key-id>
          programs.gpg = {
            enable = true;
          };
          services.gpg-agent = {
            enable = true;
            extraConfig = ''
              pinentry-program ${lib.getExe pkgs.pinentry-curses}
            '';
          };
        }
      else
        { }
    )
    // {

      home.packages =
        [
          ((import ./packages/neovim/neovim.nix) { inherit pkgs inputs; })
          pkgs.aws-vault
          pkgs.aider-chat
          pkgs.devenv
          pkgs.llama-cpp
          pkgs.uv
          pkgs.dotnet-sdk_8
          pkgs.fd
          pkgs.ffmpeg
          pkgs.ollama
          pkgs.rustup
          pkgs.sd
          pkgs.timewarrior
          pkgs.tree
          pkgs.claude-code
          # pkgs.testdisk
          pkgs.watch
          pkgs.yubikey-manager
        ]
        ++ lib.optionals (isLinux) [
          pkgs.chromium
          pkgs.chromedriver
        ];
      home.stateVersion = "24.05";

      home.sessionVariables =
        {
          PIP_REQUIRE_VIRTUALENV = "true";
          COMPOSE_DOCKER_CLI_BUILD = "true";
          DOCKER_BUILDKIT = "true";
          EDITOR = "nvim";
          DIRENV_LOG_FORMAT = "`tput setaf 11`%s`tput sgr0`";
          DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
          DO_NOT_TRACK = "1";
        }
        // lib.optionalAttrs (isLinux) {
          AWS_VAULT_BACKEND = "pass";
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
        # ".config/ghostty/config".source = ./configs/ghostty.toml;
      };

      programs.zsh = {
        enable = true;
        initContent = ''
          portkill() { kill -15 $(lsof -ti :''${1:-8000} -sTCP:LISTEN) }
          mkcd() { mkdir -p "$1" && cd "$1" }
          cdsitepackages() {
              cd $(python -c 'import site; print(site.getsitepackages()[0])')
          }
          bindkey -e
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
          ".aider.*"
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

      programs.ghostty = {
        enable = true;
        package = if isLinux then pkgs.ghostty else null;
        enableZshIntegration = true;
        settings = {
          theme = "Sublette";
          font-family = "Hack Nerd Font Mono";
          macos-non-native-fullscreen = true;
          macos-titlebar-style = "tabs";
          font-size = if isLinux then 14 else 16;
          font-thicken = true;
          auto-update-channel = "stable";
          window-save-state = "always";
          shell-integration-features = "sudo";
        };
      };
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
}
