pkgs: {
  neovim =
    let
      sql-formatter = pkgs.nodePackages.sql-formatter.override {
        buildInputs = [ pkgs.makeWrapper ];
        preFixup = ''
          wrapProgram $out/bin/sql-formatter --add-flags \
            '-l postgresql -c ${pkgs.writeText "sql-formatter-config" ''{ "expressionWidth": 80, "keywordCase": "upper" }''}'
        '';
      };
      myVimPlugins = {
        vim-coverage-py = pkgs.vimUtils.buildVimPlugin {
          pname = "vim-coverage.py";
          version = "2021-08-01";
          src = pkgs.fetchFromGitHub {
            owner = "kalekseev";
            repo = "vim-coverage.py";
            rev = "0cabe076776640988c245a9eb640da2e6f4b2bc4";
            sha256 = "sha256-9dpw+0UmuE9R8Lr+npJ9vQYwoSexsU/XJbhnOL+HulY=";
          };
        };
        vim-qfreplace = pkgs.vimUtils.buildVimPlugin {
          pname = "vim-qfreplace";
          version = "2014-06-07";
          src = pkgs.fetchFromGitHub {
            owner = "thinca";
            repo = "vim-qfreplace";
            rev = "89e64ae24fb4b8e2402ba6d84971c06606f4adf4";
            sha256 = "sha256-Ttu9QqIRLf1o+DX0Un3quk4TcOgzRhnDidqY7iMvQGE=";
          };
        };
        gp-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "gp-nvim";
          version = "2024-02-27";
          src = pkgs.fetchFromGitHub {
            owner = "Robitx";
            repo = "gp.nvim";
            rev = "d76be3d067b4e7352d1e744954327982cf1d24aa";
            sha256 = "sha256-IIpbLDiC5Th/jbx7LDEPj+6D86eQQCZgPQHsfc8j8GY=";
          };
        };

        nvim-treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins
          (p: with p; [
            bash
            comment
            css
            diff
            dockerfile
            html
            htmldjango
            javascript
            json
            lua
            make
            markdown
            markdown_inline
            nix
            python
            query
            rust
            regex
            scss
            sql
            toml
            tsx
            typescript
            vue
            yaml
          ]);
      };
    in
    pkgs.neovim.override {
      withNodeJs = true;
      withRuby = false;
      configure = {
        customRC = ''
          let g:nix_exes = {
          \ 'pyright': '${pkgs.nodePackages.pyright}/bin/pyright-langserver',
          \ 'bash-language-server': '${pkgs.nodePackages.bash-language-server}/bin/bash-language-server',
          \ 'vscode-css-language-server': '${pkgs.nodePackages.vscode-langservers-extracted}/bin/vscode-css-language-server',
          \ 'vscode-eslint-language-server': '${pkgs.nodePackages.vscode-langservers-extracted}/bin/vscode-eslint-language-server',
          \ 'nil_ls': '${pkgs.nil}/bin/nil',
          \ 'tsserver': '${pkgs.nodePackages.typescript-language-server}/bin/typescript-language-server',
          \ 'prettier': '${pkgs.nodePackages.prettier}/bin/prettier',
          \ 'pg_format': '${pkgs.pgformatter}/bin/pg_format',
          \ 'sql-formatter': '${sql-formatter}/bin/sql-formatter',
          \ 'shellcheck': '${pkgs.shellcheck}/bin/shellcheck',
          \ 'nixpkgs-fmt': '${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt',
          \ 'ruff-lsp': '${pkgs.ruff-lsp}/bin/ruff-lsp',
          \ 'lua-language-server': '${pkgs.sumneko-lua-language-server}/bin/lua-language-server',
          \ 'volar': '${pkgs.nodePackages.volar}/bin/vue-language-server',
          \ 'fsautocomplete': '${pkgs.fsautocomplete}/bin/fsautocomplete',
          \ 'rust-analyzer': '${pkgs.rust-analyzer}/bin/rust-analyzer',
          \}
          source ${./init.vim}
          source ${./init.lua}
          set rtp+=${./after}
        '';
        packages.myVimPackages = with pkgs.vimPlugins; {
          start = [
            # -- neovim
            conform-nvim
            cmp-buffer
            cmp-nvim-lsp
            cmp-path
            cmp-vsnip
            diffview-nvim
            gitsigns-nvim
            Ionide-vim
            lspsaga-nvim
            lualine-nvim
            neodev-nvim
            nvim-cmp
            nvim-lspconfig
            nvim-tree-lua
            myVimPlugins.nvim-treesitter
            nvim-treesitter-context
            nvim-treesitter-textobjects
            nvim-web-devicons
            onedark-nvim
            playground
            telescope-nvim
            trouble-nvim
            vim-visual-multi
            vim-vsnip
            which-key-nvim
            git-conflict-nvim
            myVimPlugins.gp-nvim
            # copilot-lua
            # copilot-cmp
            # -- vim
            neoformat
            jdaddy-vim
            myVimPlugins.vim-coverage-py
            ReplaceWithRegister
            asyncrun-vim
            camelcasemotion
            delimitMate
            direnv-vim
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
            myVimPlugins.vim-qfreplace
            vim-repeat
            vim-rooter
            vim-surround
            vim-test
            vim-dispatch # recommended for vim-test
            vim-tmux-navigator
            # vim-tsx
            vim-jsx-typescript
            vim-visual-star-search
            octo-nvim
            fidget-nvim
          ];
          opt = [ ];
        };
      };
    };
}
