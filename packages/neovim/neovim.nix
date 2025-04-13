{ pkgs, inputs }:
let
  pg-sql-formatter =
    pkgs.runCommand "pg-sql-formatter" { nativeBuildInputs = [ pkgs.makeWrapper ]; }
      ''
        mkdir -p $out/bin
        ln -s ${pkgs.sql-formatter}/bin/sql-formatter $out/bin/sql-formatter
        wrapProgram $out/bin/sql-formatter --add-flags \
          '-l postgresql -c ${pkgs.writeText "sql-formatter-config" ''{ "expressionWidth": 80, "keywordCase": "upper" }''}'
      '';
  plugins = {
    vim-coverage-py = pkgs.vimUtils.buildVimPlugin {
      name = "vim-coverage.py";
      src = inputs.vim-coverage-py;
    };
    # llama-vim = pkgs.vimUtils.buildVimPlugin {
    #   name = "llama-vim";
    #   src = inputs.llama-vim;
    # };
    vim-qfreplace = pkgs.vimUtils.buildVimPlugin {
      name = "vim-qfreplace";
      src = inputs.vim-qfreplace;
    };
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/nvim-treesitter/generated.nix
    nvim-treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
      p: with p; [
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
        fsharp
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
    );
  };
in
pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
  neovimRcContent = ''
    source ${./init.vim}
    source ${./init.lua}
    set rtp+=${./after}
  '';
  plugins = with pkgs.vimPlugins; [
    toggleterm-nvim
    fileline-nvim
    SchemaStore-nvim
    avante-nvim
    efmls-configs-nvim
    supermaven-nvim
    markview-nvim
    FixCursorHold-nvim
    neotest-python
    # -- neovim
    flash-nvim
    conform-nvim
    cmp-buffer
    cmp-nvim-lsp
    cmp-path
    cmp-vsnip
    cmp-nvim-lsp-signature-help
    cmp-calc
    diffview-nvim
    gitsigns-nvim
    Ionide-vim
    lualine-nvim
    mini-nvim
    nvim-cmp
    nvim-dap
    nvim-dap-ui
    nvim-dap-python
    nvim-lspconfig
    {
      plugin = lazydev-nvim.overrideAttrs (finalAttrs: {
        runtimeDeps = [
          pkgs.typescript-language-server
          pkgs.harper
          pkgs.ruff
          pkgs.nil
          pkgs.efm-langserver
          pkgs.lemminx
          pkgs.pyright
          pkgs.yaml-language-server
          pkgs.bash-language-server
          pkgs.vscode-langservers-extracted
          pkgs.biome
          pkgs.eslint_d
          pkgs.nixfmt-rfc-style
          pg-sql-formatter
          pkgs.shellcheck
          pkgs.sumneko-lua-language-server
          pkgs.fsautocomplete
          pkgs.rust-analyzer
          pkgs.tinymist

        ];
      });
    }
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
    telescope-dap-nvim
    trouble-nvim
    # vim-visual-multi
    vim-vsnip
    which-key-nvim
    git-conflict-nvim
    # fidget-nvim
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
    vim-visual-star-search
    # plugins.llama-vim
  ];
}
