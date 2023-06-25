final: prev: {
  userPackages = prev.userPackages or { } // {
    neovim =
      let
        vscode-langservers-extracted = prev.buildNpmPackage rec {
          pname = "vscode-langservers-extracted";
          version = "4.7.0";

          src = prev.fetchFromGitHub {
            owner = "hrsh7th";
            repo = pname;
            rev = "v${version}";
            hash = "sha256-RLRDEHfEJ2ckn0HTMu0WbMK/o9W20Xwm+XI6kCq57u8=";
          };

          npmDepsHash = "sha256-DhajWr+O0zgJALr7I/Nc5GmkOsa9QXfAQpZCaULV47M=";

          buildPhase =
            let
              inherit (prev.vscode-extensions.dbaeumer) vscode-eslint;
              extensions =
                if prev.stdenv.isDarwin
                then "${prev.vscode}/Applications/Visual\\ Studio\\ Code.app/Contents/Resources/app/extensions"
                else "${prev.vscode}/lib/vscode/resources/app/extensions";
            in
            ''
              npx babel ${extensions}/css-language-features/server/dist/node \
                --out-dir lib/css-language-server/node/
              npx babel ${extensions}/html-language-features/server/dist/node \
                --out-dir lib/html-language-server/node/
              npx babel ${extensions}/json-language-features/server/dist/node \
                --out-dir lib/json-language-server/node/
              npx babel ${extensions}/markdown-language-features/server/dist/node \
                --out-dir lib/markdown-language-server/node/
              cp -r ${vscode-eslint}/share/vscode/extensions/dbaeumer.vscode-eslint/server/out \
                lib/eslint-language-server
              mv lib/markdown-language-server/node/workerMain.js lib/markdown-language-server/node/main.js
            '';

          meta = with prev.lib; {
            description = "HTML/CSS/JSON/ESLint language servers extracted from vscode";
            homepage = "https://github.com/hrsh7th/vscode-langservers-extracted";
            license = licenses.mit;
            maintainers = with maintainers; [ lord-valen ];
          };
        };
        myVimPlugins = {
          vim-coverage-py = prev.vimUtils.buildVimPluginFrom2Nix {
            pname = "vim-coverage.py";
            version = "2021-08-01";
            src = prev.fetchFromGitHub {
              owner = "kalekseev";
              repo = "vim-coverage.py";
              rev = "0cabe076776640988c245a9eb640da2e6f4b2bc4";
              sha256 = "sha256-9dpw+0UmuE9R8Lr+npJ9vQYwoSexsU/XJbhnOL+HulY=";
            };
          };
          vim-qfreplace = prev.vimUtils.buildVimPluginFrom2Nix {
            pname = "vim-qfreplace";
            version = "2014-06-07";
            src = prev.fetchFromGitHub {
              owner = "thinca";
              repo = "vim-qfreplace";
              rev = "89e64ae24fb4b8e2402ba6d84971c06606f4adf4";
              sha256 = "sha256-Ttu9QqIRLf1o+DX0Un3quk4TcOgzRhnDidqY7iMvQGE=";
            };
          };

          nvim-treesitter = prev.vimPlugins.nvim-treesitter.withPlugins
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
              markdown_inline
              nix
              scss
              sql
              query
              vue
              vim
              yaml
            ]);
        };
      in
      prev.neovim.override {
        extraPython3Packages = (ps: [ ps.pythonPackages.jedi ]);
        withNodeJs = true;
        withRuby = false;
        configure = {
          customRC = ''
            let g:nix_exes = {
            \ 'pylsp': '${final.python3Packages.python-lsp-server}/bin/pylsp',
            \ 'bash-language-server': '${final.nodePackages.bash-language-server}/bin/bash-language-server',
            \ 'vscode-css-language-server': '${vscode-langservers-extracted}/bin/vscode-css-language-server',
            \ 'vscode-eslint-language-server': '${vscode-langservers-extracted}/bin/vscode-eslint-language-server',
            \ 'nil_ls': '${final.nil}/bin/nil',
            \ 'tsserver': '${final.nodePackages.typescript-language-server}/bin/typescript-language-server',
            \ 'prettier': '${final.nodePackages.prettier}/bin/prettier',
            \ 'pg_format': '${final.pgformatter}/bin/pg_format',
            \ 'sql-formatter': '${final.nodePackages.sql-formatter}/bin/sql-formatter',
            \ 'shellcheck': '${final.shellcheck}/bin/shellcheck',
            \ 'nixpkgs_fmt': '${final.nixpkgs-fmt}/bin/nixpkgs-fmt',
            \ 'lua_language_server': '${final.sumneko-lua-language-server}/bin/lua-language-server',
            \ 'volar': '${final.nodePackages.volar}/bin/vue-language-server',
            \}
            source ${../../vim/init.vim}
            source ${../../vim/init.lua}
            set rtp+=${../../vim/after}
          '';
          packages.myVimPackages = with final.vimPlugins; {
            start = [
              # -- neovim
              cmp-buffer
              cmp-nvim-lsp
              cmp-path
              cmp-vsnip
              diffview-nvim
              fidget-nvim
              gitsigns-nvim
              Ionide-vim
              lspsaga-nvim-original
              lualine-nvim
              neodev-nvim
              null-ls-nvim
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
              # copilot-lua
              # copilot-cmp
              # -- vim
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
