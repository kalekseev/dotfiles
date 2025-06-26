# Based on https://github.com/mitchellh/nixos-config
{
  pkgs,
  ...
}:
{
  imports = [ ./hardware/vm-aarch64.nix ];
  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  # Setup qemu so we can run x86_64 binaries
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";

  # Define your hostname.
  networking.hostName = "dev";

  # Set your timezone.
  time.timeZone = "Asia/Nicosia";

  # Interface is this on M1
  networking.interfaces.ens160.useDHCP = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behavior.
  networking.useDHCP = false;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # This works through our custom module imported above
  virtualisation.vmware.guest.enable = true;

  # Share our host filesystem
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true; # default shell on catalina
  # programs.ssh.startAgent = true;
  # Virtualization settings
  virtualisation.docker.enable = true;
  virtualisation.lxd = {
    enable = true;
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-gtk
        fcitx5-hangul
        fcitx5-mozc
      ];
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;

  fonts = {
    fontDir.enable = true;
    packages = [ pkgs.nerd-fonts.hack ];
  };

  environment.systemPackages = with pkgs; [
    gnumake
    killall
    xclip
    pass
  ];

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  # Our default non-specialised desktop environment.
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    updateDbusEnvironment = true;
    # displayManager.sessionCommands = ''
    #   ${lib.getBin pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
    # '';
  };
  # programs.dconf.profiles.gdm.databases = [
  #   {
  #     settings."org/gnome/desktop/interface".scaling-factor = lib.gvariant.mkUint32 2;
  #   }
  # ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;
  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;

  system.stateVersion = "24.05";
}
