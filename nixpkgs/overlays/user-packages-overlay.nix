self: super:

{
  userPackages = super.userPackages or {} // {
    ### apps
    mailhog = self.mailhog;
    neovim = self.neovim;
    tmux = self.tmux;
    ### shell utils
    bat = self.bat;
    starship = self.starship;
    delta = self.gitAndTools.delta;
    gh = self.gitAndTools.gh;
    direnv = self.direnv;
    fd = self.fd;
    icdiff = self.icdiff;
    jq = self.jq;
    overmind = self.overmind;
    pre-commit = self.pre-commit;
    ripgrep = self.ripgrep;
    rsync = self.rsync;
    shellcheck = self.shellcheck;
    skim = self.skim;
    watchman = self.watchman;
    z-lua = self.z-lua;
    # global = self.global;
    # ctags = self.ctags;
    ### cloud
    aws-vault = self.aws-vault;
    awscli2 = self.awscli2;
    chamber = self.chamber;
    packer = self.packer;
    amazon-ecr-credential-helper = self.amazon-ecr-credential-helper;
    ### js
    nodejs-12_x = self.nodejs-12_x;
    npm-check-updates = self.nodePackages.npm-check-updates;
    yarn = self.yarn;
    ### python
    python38Full = self.python38Full;
    black = self.black;
    flake8 = self.python38Packages.flake8;
    isort = self.python38Packages.isort;
    pipenv = self.pipenv;
    tox = self.python38Packages.tox;
    ### nix utils
    vgo2nix = self.vgo2nix;
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
        versionText = super.lib.strings.concatMapStrings (s: s+"\n") versions;
      in
      super.writeTextDir "package_versions" versionText;
  };
}
