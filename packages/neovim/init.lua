vim.o.completeopt   = 'menuone,noselect' -- nvim-cmp
vim.o.syntax        = 'ON'
vim.o.exrc          = true
vim.o.secure        = true
vim.o.number        = true
vim.o.showbreak     = '↪..'
vim.o.linebreak     = true
vim.o.listchars     = 'tab:»·'
vim.o.laststatus    = 3
vim.o.lazyredraw    = true
vim.o.langmap       =
"ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz,№;#"
vim.o.splitright    = true
vim.o.splitbelow    = true
vim.o.clipboard     = 'unnamed'

vim.o.inccommand    = 'nosplit'
vim.o.ignorecase    = true
vim.o.smartcase     = true
vim.o.incsearch     = true
vim.o.hlsearch      = true
vim.o.wrapscan      = true

vim.o.foldmethod    = 'indent';
vim.o.foldnestmax   = 3;
vim.o.foldenable    = false;

vim.o.background    = 'dark'
vim.o.termguicolors = true
vim.o.colorcolumn   = '80'


-- BACKUP
-- https://begriffs.com/posts/2019-07-19-history-use-vim.html
-- Protect changes between writes. Default values of
-- updatecount (200 keystrokes) and updatetime
-- (4 seconds) are fine
vim.o.swapfile = true;
-- protect against crash-during-write
vim.o.writebackup = true;
-- but do not persist backup after successful write
vim.o.backup = false;
-- use rename-and-write-new method whenever safe
vim.o.backupcopy = "auto"
-- store undo
vim.o.undofile = true


vim.g.loaded_perl_provider = 0
local keymap = vim.keymap.set

require('onedark').setup {
  style = 'dark',
  toggle_style_key = "<leader>tn",
  toggle_style_list = { 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light' }
}
require('onedark').load()
require("oil").setup()
require('mini.ai').setup()
require('mini.surround').setup()
require('mini.operators').setup()
require('mini.pairs').setup()
-- require("copilot").setup({
--     suggestion = { enabled = false },
--     panel = { enabled = false },
-- })
-- require("copilot_cmp").setup()

require('treesitter-context').setup {
  enable = true,
  multiline_threshold = 1,
}

---@diagnostic disable-next-line: missing-fields
require('ts_context_commentstring').setup {
  enable_autocmd = false,
}
vim.g.skip_ts_context_commentstring_module = true
local _get_option = vim.filetype.get_option
---@diagnostic disable-next-line: duplicate-set-field
vim.filetype.get_option = function(filetype, option)
  return option == "commentstring"
      and require("ts_context_commentstring.internal").calculate_commentstring()
      or _get_option(filetype, option)
end

require 'nvim-treesitter.configs'.setup {
  modules = {},
  ensure_installed = {},
  ignore_install = {},
  sync_install = false,
  auto_install = false,
  highlight = { enable = true },
  incremental_selection = { enable = true },
  indent = { enable = true, disable = { 'tsx' } },
  query_linter = {
    enable = true,
    use_virtual_text = true,
    lint_events = { "BufWrite", "CursorHold" },
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
      },
      selection_modes = {
        ['@parameter.outer'] = 'v',
        ['@function.outer'] = 'V',
        ['@class.outer'] = 'V',
      },
    }
  }
}

-- require('octo').setup {}
require("fidget").setup {}
require('which-key').setup {}
require('gitsigns').setup {}
require('gp').setup {
  openai_api_key = { "cat", vim.fn.expand('$HOME/.oai_key') },
}

require 'lualine'.setup {
  options = {
    theme = 'onedark',
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch' },
    lualine_c = { 'filename' },
    lualine_x = {
      {
        'diagnostics',
        sources = { 'nvim_diagnostic' },
        sections = { 'error', 'warn', 'info', 'hint' }
      },
      'filetype'
    },
    lualine_y = { 'progress' },
    lualine_z = { 'location' }
  },
}

local actions = require('telescope.actions')
local trouble = require("trouble.sources.telescope")
keymap("n", "gR", "<cmd>TroubleToggle lsp_references<cr>",
  { silent = true, noremap = true }
)
require('telescope').setup {
  defaults = {
    mappings = {
      n = {
        ["q"] = actions.close,
        ["<c-t>"] = trouble.open
      },
      i = {
        ["<C-u>"] = function()
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>cc", true, false, true), "t", true)
        end,
        ["<c-t>"] = trouble.open
      },
    },
  }
}

