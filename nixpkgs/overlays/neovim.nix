self: super:

{
  vimPlugins = super.vimPlugins // {

    vim-visual-star-search = super.vimUtils.buildVimPluginFrom2Nix {
      pname = "vim-visual-star-search";
      version = "2022-12-15";
      src = super.fetchFromGitHub {
        owner = "bronson";
        repo = "vim-visual-star-search";
        rev = "7c32edb9e3c85d473d9be4dec721a4c9d5d4d69c";
        sha256 = "sha256-Cx1Ev4S7d/3Re3GfU+jmMlikhyQB8o5sGUX4zRdBdrw=";
      };
    };

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

    nvim-treesitter = super.vimPlugins.nvim-treesitter.withPlugins
      (p: with p; [
        typescript
        tsx
        javascript
        python
        css
        diff
        html
        json
        lua
        make
        markdown
        nix
        scss
        sql
        query
        vue
        vim
        yaml
      ]);
  };
  userPackages = super.userPackages or { } // {
    neovim = super.neovim.override {
      extraPython3Packages = (ps: [ ps.pythonPackages.jedi ]);
      withNodeJs = true;
      withRuby = false;
      configure = {
        customRC = ''
          let g:nix_exes = {
          \ 'pylsp': '${self.python3Packages.python-lsp-server}/bin/pylsp',
          \ 'bash-language-server': '${self.nodePackages.bash-language-server}/bin/bash-language-server',
          \ 'vscode-css-language-server': '${self.nodePackages.vscode-langservers-extracted}/bin/vscode-css-language-server',
          \ 'vscode-eslint-language-server': '${self.nodePackages.vscode-langservers-extracted}/bin/vscode-eslint-language-server',
          \ 'nil_ls': '${self.nil}/bin/nil',
          \ 'tsserver': '${self.nodePackages.typescript-language-server}/bin/typescript-language-server',
          \ 'prettier': '${self.nodePackages.prettier}/bin/prettier',
          \ 'pg_format': '${self.pgformatter}/bin/pg_format',
          \ 'sql-formatter': '${super.userPackages.sql-formatter}/bin/sql-formatter',
          \ 'shellcheck': '${self.shellcheck}/bin/shellcheck',
          \ 'nixpkgs_fmt': '${self.nixpkgs-fmt}/bin/nixpkgs-fmt',
          \ 'lua_language_server': '${self.sumneko-lua-language-server}/bin/lua-language-server',
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
            diffview-nvim
            fidget-nvim
            gitsigns-nvim
            ionide-vim
            lspsaga-nvim-original
            lualine-nvim
            neodev-nvim
            null-ls-nvim
            nvim-cmp
            nvim-lspconfig
            nvim-tree-lua
            nvim-treesitter
            nvim-treesitter-context
            nvim-treesitter-textobjects
            nvim-web-devicons
            onedark-nvim
            playground
            plenary-nvim
            telescope-nvim
            trouble-nvim
            vim-visual-multi
            vim-vsnip
            which-key-nvim
            # -- vim
            jdaddy-vim
            vim-coverage-py
            ReplaceWithRegister
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
            smartpairs-vim
            splitjoin-vim
            targets-vim
            tcomment_vim
            undotree
            vim-abolish
            vim-argwrap
            vim-dadbod
            vim-dadbod-ui
            vim-dadbod-completion
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
            vim-dispatch # recommended for vim-test
            vim-tmux-navigator
            vim-tsx
            vim-visual-star-search
          ];
          opt = [ ];
        };
      };
    };
  };
}
