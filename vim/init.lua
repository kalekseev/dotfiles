-- nvim-cmp setup
-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

require('onedark').setup {
    style = 'dark',
    toggle_style_key = "<leader>tn",
    toggle_style_list = { 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light' }
}
require('onedark').load()

require('treesitter-context').setup {
    enable = true,
}

require 'nvim-treesitter.configs'.setup {
    highlight = { enable = true },
    incremental_selection = { enable = true },
    textobjects = { enable = true },
    indent = { enable = true }
}

require('which-key').setup {}
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
require('gitsigns').setup {}

local actions = require('telescope.actions')
local trouble = require("trouble.providers.telescope")
vim.keymap.set("n", "gR", "<cmd>TroubleToggle lsp_references<cr>",
    { silent = true, noremap = true }
)
require('telescope').setup {
    defaults = {
        mappings = {
            n = {
                ["q"] = actions.close,
                ["<c-t>"] = trouble.open_with_trouble
            },
            i = {
                ["<C-u>"] = function()
                    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>cc", true, false, true), "t", true)
                end,
                ["<c-t>"] = trouble.open_with_trouble
            },
        },
    }
}

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
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
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        },
        ['<Tab>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 's' }),
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'vsnip' },
        { name = 'path' },
        {
            name = 'buffer',
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

local augroupFormat = vim.api.nvim_create_augroup("LspFormatting", {})
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

    -- local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- Mappings.
    local opts = { noremap = true, silent = true }

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    -- buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.set_loclist()<CR>', opts)
    buf_set_keymap('n', '<space>gf', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

    if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroupFormat, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroupFormat,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.format({ bufnr = bufnr })
            end,
        })
    end
end

local nvim_lsp = require('lspconfig')
local util = require('lspconfig/util')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

nvim_lsp.pylsp.setup {
    on_attach = on_attach,
    capabilities = capabilities,

    cmd = { vim.g.nix_exes.pylsp },
    root_dir = function(fname)
        local root_files = {
            'setup.cfg',
        }
        return util.root_pattern(unpack(root_files))(fname) or util.find_git_ancestor(fname) or util.path.dirname(fname)
    end,
}

nvim_lsp.csharp_ls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}

nvim_lsp.tsserver.setup {
    on_attach = on_attach,
    capabilities = capabilities,

    cmd = { vim.g.nix_exes.tsserver, "--stdio" },
}

nvim_lsp.sumneko_lua.setup {
    on_attach = on_attach,
    capabilities = capabilities,

    cmd = { vim.g.nix_exes.lua_language_server, "--stdio" },
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

local null_ls = require('null-ls')
null_ls.setup({
    diagnostics_format = "[#{c}] #{m} (#{s})",
    sources = {
        null_ls.builtins.diagnostics.eslint_d.with({
            command = vim.g.nix_exes.eslint_d
        }),
        null_ls.builtins.diagnostics.flake8,
        null_ls.builtins.diagnostics.shellcheck.with({
            command = vim.g.nix_exes.shellcheck
        }),
        null_ls.builtins.formatting.isort,
        null_ls.builtins.formatting.black,
        null_ls.builtins.formatting.nixpkgs_fmt.with({
            command = vim.g.nix_exes.nixpkgs_fmt
        }),
        null_ls.builtins.formatting.prettier,
        null_ls.builtins.formatting.eslint_d.with({
            command = vim.g.nix_exes.eslint_d
        }),
    },
    on_attach = on_attach,
})

require 'ionide'.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}

require 'nvim-tree'.setup {
    disable_netrw       = false,
    hijack_netrw        = true,
    open_on_setup       = false,
    ignore_ft_on_setup  = {},
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
        side = 'left',
        mappings = {
            custom_only = false,
            list = {}
        }
    }
}