-- nvim-cmp setup
local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end
local cmp = require 'cmp'
cmp.setup {
  completion = {
    keyword_length = 3
  },
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-Space>'] = cmp.mapping.complete({}),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif vim.fn["vsnip#available"](1) == 1 then
        feedkey("<Plug>(vsnip-expand-or-jump)", "")
      elseif has_words_before() then
        cmp.complete()
      else
        fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item()
      elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        feedkey("<Plug>(vsnip-jump-prev)", "")
      end
    end, { "i", "s" }),
  },
  sources = {
    -- { name = "copilot",  group_index = 1 },
    { name = "supermaven",              group_index = 1 },
    { name = 'nvim_lsp',                group_index = 2, keyword_length = 1 },
    { name = 'vsnip',                   group_index = 2 },
    { name = 'path',                    group_index = 2 },
    { name = 'nvim_lsp_signature_help', group_index = 2 },
    { name = 'calc',                    group_index = 2 },
    {
      name = 'buffer',
      group_index = 3,
      option = {
        get_bufnrs = function()
          local bufs = {}
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
              bufs[buf] = true
            end
          end
          return vim.tbl_keys(bufs)
        end
      }
    },
  },
}
cmp.setup.filetype({ 'sql', 'mysql', 'plsql' }, {
  sources = {
    { name = 'vim-dadbod-completion' },
    { name = 'buffer' }
  }
})
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'nvim_lsp_document_symbol' },
    { name = 'buffer' }
  }
})
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  }),
  ---@diagnostic disable-next-line: missing-fields
  matching = { disallow_symbol_nonprefix_matching = false }
})
require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<C-y>",
    clear_suggestion = "<C-]>",
    accept_word = "<C-j>",
  },
  ignore_filetypes = { cpp = true },
  -- color = {
  --   suggestion_color = "#ffffff",
  --   cterm = 244,
  -- },
  log_level = "info",                -- set to "off" to disable logging completely
  disable_inline_completion = false, -- disables inline completion for use with cmp
  disable_keymaps = false            -- disables built in keymaps for more manual control
})
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

  -- Mappings.
  local opts = { noremap = true, silent = true }
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end
  nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  -- buf_set_keymap('n', 'gd',
  --     '<cmd>lua vim.lsp.buf.definition{ on_list = function (options) vim.fn.setqflist({}, " ", options); vim.api.nvim_command("cfirst") end}<CR>',
  --     opts)
  -- buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  -- buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  -- buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  -- buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.show_line_diagnostics()<CR>', opts)
  -- buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  -- buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('n', '<space>gf', '<cmd>lua vim.lsp.buf.format()<CR>', opts)
end

-- IMPORTANT: make sure to setup neodev BEFORE lspconfig
require("neodev").setup {
  override = function(root_dir, library)
    if root_dir:find("dotfiles") then
      library.enabled = true
      library.plugins = true
    end
  end,
}
local nvim_lsp = require('lspconfig')
local lsp_util = require('lspconfig/util')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

local select_exe = function(name)
  return function()
    if vim.fn.executable(name) == 1 then
      return name
    end
    return vim.g.nix_exes[name]
  end
end

nvim_lsp.pyright.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { select_exe('pyright-langserver')(), "--stdio" },

  settings = {
    -- https://github.com/microsoft/pyright/blob/main/docs/settings.md
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
      }
    }
  }
}

nvim_lsp.volar.setup {
  -- packages required
  -- @vue/typescript-plugin
  -- @vue/language-server
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = function(fname)
    if vim.fn.executable('vue-language-server') == 1 then
      return lsp_util.root_pattern 'package.json' (fname)
    end
  end,
}

nvim_lsp.biome.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

nvim_lsp.csharp_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

nvim_lsp.nil_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { vim.g.nix_exes.nil_ls },
}

nvim_lsp.tsserver.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { vim.g.nix_exes.tsserver, "--stdio" },
  root_dir = lsp_util.root_pattern('tsconfig.json', '.git'),
  init_options = {
    plugins = {
      {
        name = '@vue/typescript-plugin',
        location = '',
        languages = { 'vue' },
      },
    },
  },
  filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
}

nvim_lsp.bashls.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { vim.g.nix_exes['bash-language-server'], "start" },
  settings = {
    bashIde = {
      globPattern = vim.env.GLOB_PATTERN or '*@(.sh|.inc|.bash|.command)',
      shellcheckPath = vim.g.nix_exes.shellcheck,
    }
  }
}

nvim_lsp.eslint.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { vim.g.nix_exes['vscode-eslint-language-server'], "--stdio" },
}

nvim_lsp.cssls.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { vim.g.nix_exes['vscode-css-language-server'], "--stdio" },
}

nvim_lsp.lua_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { vim.g.nix_exes['lua-language-server'], "--stdio" },
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' }
      },
      telemetry = {
        enable = false,
      },
    }
  }
}

nvim_lsp.ruff.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { select_exe('ruff')(), "server" },
}

nvim_lsp.rust_analyzer.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { vim.g.nix_exes['rust-analyzer'] },
}

nvim_lsp.tinymist.setup {
  on_attach = on_attach,
  capabilities = capabilities,

  cmd = { vim.g.nix_exes['tinymist'] },
}

