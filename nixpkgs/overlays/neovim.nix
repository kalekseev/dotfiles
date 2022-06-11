self: super:

{
  vimPlugins = super.vimPlugins // {
    vim-coverage-py = super.vimUtils.buildVimPluginFrom2Nix {
      pname = "vim-coverage.py";
      version = "2021-08-01";
      src = super.fetchFromGitHub {
        owner = "kalekseev";
        repo = "vim-coverage.py";
        rev = "0cabe076776640988c245a9eb640da2e6f4b2bc4";
        sha256 = "sha256-9dpw+0UmuE9R8Lr+npJ9vQYwoSexsU/XJbhnOL+HulY=";
      };
    };
    asyncrun-vim = super.vimUtils.buildVimPluginFrom2Nix {
      pname = "asyncrun-vim";
      version = "2021-03-29";
      src = super.fetchFromGitHub {
        owner = "skywind3000";
        repo = "asyncrun.vim";
        rev = "168d6b4be9d003ed14ef5d0e1668f01145327e68";
        sha256 = "sha256-xEmc85GsKB4fTZYzf9z+apxdOAvW5AwUNA8bSjXg7Ic=";
      };
    };
    vim-qfreplace = super.vimUtils.buildVimPluginFrom2Nix {
      pname = "vim-qfreplace";
      version = "2014-06-07";
      src = super.fetchFromGitHub {
        owner = "thinca";
        repo = "vim-qfreplace";
        rev = "89e64ae24fb4b8e2402ba6d84971c06606f4adf4";
        sha256 = "sha256-Ttu9QqIRLf1o+DX0Un3quk4TcOgzRhnDidqY7iMvQGE=";
      };
    };
    ionide-vim = super.vimUtils.buildVimPluginFrom2Nix {
      pname = "ionide-vim";
      version = "2022-02-06";
      src = super.fetchFromGitHub {
        owner = "ionide";
        repo = "ionide-vim";
        rev = "6eb5de0b13cee781d0ccc0559d614ea032967293";
        sha256 = "sha256-p8qPjBO83KQSNRbIZ7Zt4fEYaWzAjkyI3klUgXLq+ho=";
      };
    };
  };
  python39 = super.python39.override {
    packageOverrides = python-self: python-super: {
      python-lsp-server = (
        (python-super.python-lsp-server.override
          {
            withAutopep8 = false;
            withFlake8 = false;
            withMccabe = false;
            withPycodestyle = false;
            withPydocstyle = false;
            withPyflakes = false;
            withPylint = false;
            withYapf = false;
          }).overridePythonAttrs (o: { doCheck = false; }));
    };
  };
  userPackages = super.userPackages or { } // {
    neovim = super.neovim.override {
      extraPython3Packages = (ps: [ ps.pythonPackages.jedi ]);
      withNodeJs = true;
      withRuby = false;
      configure = {
        customRC = ''
          let g:nix_exes = {
          \ 'pylsp': '${self.python39Packages.python-lsp-server}/bin/pylsp',
          \ 'tsserver': '${self.nodePackages.typescript-language-server}/bin/typescript-language-server',
          \ 'pg_format': '${self.userPackages.pgformatter}/bin/pg_format',
          \}
          source ${../../vim/init.vim}
          source ${../../vim/init.lua}
          set rtp+=${../../vim/after}
        '';
        packages.myVimPackages = with self.vimPlugins; {
          start = [
            # -- neovim
            cmp-buffer
            cmp-nvim-lsp
            cmp-path
            cmp-vsnip
            vim-vsnip
            gitsigns-nvim
            lualine-nvim
            nvim-cmp
            nvim-lspconfig
            nvim-tree-lua
            nvim-web-devicons
            # onedark-nvim
            ionide-vim
            plenary-nvim
            telescope-nvim
            which-key-nvim
            # -- vim
            jdaddy-vim
            vim-coverage-py
            ReplaceWithRegister
            ale
            asyncrun-vim
            camelcasemotion
            delimitMate
            direnv-vim
            editorconfig-vim
            emmet-vim
            goyo-vim
            indentLine
            limelight-vim
            matchit-zip
            onedark-vim
            smartpairs-vim
            splitjoin-vim
            targets-vim
            tcomment_vim
            undotree
            vim-abolish
            vim-argwrap
            vim-dadbod
            vim-eunuch
            vim-fugitive
            vim-rhubarb
            # vim-go
            vim-niceblock
            vim-polyglot
            vim-qfreplace
            vim-racer
            vim-repeat
            vim-rooter
            vim-surround
            vim-test
            vim-tmux-navigator
            vim-tsx
            vim-visualstar
          ];
          opt = [ ];
        };
      };
    };
  };
}
