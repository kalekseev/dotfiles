{ pkgs, inputs }:
{
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

        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/nvim-treesitter/generated.nix
        nvim-treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
          p:
          with p;
          [
            bash
            c
            c_sharp
            cmake
            comment
            cpp
            css
            csv
            diff
            dockerfile
            git_config
            git_rebase
            gitattributes
            gitcommit
            gitignore
            html
            htmldjango
            javascript
            jq
            jsdoc
            json
            jsonc
            latex
            lua
            luadoc
            make
            markdown
            markdown_inline
            mermaid
            nix
            ocaml
            po
            python
            query
            regex
            requirements
            rust
            scss
            sql
            ssh_config
            strace
            tmux
            toml
            tsv
            tsx
            typescript
            typst
            vim
            vimdoc
            vue
            xml
            yaml
          ]
          ++ [
            # (pkgs.tree-sitter.buildGrammar {
            #   language = "sql";
            #   version = "b817500";
            #   src = pkgs.fetchFromGitHub {
            #     owner = "derekstride";
            #     repo = "tree-sitter-sql";
            #     rev = "b8175006d9c8120d41cf40a4ef3711bbbbc08973";
            #     hash = "sha256-ZURUEd7TokBIVVejRoBiXMQ1XwUEgMnzOhQiV+Tdpk0=";
            #   };
            # })
            (pkgs.tree-sitter.buildGrammar {
              language = "fsharp";
              version = "996ea99";
              src = pkgs.fetchFromGitHub {
                owner = "ionide";
                repo = "tree-sitter-fsharp";
                rev = "996ea9982bd4e490029f84682016b6793940113b";
                sha256 = "sha256-HgHVIU67h9WXfj+yx7ukCSqucRvo16jugFhxWYY1kyk=";
              };
            })
          ]
        );
      };
    in
    pkgs.neovim.override {
      withNodeJs = true;
      withRuby = false;
      configure = {
        customRC = ''
          let g:nix_exes = {
          \ 'pyright-langserver': '${pkgs.pyright}/bin/pyright-langserver',
          \ 'bash-language-server': '${pkgs.bash-language-server}/bin/bash-language-server',
          \ 'vscode-css-language-server': '${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server',
          \ 'vscode-eslint-language-server': '${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server',
          \ 'nil_ls': '${pkgs.nil}/bin/nil',
          \ 'tsserver': '${pkgs.typescript-language-server}/bin/typescript-language-server',
          \ 'biome': '${pkgs.biome}/bin/biome',
          \ 'eslint_d': '${pkgs.eslint_d}/bin/eslint_d',
          \ 'nixfmt': '${pkgs.nixfmt-rfc-style}/bin/nixfmt',
          \ 'pg_format': '${pkgs.pgformatter}/bin/pg_format',
          \ 'sql-formatter': '${sql-formatter}/bin/sql-formatter',
          \ 'shellcheck': '${pkgs.shellcheck}/bin/shellcheck',
          \ 'nixpkgs-fmt': '${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt',
          \ 'ruff': '${pkgs.lib.getExe pkgs.ruff}',
          \ 'lua-language-server': '${pkgs.sumneko-lua-language-server}/bin/lua-language-server',
          \ 'fsautocomplete': '${pkgs.fsautocomplete}/bin/fsautocomplete',
          \ 'rust-analyzer': '${pkgs.rust-analyzer}/bin/rust-analyzer',
          \ 'tinymist': '${pkgs.tinymist}/bin/tinymist',
          \}
          source ${./init.vim}
          source ${./init.lua}
          set rtp+=${./after}
        '';
        packages.myVimPackages = with pkgs.vimPlugins; {
          start = [
            supermaven-nvim
            # -- neovim
            conform-nvim
            cmp-buffer
            cmp-nvim-lsp
            cmp-path
            cmp-vsnip
            cmp-cmdline
            cmp-nvim-lsp-document-symbol
            cmp-nvim-lsp-signature-help
            cmp-calc
            diffview-nvim
            gitsigns-nvim
            Ionide-vim
            lspsaga-nvim
            lualine-nvim
            mini-nvim
            neodev-nvim
            nvim-cmp
            nvim-lspconfig
            nvim-tree-lua
            plugins.nvim-treesitter
            nvim-treesitter-context
            nvim-treesitter-textobjects
            nvim-web-devicons
            nvim-ts-context-commentstring
            oil-nvim
            onedark-nvim
            playground
            telescope-nvim
            trouble-nvim
            vim-visual-multi
            vim-vsnip
            which-key-nvim
            git-conflict-nvim
            plugins.gp-nvim
            fidget-nvim
            # octo-nvim
            # copilot-lua
            # copilot-cmp
            # -- vim
            jdaddy-vim
            plugins.vim-coverage-py
            asyncrun-vim
            camelcasemotion
            direnv-vim
            # emmet-vim
            indentLine
            smartpairs-vim
            splitjoin-vim
            undotree
            vim-abolish
            vim-argwrap
            vim-dadbod
            vim-dadbod-ui
            vim-dadbod-completion
            vim-eunuch
            vim-fugitive
            vim-rhubarb
            vim-niceblock
            plugins.vim-qfreplace
            vim-rooter
            vim-test
            vim-dispatch # recommended for vim-test
            vim-tmux-navigator
            vim-visual-star-search
          ];
          opt = [ ];
        };
      };
    };
}
