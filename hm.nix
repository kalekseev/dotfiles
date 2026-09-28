{
  inputs,
  isNFS ? false, # Is on Network File System i.e. VM disk
}:
{ pkgs, lib, ... }:
{

  home.packages = [
    ((import ./packages/neovim/neovim.nix) { inherit pkgs inputs; })
    (pkgs.callPackage ./packages/sentry-cli { })
    pkgs.aws-vault
    pkgs.llama-cpp
    pkgs.uv
    pkgs.qemu
    pkgs.dotnet-sdk_10
    pkgs.fd
    pkgs.ffmpeg
    pkgs.rustup
    pkgs.sd
    pkgs.timewarrior
    inputs.llm-agents-codex.packages.${pkgs.stdenv.hostPlatform.system}.codex
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr
    ((inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code.override {
      # sets DISABLE_TELEMETRY=1 and CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
      disableTelemetry = true;
    }).overrideAttrs
      (old: {
        # no "Co-Authored-By: Claude" in commits; injected into the existing
        # wrapProgram call to avoid double-wrapping
        postFixup =
          builtins.replaceStrings
            [ "--argv0 claude" ]
            [ "--argv0 claude --add-flags \"--settings '{\\\"includeCoAuthoredBy\\\":false}'\"" ]
            old.postFixup;
      })
    )
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccusage
    # inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    # inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.gemini-cli
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex-auth
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hunk
    pkgs.nodejs
    pkgs.pnpm
    # pkgs.testdisk
    # pkgs.yubikey-manager
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    (pkgs.callPackage ./packages/fastmail-cli { })
  ];
  home.stateVersion = "24.05";

  home.sessionVariables = {
    PIP_REQUIRE_VIRTUALENV = "true";
    COMPOSE_DOCKER_CLI_BUILD = "true";
    DOCKER_BUILDKIT = "true";
    EDITOR = "nvim";
    DIRENV_LOG_FORMAT = "`tput setaf 11`%s`tput sgr0`";
    DOTNET_ROOT = "${pkgs.dotnet-sdk_10}";
    DO_NOT_TRACK = "1";
  }
  // lib.optionalAttrs (pkgs.stdenv.isLinux) {
    AWS_VAULT_BACKEND = "pass";
  }
  // lib.optionalAttrs (pkgs.stdenv.isDarwin) {
    SSH_AUTH_SOCK = "/Users/konstantin/.bitwarden-ssh-agent.sock";
  };

  # Hide the current input source bubble next to the text cursor.
  targets.darwin.defaults.NSGlobalDomain.TSMLanguageIndicatorEnabled = false;

  home.shellAliases = {
    g = "git";
    gs = "git status";
    gp = "git push";
    gl = "git pull";
    grom = "git grom";
    gd = "git -c diff.external=difft diff";
    vim = "nvim";
    da = "django-admin";
  };

  home.file = {
    ".psqlrc".source = ./configs/psqlrc;
  };

  # Maintain Spotlight Search Privacy exclusions on activation.
  home.activation.spotlightExclusions = lib.mkIf pkgs.stdenv.isDarwin (
    let
      spotlightExclusions = pkgs.callPackage ./packages/spotlight-exclusions { };
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run /bin/mkdir -p "$HOME/code"
      spotlight_paths=("$HOME/code")

      t7_dir="/Volumes/T7 Shield"
      if [ -d "$t7_dir" ]; then
        spotlight_paths+=("$t7_dir")
      fi

      run ${lib.getExe spotlightExclusions} "''${spotlight_paths[@]}"
    ''
  );

  # Periodically garbage collect old per-user (home-manager) generations.
  # The system-level nix.gc runs as root and does not trim these.
  systemd.user.services.nix-user-gc = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "Garbage collect old home-manager generations";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 14d";
    };
  };
  systemd.user.timers.nix-user-gc = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "Weekly home-manager garbage collection";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  launchd.agents.nix-user-gc = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.nix}/bin/nix-collect-garbage"
        "--delete-older-than"
        "14d"
      ];
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 8;
          Minute = 30;
        }
      ];
    };
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

      # eval "$(${
        inputs.try.packages.${pkgs.stdenv.hostPlatform.system}.default
      }/bin/try init ~/code/experiments)"
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
  programs.atuin.daemon.enable = isNFS;
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
      follow_symlinks = !isNFS;

      python = {
        format = "via [\${symbol}\${pyenv_prefix}(\${version} )]($style)";
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

  programs.difftastic = {
    enable = true;
    git.enable = false;
    options = {
      background = "light";
    };
  };
  programs.git = {
    enable = true;
    signing.format = null;
    ignores = [
      "*.local"
      "*.pyc"
      ".DS_Store"
      ".direnv"
      ".aider.*"
    ];
    settings = {
      alias = {
        co = "checkout";
        fomo = ''
          !f() {
            git fetch origin || return
            if git show-ref --verify --quiet refs/remotes/origin/main; then
              git rebase origin/main "$@"
            else
              git rebase origin/master "$@"
            fi
          }; f
        '';
        hist = "log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short";
        up = "!git remote update -p && git merge --ff-only @{u}";
        # Show branches, verbosely, sorted by last touch, with commit messages.
        brv = "!f() { git branch --sort=-creatordate --color=always --format='%(color:reset)%(creatordate:short) %(color:bold white)%(align:2,right)%(upstream:trackshort)%(end)%(color:nobold) %(align:40,left)%(color:yellow)%(refname:short)%(end) %(color:reset)%(contents:subject)'; }; f";
      };
      core = {
        editor = "nvim";
        untrackedCache = true;
      };
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
        tool = "fugitive";
        conflictstyle = "zdiff3";
      };
      mergetool = {
        prompt = false;
        keepBackup = false;
        vimdiff.cmd = "nvim -d $LOCAL $BASE $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";
        p4merge.cmd = "p4merge $BASE $LOCAL $REMOTE $MERGED";
        fugitive.cmd = ''nvim -f "$MERGED" -c "Gvdiffsplit!"'';
        fugitive.trustExitCode = true;
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
    includes = [ { path = "~/.gitconfig.local"; } ];
    lfs.enable = true;
    lfs.skipSmudge = true;
  };
  programs.ssh = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "~/.orbstack/ssh/config" ];
    settings = {
      "*" = {
        IdentityAgent = "~/.bitwarden-ssh-agent.sock";
        IdentityFile = "none";
      };
      "192.168.234.11 vm-ubuntu" = {
        HostName = "192.168.234.11";
        User = "konstantin";
        ForwardAgent = true;
      };
      "192.168.234.10 vm-aarch64" = {
        HostName = "192.168.234.10";
        User = "konstantin";
        ForwardAgent = true;
      };
      "i-*" = {
        User = "ec2-user";
        ProxyCommand = "sh -c \"aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'\"";
      };
    };
  };
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isLinux then pkgs.ghostty else null;
    enableZshIntegration = true;
    settings = {
      theme = "Sublette";
      font-family = "Hack Nerd Font Mono";
      macos-non-native-fullscreen = true;
      macos-titlebar-style = "tabs";
      font-size = if pkgs.stdenv.isLinux then 14 else 16;
      font-thicken = true;
      auto-update-channel = "stable";
      window-save-state = "always";
      shell-integration-features = "sudo";
      keybind = [
        "cmd+w=close_surface"
        "super+right_bracket=goto_split:next"
        "super+left_bracket=goto_split:previous"
      ];
      # command-palette-entry = [ "title:Close surface.,action:close_surface" ];
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
}
