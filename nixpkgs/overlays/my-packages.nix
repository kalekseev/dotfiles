self: super:

{
  userPackages = super.userPackages or { } // {
    dos2unix = self.dos2unix;
    devd = self.devd;
    modd = self.modd;
    ticker = self.ticker;
    timewarrior = self.timewarrior;
    dotnet-sdk_6 = self.dotnet-sdk_6;
    graphviz = self.graphviz;
    # ocaml = self.ocaml-ng.ocamlPackages_5_0.ocaml;
    yt-dlp = self.yt-dlp;
    sql-formatter = super.nodePackages.sql-formatter.override {
      buildInputs = [ super.makeWrapper ];
      preFixup = ''
        wrapProgram $out/bin/sql-formatter --add-flags \
          '-l postgresql -c ${super.writeText "sql-formatter-config" ''{ "expressionWidth": 80, "keywordCase": "upper" }''}'
      '';
    };
    ### shell utils
    bat = self.bat;
    difftastic = self.difftastic;
    # pspg = self.pspg;
    # bindfs = self.bindfs;
    # unionfs-fuse = self.unionfs-fuse;
    starship = self.starship;
    fd = self.fd;
    sd = self.sd;
    icdiff = self.icdiff;
    z-lua = self.z-lua;
    nmap = self.nmap;
    ### nix utils
    nixpkgs-fmt = self.nixpkgs-fmt;
    nix-update = self.nix-update;
    ### custom
    ruff-lsp =
      let
        pkgs = super.python310.pkgs;
      in
      pkgs.buildPythonPackage
        rec {
          pname = "ruff-lsp";
          version = "0.0.24";
          format = "pyproject";
          disabled = pkgs.pythonOlder "3.7";

          src = pkgs.fetchPypi {
            inherit version;
            pname = "ruff_lsp";
            sha256 = "sha256-1he/GYk8O9LqPXH3mu7eGWuRygiDG1OnJ+JNT2Pynzo=";
          };

          nativeBuildInputs = [
            pkgs.hatchling
          ];

          nativeCheckInputs = [
            pkgs.unittestCheckHook
            pkgs.python-lsp-jsonrpc
            super.ruff
          ];

          propagatedBuildInputs = [
            pkgs.pygls
            pkgs.lsprotocol
            pkgs.typing-extensions
          ];

          postPatch = ''
            # ruff binary added to PATH in wrapper so it's not needed
            sed -i '/"ruff>=/d' pyproject.toml
          '';

          makeWrapperArgs = [
            # prefer ruff from user's PATH, that's usually desired behavior
            "--suffix PATH : ${super.lib.makeBinPath [ super.ruff ]}"
          ];

          meta = with super.lib; {
            homepage = "https://github.com/charliermarsh/ruff-lsp";
            description = "A Language Server Protocol implementation for Ruff";
            changelog = "https://github.com/charliermarsh/ruff-lsp/releases/tag/v${version}";
            license = licenses.mit;
            maintainers = with maintainers; [ kalekseev ];
          };
        };
    skim =
      let
        previewSrc = super.fetchurl {
          url = "https://raw.githubusercontent.com/junegunn/fzf.vim/0452b71830b1a219b8cdc68141ee58ec288ea711/bin/preview.sh";
          sha256 = "sha256-xAnde3In19gid3Fn1hlZZVCd/tIQLLmku0n9OsmOsIo=";
        };
        preview = super.writeShellScriptBin "preview.sh" (builtins.readFile previewSrc);
      in
      self.symlinkJoin {
        name = self.skim.name;
        paths = [
          self.skim
        ];
        buildInputs = [ self.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/sk \
            --add-flags "--bind 'ctrl-p:toggle-preview' --ansi --preview='${preview}/bin/preview.sh {}' --preview-window=up:50%:hidden" \
            --prefix SKIM_DEFAULT_COMMAND : "${self.fd}/bin/fd"
        '';
      };
  };
}
