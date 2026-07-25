{
  inputs,
  nixpkgs,
  home-manager,
}:
home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "aarch64-linux";
    config.allowUnfree = true;
  };
  modules = [
    (import ../hm.nix { inherit inputs; })
    {
      home.username = "konstantin";
      home.homeDirectory = "/home/konstantin";
      programs.home-manager.enable = true;
      home.file.".ssh/authorized_keys".text = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5YD9sWEjZTxjZEiSE62Qk8SHYiVKrIRy/GCcMF0m8H kalekseev
      '';
    }
  ];
}
