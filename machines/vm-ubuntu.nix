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
    (
      { lib, ... }:
      {
        home.username = "konstantin";
        home.homeDirectory = "/home/konstantin";
        programs.home-manager.enable = true;
        # Real file required: sshd StrictModes rejects authorized_keys symlinked
        # into /nix/store ("bad ownership or modes for directory /nix/store").
        home.activation.sshAuthorizedKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/.ssh"
          chmod 700 "$HOME/.ssh"
          # Drop HM symlink if present, then write a normal file.
          rm -f "$HOME/.ssh/authorized_keys"
          cat >"$HOME/.ssh/authorized_keys" <<'EOF'
          ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5YD9sWEjZTxjZEiSE62Qk8SHYiVKrIRy/GCcMF0m8H kalekseev
          EOF
          # Strip leading indentation from heredoc lines
          sed -i 's/^[[:space:]]*//' "$HOME/.ssh/authorized_keys"
          chmod 600 "$HOME/.ssh/authorized_keys"
        '';
      }
    )
  ];
}
