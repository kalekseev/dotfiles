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
    vim-argwrap = super.vimUtils.buildVimPluginFrom2Nix {
      pname = "vim-argwrap";
      version = "2021-06-11";
      src = super.fetchFromGitHub {
        owner = "FooSoft";
        repo = "vim-argwrap";
        rev = "f1c1d2b0c763ed77f9b9f2515ffff99a72c6a757";
        sha256 = "sha256-n5O9qctmhXyMb6eHjbNdRqzvETjtVOj9f1aFpdPatg4=";
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
    vim-jdaddy = super.vimUtils.buildVimPluginFrom2Nix {
      pname = "vim-jdaddy";
      version = "2014-06-07";
      src = super.fetchFromGitHub {
        owner = "tpope";
        repo = "vim-jdaddy";
        rev = "5cffddb8e644d3a3d0c0ee6a7abf5b713e3c4f97";
        sha256 = "sha256-4Bj7ekoNCG80C4Lb9+l6KFJfeXQ0NbtjOKmOnlzw6u8=";
      };
    };
    orgmode-nvim = super.vimUtils.buildVimPluginFrom2Nix {
      pname = "orgmode-nvim";
      version = "2021-09-10";
      src = super.fetchFromGitHub {
        owner = "kristijanhusak";
        repo = "orgmode.nvim";
        rev = "e7fff702db42ed1d90bc9fa46c3b3a102024041f";
        sha256 = "sha256-ki1jXviPswQ3muYU15slIlAEh9Ry9IlCJ0YvWY8Evzs=";
      };
    };
  };
  python39 = super.python39.override {
    packageOverrides = python-self: python-super: {
      python-lsp-server = (python-super.python-lsp-server.override
        {
          withAutopep8 = false;
          withFlake8 = false;
          withMccabe = false;
          withPycodestyle = false;
          withPydocstyle = false;
          withPyflakes = false;
          withPylint = false;
          withYapf = false;
        }).overridePythonAttrs
        (oldAttrs: {
          doCheck = false;
          checkInputs = [ ];
        });
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
            orgmode-nvim
            plenary-nvim
            telescope-nvim
            which-key-nvim
            # -- vim
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
            vim-go
            vim-jdaddy
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
