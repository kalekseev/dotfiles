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
-- vim.o.cmdheight     = 0


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
-- move between panes
keymap('n', '<C-h>', '<C-w>h', { silent = true })
keymap('n', '<C-j>', '<C-w>j', { silent = true })
keymap('n', '<C-k>', '<C-w>k', { silent = true })
keymap('n', '<C-l>', '<C-w>l', { silent = true })

require('onedark').setup {
  style = 'dark',
  toggle_style_key = "<leader>tn",
  toggle_style_list = { 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light' }
}
require('onedark').load()
require("oil").setup()
require('mini.ai').setup()
require('mini.surround').setup()
require('mini.pairs').setup()
-- require("copilot").setup({
--     suggestion = { enabled = false },
--     panel = { enabled = false },
-- })
-- require("copilot_cmp").setup()

require("toggleterm").setup {
  open_mapping = [[<c-\>]]
}

function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  keymap('t', '<esc>', [[<C-\><C-n>]], opts)
  keymap('t', 'jk', [[<C-\><C-n>]], opts)
  keymap('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  -- keymap('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  keymap('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  keymap('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
  keymap('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end

vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

require('treesitter-context').setup {
  enable = true,
  multiline_threshold = 1,
}

require('ts_context_commentstring').setup({
  enable_autocmd = false,
})
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

---@diagnostic disable-next-line: missing-fields
require("neotest").setup({
  adapters = {
    require("neotest-python")({
      dap = { justMyCode = false },
    }),
  },
})

require("dap-python").setup("python")
local dap = require('dap')
dap.configurations.python = {
  {
    type = 'python',
    request = 'attach',
    name = 'attach',
    connect = { host = '127.0.0.1', port = vim.env.PYTHON_DEBUG_PORT or 5678 },
    justMyCode = false,

  },
}
vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })

keymap('n', '<Leader>b', function() dap.toggle_breakpoint() end, { desc = 'toggle breakpoint' })
keymap('n', '<Leader>dc', function() dap.continue() end, { desc = 'continue' })
keymap('n', '<Leader>dd', function() dap.disconnect() end, { desc = 'disconnect' })
keymap('n', '<C-n>', function() require('dap').step_over() end, { desc = 'step over' })
keymap('n', '<Leader>di', function() require('dap').step_into() end, { desc = 'step into' })
keymap('n', '<Leader>do', function() require('dap').step_out() end, { desc = 'step out' })
keymap('n', '<Leader>ds', function()
  local widgets = require('dap.ui.widgets')
  widgets.centered_float(widgets.scopes)
end, { desc = 'show scopes' })
keymap('n', '<Leader>df', function() require('telescope').extensions.dap.frames({}) end, { desc = 'show frames' })
keymap('n', '<Leader>dp', function() require("dap.ui.widgets").preview() end, { desc = 'show preview' })


-- local dapui = require("dapui")
-- dapui.setup()
-- require('octo').setup {}
-- require("fidget").setup {}
-- https://github.com/yetone/avante.nvim/issues/665#issuecomment-2412440939
require('flash').setup({ modes = { search = { enabled = true } } })

-- require('avante_lib').load()
-- require("avante").setup {
--   hints = { enabled = false },
--   mappings = {
--     ask = "<leader>ga",
--     edit = "<leader>ge",
--     refresh = "<leader>zr",
--     focus = "<leader>zf",
--     select_model = "<leader>z?",
--     toggle = {
--       default = "<leader>zt",
--       debug = "<leader>zd",
--       hint = "<leader>zh",
--       suggestion = "<leader>zs",
--       repomap = "<leader>zr",
--     },
--   },
-- }

require('markview').setup {
  preview = {
    filetypes = { "markdown", "Avante" },
    buf_ignore = {},
  },
  max_length = 2000
}

require('which-key').setup()
require('gitsigns').setup {}

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
require('telescope').load_extension('dap')

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

vim.lsp.enable({
  'ruff',
  'pyright',
  'jsonls',
  'yamlls',
  'biome',
})

local lsp_util = require('lspconfig/util')
local lsp_servers = {
  csharp_ls     = {},
  nil_ls        = {},
  bashls        = {},
  eslint        = {},
  cssls         = {},
  rust_analyzer = {},
  tinymist      = {},
  ocamllsp      = {},
  html          = {
    filetypes = { 'html', 'templ', 'htmldjango' },
  },

  efm           = {
    filetypes = { "python" },
    root_dir = lsp_util.root_pattern('.env.mypy'),
    single_file_support = false,

    settings = {
      rootMarkers = { '.env.mypy' },
      languages = {
        python = { require('efmls-configs.linters.mypy') },
      }
    }
  },

  harper_ls     = {
    settings = {
      ["harper-ls"] = {
        linters = {
          sentence_capitalization = false,
        }
      }
    }
  },

  lemminx       = {
    init_options = {
      settings = {
        xml = {
          format = {
            enabled = true,
            splitAttributes = "preserve",
            maxLineWidth = 280,
          },
        },
        xslt = {
          format = {
            enabled = true,
            splitAttributes = "preserve",
            maxLineWidth = 280,
          },
        },
      }
    }
  },

  ts_ls         = {
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
  },

  lua_ls        = {
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
  },
}

require("lazydev").setup()
vim.diagnostic.config { virtual_text = true, virtual_lines = false }

vim.api.nvim_create_user_command("LspLinesToggle", function()
  local config = vim.diagnostic.config() or {}
  if config.virtual_text then
    vim.diagnostic.config { virtual_text = false, virtual_lines = true }
  else
    vim.diagnostic.config { virtual_text = true, virtual_lines = false }
  end
end, { desc = "Toggle lsp_lines" })

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

    keymap('n', keys, func, { buffer = bufnr, desc = desc })
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
  -- buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.show_line_diagnostics()<CR>', opts)
  -- buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  -- buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('n', '<space>gf', '<cmd>lua vim.lsp.buf.format()<CR>', opts)
end
local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()
for name, config in pairs(lsp_servers) do
  config = vim.tbl_deep_extend("force", {}, {
    capabilities = capabilities,
    on_attach = on_attach,
  }, config)
  lspconfig[name].setup(config)
end

vim.g['fsharp#lsp_auto_setup'] = 0
vim.g['fsharp#exclude_project_directories'] = { 'paket-files' }

require('ionide').setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- require 'git-conflict'.setup {
--   default_mappings = true,
--   default_commands = true,
--   disable_diagnostics = false,
--   list_opener = 'copen',
--   highlights = {
--     incoming = 'DiffAdd',
--     current = 'DiffText',
--   },
--   debug = false
-- }

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


local jsformatters = { "eslint_d", "biome", "prettier" };
require("conform").setup({
  formatters = {
    biome = {
      require_cwd = true
    },
    eslint_d = {
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

keymap("n", "[d", function()
  vim.diagnostic.jump({ count = -1, severity = { min = vim.diagnostic.severity.INFO }, float = true })
end, { silent = true })
keymap("n", "]d", function()
  vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.INFO }, float = true })
end, { silent = true })
keymap("n", "[h", function()
  vim.diagnostic.jump({ count = -1, severity = { min = vim.diagnostic.severity.HINT }, float = true })
end, { silent = true })
keymap("n", "]h", function()
  vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.HINT }, float = true })
end, { silent = true })

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
