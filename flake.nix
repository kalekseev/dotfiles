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
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    nix-ai-tools.inputs.nixpkgs.follows = "nixpkgs";
    vim-coverage-py.url = "github:kalekseev/vim-coverage.py/0cabe076776640988c245a9eb640da2e6f4b2bc4";
    vim-coverage-py.flake = false;
    yank-for-claude-nvim.url = "github:wasabeef/yank-for-claude.nvim/5879059decfd16c2f983c0d27e0247fede5dff4d";
    yank-for-claude-nvim.flake = false;
    vim-qfreplace.url = "github:thinca/vim-qfreplace/db1c4b0161931c9a63942f4f562a0d0f4271ac14";
    vim-qfreplace.flake = false;
    webster-dictionary.url = "https://github.com/websterParser/WebsterParser/releases/download/v2.0.2/websters-1913.dictionary.zip";
    webster-dictionary.flake = false;
    llama-vim.url = "github:ggml-org/llama.vim/master";
    llama-vim.flake = false;
    fold-imports-nvim.url = "github:kalekseev/fold-imports.nvim";
    fold-imports-nvim.flake = false;
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
    {
      # nixos-rebuild switch --flake .#vm-aarch64
      nixosConfigurations.vm-aarch64 = nixpkgs.lib.nixosSystem {
        modules = [
          ./machines/vm-aarch64.nix
          (
            { pkgs, ... }:
            {

              users.users.konstantin = {
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
              };
            }
          )
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "hmb";
            home-manager.useUserPackages = true;
            home-manager.users.konstantin = (
              import ./hm.nix {
                inherit inputs;
                isNFS = true;
              }
            );
          }
        ];
      };
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#macbook-pro-m3
      darwinConfigurations."macbook-pro-m3" = nix-darwin.lib.darwinSystem {
        modules = [
          (import ./machines/macbook-pro-m3.nix { inherit inputs; })
          {
            users.users.konstantin = {
              name = "konstantin";
              home = "/Users/konstantin";
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.backupFileExtension = "hmb";
            home-manager.useUserPackages = true;
            home-manager.users.konstantin = (
              import ./hm.nix {
                inherit inputs;
              }
            );
          }
        ];
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        vmip = "192.168.234.133";
      in
      {
        packages = {
          neovim = ((import ./packages/neovim/neovim.nix) { inherit pkgs inputs; });
          vm-copy = pkgs.writeShellApplication {
            name = "vm-copy";
            runtimeInputs = [
              pkgs.rsync
            ];
            text = ''
              	rsync -av --exclude='.git/' . konstantin@${vmip}:/tmp/dotfiles
            '';
          };
          vm-secrets = pkgs.writeShellApplication {
            name = "vm-secrets";
            runtimeInputs = [
              pkgs.rsync
            ];
            text = ''
              	rsync -av ~/.aws/ konstantin@${vmip}:~/.aws
              	rsync -av ~/.ssh/ konstantin@${vmip}:~/.ssh
            '';
          };
          vm-switch = pkgs.writeShellApplication {
            name = "vm-switch";
            runtimeInputs = [
              pkgs.rsync
            ];
            text = ''
              ssh -o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no konstantin@${vmip} " \
                sudo NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --flake \"/tmp/dotfiles#vm-aarch64\" \
               "
            '';
          };
          vm-bootstrap0 = pkgs.writeShellApplication {
            name = "vm-bootstrap0";
            runtimeInputs = [
              pkgs.rsync
            ];
            text = ''
              ssh -o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@${vmip} " \
                parted /dev/nvme0n1 -- mklabel gpt; \
                parted /dev/nvme0n1 -- mkpart primary 512MB -8GB; \
                parted /dev/nvme0n1 -- mkpart primary linux-swap -8GB 100\%; \
                parted /dev/nvme0n1 -- mkpart ESP fat32 1MB 512MB; \
                parted /dev/nvme0n1 -- set 3 esp on; \
                sleep 1; \
                mkfs.ext4 -L nixos /dev/nvme0n1p1; \
                mkswap -L swap /dev/nvme0n1p2; \
                mkfs.fat -F 32 -n boot /dev/nvme0n1p3; \
                sleep 1; \
                mount /dev/disk/by-label/nixos /mnt; \
                mkdir -p /mnt/boot; \
                mount /dev/disk/by-label/boot /mnt/boot; \
                nixos-generate-config --root /mnt; \
                sed --in-place '/system\.stateVersion = .*/a \
                  nix.package = pkgs.nixVersions.latest;\n \
                  nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
                    services.openssh.enable = true;\n \
                  services.openssh.settings.PasswordAuthentication = true;\n \
                  services.openssh.settings.PermitRootLogin = \"yes\";\n \
                  users.users.root.initialPassword = \"root\";\n \
                ' /mnt/etc/nixos/configuration.nix; \
                nixos-install --no-root-passwd && reboot; \
              "
            '';
          };
        };
      }
    );
}
