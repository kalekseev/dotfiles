self: super:

{
  userPackages = super.userPackages or { } // {
    dos2unix = self.dos2unix;
    ticker = self.ticker;
    timewarrior = self.timewarrior;
    dotnet-sdk_6 = self.dotnet-sdk_6;
    yt-dlp = self.yt-dlp;
    sql-formatter = super.nodePackages.sql-formatter.override {
      buildInputs = [ super.makeWrapper ];
      preFixup = ''
        wrapProgram $out/bin/sql-formatter --add-flags \
          '-l postgresql -c ${super.writeText "sql-formatter-config" ''{ "expressionWidth": 80 }''}'
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
    # skim = self.skim;
    z-lua = self.z-lua;
    nmap = self.nmap;
    poetry = self.poetry;
    ### nix utils
    nixpkgs-fmt = self.nixpkgs-fmt;
    nix-update = self.nix-update;
    ### custom
    preview_sh =
      let
        src = super.fetchurl {
          url = "https://raw.githubusercontent.com/junegunn/fzf.vim/f86ef1bce602713fe0b5b68f4bdca8c6943ecb59/bin/preview.sh";
          sha256 = "41d28a28256d837f4e39a9b750ac2fe87622d0303301f1223a0f6820bc390eea";
        };
      in
      super.writeScriptBin "preview.sh" (builtins.readFile src);
  };
}
