{ pkgs, inputs }: {
  neovim =
    let
      sql-formatter = pkgs.nodePackages.sql-formatter.override {
        buildInputs = [ pkgs.makeWrapper ];
        preFixup = ''
          wrapProgram $out/bin/sql-formatter --add-flags \
            '-l postgresql -c ${pkgs.writeText "sql-formatter-config" ''{ "expressionWidth": 80, "keywordCase": "upper" }''}'
        '';
      };
      plugins = {
        vim-coverage-py = pkgs.vimUtils.buildVimPlugin {
          name = "vim-coverage.py";
          src = inputs.vim-coverage-py;
        };
        vim-qfreplace = pkgs.vimUtils.buildVimPlugin {
          name = "vim-qfreplace";
          src = inputs.vim-qfreplace;
        };
        gp-nvim = pkgs.vimUtils.buildVimPlugin {
          name = "gp-nvim";
          src = inputs.gp-nvim;
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
            plugins.nvim-treesitter
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
            plugins.gp-nvim
            # copilot-lua
            # copilot-cmp
            # -- vim
            neoformat
            jdaddy-vim
            plugins.vim-coverage-py
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
            plugins.vim-qfreplace
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
