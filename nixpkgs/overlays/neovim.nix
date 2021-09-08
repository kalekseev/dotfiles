self: super:

{
  vimPlugins = super.vimPlugins // {
    asyncrun-vim = super.vimUtils.buildVimPlugin {
      pname = "asyncrun-vim";
      version = "2021-03-29";
      src = super.fetchFromGitHub {
        owner = "skywind3000";
        repo = "asyncrun.vim";
        rev = "168d6b4be9d003ed14ef5d0e1668f01145327e68";
        sha256 = "sha256-xEmc85GsKB4fTZYzf9z+apxdOAvW5AwUNA8bSjXg7Ic=";
      };
    };
    vim-argwrap = super.vimUtils.buildVimPlugin {
      pname = "vim-argwrap";
      version = "2021-06-11";
      src = super.fetchFromGitHub {
        owner = "FooSoft";
        repo = "vim-argwrap";
        rev = "f1c1d2b0c763ed77f9b9f2515ffff99a72c6a757";
        sha256 = "sha256-n5O9qctmhXyMb6eHjbNdRqzvETjtVOj9f1aFpdPatg4=";
      };
    };
    vim-qfreplace = super.vimUtils.buildVimPlugin {
      pname = "vim-qfreplace";
      version = "2014-06-07";
      src = super.fetchFromGitHub {
        owner = "thinca";
        repo = "vim-qfreplace";
        rev = "89e64ae24fb4b8e2402ba6d84971c06606f4adf4";
        sha256 = "sha256-Ttu9QqIRLf1o+DX0Un3quk4TcOgzRhnDidqY7iMvQGE=";
      };
    };
    vim-jdaddy = super.vimUtils.buildVimPlugin {
      pname = "vim-jdaddy";
      version = "2014-06-07";
      src = super.fetchFromGitHub {
        owner = "tpope";
        repo = "vim-jdaddy";
        rev = "5cffddb8e644d3a3d0c0ee6a7abf5b713e3c4f97";
        sha256 = "sha256-4Bj7ekoNCG80C4Lb9+l6KFJfeXQ0NbtjOKmOnlzw6u8=";
      };
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
          \ 'pg_format': '${super.userPackages.pgformatter}/bin/pg_format',
          \}
          source ${../../vim/init.vim}
          source ${../../vim/init.lua}
          set rtp+=${../../vim/after}
          " autocmd FileType csv :packadd csv-vim
        '';
        packages.myVimPackages = with self.vimPlugins; {
          start = [
            nvim-lspconfig
            nvim-cmp
            cmp-path
            cmp-buffer
            cmp-nvim-lsp
            cmp_luasnip
            luasnip
            vim-go
            plenary-nvim
            telescope-nvim
            vim-polyglot
            vim-devicons
            editorconfig-vim
            ale
            vim-airline
            vim-airline-themes
            delimitMate
            indentLine
            onedark-vim
            onedark-nvim
            # vimproc
            vim-fugitive
            vim-surround
            vim-eunuch
            vim-abolish
            vim-dadbod
            vim-jdaddy
            vim-repeat
            which-key-nvim
            # vim-rhubarb
            nerdtree
            tcomment_vim
            vim-signify
            vim-visualstar
            smartpairs-vim
            matchit-zip
            camelcasemotion
            splitjoin-vim
            vim-argwrap
            # echodoc
            # jedi-vim
            vim-qfreplace
            ReplaceWithRegister
            undotree
            vim-niceblock
            # tagbar
            emmet-vim
            vim-test
            asyncrun-vim
            vim-snippets
            vim-tsx
            targets-vim
            vim-racer
            vim-tmux-navigator
            goyo-vim
            limelight-vim
            # direnv-vim
            vim-rooter
            # LeaderF
          ];
          opt = [ ];
        };
      };
    };
  };
}
