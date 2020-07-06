self: super: {
  neovim = super.neovim.override {
    extraPython3Packages = (ps: [ps.pythonPackages.jedi]);
    withNodeJs = true;
    withRuby = false;
  };
}

