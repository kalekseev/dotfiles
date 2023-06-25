self: super:

{
  userPackages = super.userPackages or { } // {
    dos2unix = self.dos2unix;
    devd = self.devd;
    modd = self.modd;
    ticker = self.ticker;
    timewarrior = self.timewarrior;
    dotnet-sdk_7 = self.dotnet-sdk_7;
    graphviz = self.graphviz;
    # ocaml = self.ocaml-ng.ocamlPackages_5_0.ocaml;
    yt-dlp = self.yt-dlp;
    volar = super.nodePackages.volar;
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
    ruff-lsp = self.python3Packages.ruff-lsp;
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
        buildInputs = [ self.makeWrapper preview ];
        postBuild = ''
          wrapProgram $out/bin/sk \
            --add-flags "--bind 'ctrl-p:toggle-preview' --ansi --preview='${preview}/bin/preview.sh {}' --preview-window=up:50%:hidden" \
            --prefix SKIM_DEFAULT_COMMAND : "${self.fd}/bin/fd"
        '';
      };
  };
}
