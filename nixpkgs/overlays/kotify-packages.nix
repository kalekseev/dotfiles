self: super:

{
  userPackages = super.userPackages or { } // {
    direnv = self.direnv;
    docker-compose = self.docker-compose;
    geckodriver = self.geckodriver;
    gh = self.gitAndTools.gh;
    git = self.git;
    git-lfs = self.git-lfs;
    htop = self.htop;
    jq = self.jq;
    pre-commit = self.pre-commit;
    ripgrep = self.ripgrep;
    rsync = self.rsync;
    shellcheck = self.shellcheck;
    sqlite = self.sqlite;
    tmux = self.tmux;
    watchman = self.watchman;
    ### cloud
    amazon-ecr-credential-helper = self.amazon-ecr-credential-helper;
    aws-vault = self.aws-vault;
    awscli2 = self.awscli2;
    awslogs = self.awslogs;
    chamber = self.chamber;
    packer = self.packer;
    ssm-session-manager-plugin = self.ssm-session-manager-plugin;
    ### js
    nodejs-12_x = self.nodejs-12_x;
    npm-check-updates = self.nodePackages.npm-check-updates;
    yarn = self.yarn;
    ### python
    black = self.black;
    flake8 = self.python38Packages.flake8;
    isort = self.python38Packages.isort;
    pipenv = self.pipenv;
    python27Full = (self.python2.withPackages (ps: [ ps.virtualenv ]));
    python38Full = self.python38Full;
    tox = self.python38Packages.tox;
  } // super.lib.optionalAttrs super.stdenv.isDarwin {
    ### macos only
    chromedriver = self.chromedriver;
    reattach-to-user-namespace = self.reattach-to-user-namespace;
  } // {
    ### system
    inherit (self) cacert nixUnstable;

    nix-rebuild = super.writeScriptBin "nix-rebuild" ''
      #!${super.stdenv.shell}
      set -e
      if ! command -v nix-env &>/dev/null; then
        echo "warning: nix-env was not found in PATH, add nix to userPackages" >&2
        PATH=${self.nix}/bin:$PATH
      fi
      IFS=- read -r _ oldGen _ <<<"$(readlink "$(readlink ~/.nix-profile)")"
      oldVersions=$(readlink ~/.nix-profile/package_versions || echo "/dev/null")
      nix-env -f '<nixpkgs>' -r -iA userPackages "$@"
      IFS=- read -r _ newGen _ <<<"$(readlink "$(readlink ~/.nix-profile)")"
      ${self.diffutils}/bin/diff --color -u --label "generation $oldGen" $oldVersions \
        --label "generation $newGen" ~/.nix-profile/package_versions \
        || true
    '';

    packageVersions =
      let
        versions = super.lib.attrsets.mapAttrsToList (_: pkg: pkg.name) self.userPackages;
        versionText = super.lib.strings.concatMapStrings (s: s + "\n") versions;
      in
      super.writeTextDir "package_versions" versionText;
  };
}
