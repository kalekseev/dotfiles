-- nvim-cmp setup
-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'
vim.o.syntax = 'ON'
vim.o.exrc = true
vim.o.secure = true
vim.o.number = true
vim.o.showbreak = '↪..'
vim.o.linebreak = true
vim.o.listchars = 'tab:»·'
vim.o.laststatus = 3

vim.g.loaded_perl_provider = 0

vim.o.inccommand = 'nosplit'
vim.o.shada = "!,'100,<50,s10,h,n~/.vim/.viminfo.shada"

local keymap = vim.keymap.set

require('onedark').setup {
    style = 'dark',
    toggle_style_key = "<leader>tn",
    toggle_style_list = { 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light' }
}
require('onedark').load()

-- require("copilot").setup({
--     suggestion = { enabled = false },
--     panel = { enabled = false },
-- })
-- require("copilot_cmp").setup()

require('treesitter-context').setup {
    enable = true,
    multiline_threshold = 1,
}

require 'nvim-treesitter.configs'.setup {
    highlight = { enable = true },
    incremental_selection = { enable = true },
    indent = { enable = true, disable = { 'python', } },
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

require('octo').setup {}
require("fidget").setup {}
require('which-key').setup {}
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
local trouble = require("trouble.providers.telescope")
keymap("n", "gR", "<cmd>TroubleToggle lsp_references<cr>",
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
local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end
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
        { name = 'nvim_lsp', group_index = 1 },
        { name = 'vsnip',    group_index = 1 },
        { name = 'path',     group_index = 1 },
        {
            name = 'buffer',
            group_index = 2,
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
-- cmp.setup.filetype({ 'sql', 'mysql,plsql' }, {
--     sources = cmp.config.sources({
--         { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
--     }, {
--         { name = 'buffer' },
--     })
-- })
--
local augroupFormat = vim.api.nvim_create_augroup("LspFormatting", { clear = false })
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

    if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroupFormat, buffer = bufnr })
        if client.name == 'eslint' then
            -- callback will call neoformat as needed
            vim.api.nvim_clear_autocmds({ group = 'neoformat', buffer = bufnr })
        end
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroupFormat,
            buffer = bufnr,
            callback = function()
                local clients = vim.lsp.get_active_clients({ bufnr = bufnr });
                local applyPrettier = false;
                for _, _client in ipairs(clients) do
                    if _client.name == 'ruff_lsp' then
                        local params = vim.lsp.util.make_range_params()
                        -- context taken from :LspLog with debug mode on: `:lua  vim.lsp.set_log_level 'debug'`
                        params.context = { diagnostics = {}, only = { "source.fixAll" }, triggerKind = 1 }
                        local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 2000)
                        for _, res in pairs(result or {}) do
                            for _, r in pairs(res.result or {}) do
                                if r.edit then
                                    vim.lsp.util.apply_workspace_edit(r.edit, _client.offset_encoding)
                                else
                                    vim.lsp.buf.execute_command(r.command)
                                end
                            end
                        end
                    elseif _client.name == 'eslint' then
                        vim.cmd('EslintFixAll')
                        applyPrettier = true;
                    end
                end

                vim.lsp.buf.format({
                    bufnr      = bufnr,
                    timeout_ms = 2000,
                    filter     = function(sclient)
                        return sclient.name ~= "volar" and sclient.name ~= 'tsserver' and
                            sclient.name ~= 'cssls'
                    end
                })
                if applyPrettier then
                    vim.cmd("try | undojoin | Neoformat prettier | catch /E790/ | Neoformat prettier | endtry")
                end
            end,
        })
    end
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
local util = require('lspconfig/util')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

nvim_lsp.pyright.setup {
    on_attach = on_attach,
    capabilities = capabilities,

    cmd = { vim.g.nix_exes.pyright, "--stdio" },
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
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = {
        'typescript',
        'javascript',
        'javascriptreact',
        'typescriptreact',
        'vue',
        'json'
    },
    cmd = { vim.g.nix_exes.volar, "--stdio" },
    root_dir = function(fname)
        return util.root_pattern '.env.vue' (fname)
    end,
    single_file_support = false,
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
    root_dir = function(fname)
        if (util.root_pattern '.env.vue' (fname)) then
            -- volar will start it on its own
            -- single_file_support = false is required for this to work
            return nil;
        end
        return util.root_pattern 'tsconfig.json' (fname)
            or util.root_pattern('package.json', 'jsconfig.json', '.git')(fname)
    end,
    single_file_support = false,
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

nvim_lsp.ruff_lsp.setup {
    on_attach = on_attach,
    capabilities = capabilities,

    cmd = { vim.g.nix_exes['ruff-lsp'] },
}

nvim_lsp.rust_analyzer.setup {
    on_attach = on_attach,
    capabilities = capabilities,

    cmd = { vim.g.nix_exes['rust-analyzer'] },
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
