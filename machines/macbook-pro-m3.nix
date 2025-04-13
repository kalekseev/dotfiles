{ inputs }:
{ pkgs, ... }:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget

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
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

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
  security.pam.services.sudo_local.touchIdAuth = true;

  fonts.packages = [ pkgs.nerd-fonts.hack ];

  homebrew = {
    enable = true;
    global.autoUpdate = true;
    onActivation.cleanup = "zap";
    casks = [
      "bitwarden"
      "cursor"
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
}
