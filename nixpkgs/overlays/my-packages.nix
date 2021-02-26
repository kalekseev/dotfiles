self: super:

{
  userPackages = super.userPackages or { } // {
    ### shell utils
    bat = self.bat;
    starship = self.starship;
    fd = self.fd;
    icdiff = self.icdiff;
    overmind = self.overmind;
    skim = self.skim;
    z-lua = self.z-lua;
    entr = self.entr;
    ### nix utils
    nixpkgs-fmt = self.nixpkgs-fmt;
    ### custom
    neovim = super.neovim.override {
      extraPython3Packages = (ps: [ ps.pythonPackages.jedi ]);
      withNodeJs = true;
      withRuby = false;
    };
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