nvim_lsp.ocamllsp.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}

if vim.fn.executable('rg') == 1 then
  vim.o.grepprg = 'rg --vimgrep'
end

vim.g['fsharp#lsp_auto_setup'] = 0;
vim.g['fsharp#fsautocomplete_command'] = { vim.g.nix_exes['fsautocomplete'], '--adaptive-lsp-server-enabled' };
require 'ionide'.setup {
  on_attach = on_attach,
  capabilities = capabilities,
}
require 'git-conflict'.setup {
  default_mappings = true,
  default_commands = true,
  disable_diagnostics = false,
  list_opener = 'copen',
  highlights = {
    incoming = 'DiffAdd',
    current = 'DiffText',
  },
  debug = false
}

require 'nvim-tree'.setup {
  disable_netrw       = false,
  hijack_netrw        = true,
  hijack_directories  = {
    enable = true,
    auto_open = true,
  },
  open_on_tab         = false,
  hijack_cursor       = false,
  update_cwd          = false,
  diagnostics         = {
    enable = false,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    }
  },
  update_focused_file = {
    enable      = false,
    update_cwd  = false,
    ignore_list = {}
  },
  system_open         = {
    cmd  = nil,
    args = {}
  },
  view                = {
    width = 30,
    side = 'left'
  }
}

vim.diagnostic.config {
  signs = {
    severity = { min = vim.diagnostic.severity.INFO }
  },
  virtual_text = {
    severity = { min = vim.diagnostic.severity.INFO }
  },
  float = {
    format = function(diagnostic)
      if diagnostic.source == 'eslint' then
        return string.format(
          '%s [%s]',
          diagnostic.message,
          -- shows the name of the rule
          diagnostic.user_data.lsp.code
        )
      end
      return string.format('%s [%s]', diagnostic.message, diagnostic.source)
    end,
  },
}


require('lspsaga').setup({
  lightbulb = {
    enable = false,
  },
  symbol_in_winbar = {
    respect_root = true,
  },
})

local jsformatters = { "eslint_d", "biome", "prettier" };
require("conform").setup({
  formatters = {
    sql_formatter = {
      command = vim.g.nix_exes['sql-formatter']
    },
    nixfmt = {
      command = vim.g.nix_exes['nixfmt']
    },
    biome = {
      -- command = select_exe('biome'),
      require_cwd = true
    },
    eslint_d = {
      command = vim.g.nix_exes.eslint_d,
      cwd = require("conform.util").root_file({ ".eslintrc.js" }),
      require_cwd = true
    },
    injected = {
      ignore_errors = false,
      lang_to_ext = {
        sql = "sql",
      },
      lang_to_formatters = {
        sql = { "sql_formatter", "add_new_line" },
      },
    },
    add_new_line = {
      command = "sed",
      args = { "-e", "$a\\" },
    }
  },
  formatters_by_ft = {
    sql = { "sql_formatter", "add_new_line" },
    python = { "ruff_fix", "ruff_format", "injected" },
    javascript = jsformatters,
    typescriptreact = jsformatters,
    typescript = jsformatters,
    vue = { "eslint_d", "prettier" },
    nix = { "nixfmt" },
    json = { "biome" },
    typst = { "typstyle" },
  },
  format_on_save = function(bufnr)
    -- Disable with a global or buffer-local variable
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      ---@diagnostic disable-next-line: missing-return-value
      return
    end
    return { timeout_ms = 500, lsp_fallback = true }
  end,
})
vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = "Disable autoformat-on-save",
  bang = true,
})
vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = "Re-enable autoformat-on-save",
})

keymap("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true })
keymap("n", "[d", function()
  require("lspsaga.diagnostic"):goto_prev({ severity = { min = vim.diagnostic.severity.INFO } })
end, { silent = true })
keymap("n", "]d", function()
  require("lspsaga.diagnostic"):goto_next({ severity = { min = vim.diagnostic.severity.INFO } })
end, { silent = true })
keymap("n", "[h", function()
  require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.HINT })
end, { silent = true })
keymap("n", "]h", function()
  require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.HINT })
end, { silent = true })
keymap("n", "gh", "<cmd>Lspsaga finder<CR>", { silent = true })
-- keymap("n", "gd", "<cmd>Lspsaga goto_definition<CR>", { silent = true })
keymap({ "n", "v" }, "<leader>ca", "<cmd>Lspsaga code_action<CR>", { silent = true })
keymap("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", { silent = true })

keymap("n", "<leader>o", "<cmd>Oil<CR>", { silent = true, noremap = true })

-- fugitive :GBrowse require netrw but oil.nvim disables it
vim.api.nvim_create_user_command(
  'Browse',
  function(opts)
    vim.fn.system { 'open', opts.fargs[1] }
  end,
  { nargs = 1 }
)

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*/backend/*/templates/*.html" },
  command = "set filetype=htmldjango",
})
