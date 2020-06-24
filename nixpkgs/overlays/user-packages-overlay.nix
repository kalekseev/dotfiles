self: super:

{
  userPackages = super.userPackages or {} // {
    ### apps
    neovim = self.neovim;
    tmux = self.tmux;
    ### shell utils
    delta = self.gitAndTools.delta;
    bat = self.bat;
    fd = self.fd;
    jq = self.jq;
    skim = self.skim;
    ripgrep = self.ripgrep;
    direnv = self.direnv;
    z-lua = self.z-lua;
    overmind = self.overmind;
    aws-vault = self.aws-vault;
    mailhog = self.mailhog;
    # global = self.global;
    # ctags = self.ctags;
    ### js
    nodejs-12_x = self.nodejs-12_x;
    yarn = self.yarn;
    ### python
    black = self.python37Packages.black;
    isort = self.python37Packages.isort;
    flake8 = self.python37Packages.flake8;
    pipenv = self.pipenv;
    awscli = self.awscli;
    pre-commit = self.pre-commit;
    ### nix utils
    vgo2nix = self.vgo2nix;
    niv = self.niv;
    ### system
    inherit (self) cacert nix;

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
