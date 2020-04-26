self: super: {
  neovim = super.neovim.override {
    withNodeJs = true;
    withRuby = false;
  };
}

