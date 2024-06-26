local status_ok, lspconfig = pcall(require, "lspconfig")
if not status_ok then
    return
end
local status_ok, rust_tools = pcall(require, "rust-tools")
if not status_ok then
    return
end
local status_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
if not status_ok then
    return
end
local util = require 'vim.lsp.util'
mason_lspconfig.setup({
    automatic_installation = true
}
)
local servers = mason_lspconfig.get_installed_servers()

local status_ok, lsp_status = pcall(require, "lsp-status")
if not status_ok then
    print("lsp status not working")
end
-- Copied from chrisatmachine

local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn", text = "" },
    { name = "DiagnosticSignHint", text = "" },
    { name = "DiagnosticSignInfo", text = "" },
}

for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
end

local config = {
    -- virtual_text = {
    --     severity = vim.diagnostic.severity.WARN,
    --     spacing = 5,
    --     update_in_insert = true,
    -- },
    virtual_text = true,
    severity = vim.diagnostic.severity.WARN,
    -- show signs
    signs = {
        active = signs,
    },
    update_in_insert = true,
    underline = true,
    severity_sort = true,
    float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
    },
}

vim.diagnostic.config(config)
--
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
})

-- vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
--     vim.lsp.diagnostic.on_publish_diagnostics,
--     {
--         underline = true,
--         virtual_text = {
--             spacing = 5,
--         },
--
--         update_in_insert = true,
--     }
-- )

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = "rounded",
})
local function lsp_highlight_document(client)
    -- Set autocommands conditional on server_capabilities
    if client.server_capabilities.documentHighlightProvider then
        --[[ print(vim.inspect(client.server_capabilities)) ]]
        vim.api.nvim_exec(
            [[
 augroup lsp_document_highlight
 autocmd! * <buffer>
 autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
 autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
 augroup END
 ]]          ,
            false
        )
    end
end

local function lsp_keymaps(bufnr)
    local opts = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>R", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
    -- vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>f", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "[d", '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<CR>', opts)
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "gl",
        '<cmd>lua vim.diagnostic.open_float(' .. bufnr .. ',{{ border = "rounded" }, scope = "line"})<CR>',
        opts
    )
    vim.api.nvim_buf_set_keymap(bufnr, "n", "]d", '<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<CR>', opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>q", "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)
    vim.cmd([[ command! Format execute 'lua vim.lsp.buf.format()' ]])
end

--
-- -- Do after nvim 0.8 releases => change call to use .format() and use the filter to filter out LSP
-- -- -- Choose null-ls only to format
--[[ local lsp_formatting = function(client, bufnr) ]]
--[[     vim.lsp.buf.format({ ]]
--[[         filter = function(client) ]]
--[[             return client.name == "null-ls" ]]
--[[         end, ]]
--[[         bufnr = bufnr, ]]
--[[     }) ]]
--[[ end ]]

-- -- -- if you want to set up formatting on save, you can use this as a callback
local lsp_formatting_augroup = vim.api.nvim_create_augroup("LspFormatting", {})
-- add to your shared on_attach callback
local on_attach = function(client, bufnr)
    --[[ if client.supports_method("textDocument/formatting") then ]]
    --[[     vim.api.nvim_clear_autocmds({ group = lsp_formatting_augroup, buffer = bufnr }) ]]
    --[[     vim.api.nvim_create_autocmd("BufWritePre", { ]]
    --[[         group = lsp_formatting_augroup, ]]
    --[[         buffer = bufnr, ]]
    --[[         callback = function() ]]
    --[[             lsp_formatting(client, bufnr) ]]
    --[[         end, ]]
    --[[     }) ]]
    --[[ end ]]
    lsp_keymaps(bufnr)
    lsp_highlight_document(client)
end

--
-- make capabilities compatible with nvim-cmp

local cmp_status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_status_ok then
    return
end

local capabilities = cmp_nvim_lsp.default_capabilities()

-- for each server set it up with options
for _, lsp_name in ipairs(servers) do

    local opts = { on_attach = on_attach, capabilities = capabilities }
    -- configure your own server things here, like disabling formatting n all
    if lsp_name == 'rust_analyzer' then
        -- print(vim.inspect(lsp._default_options))
        -- print(vim.inspect(opts.on_attach))
        opts.capabilities = lsp_status.capabilities
        rust_tools.setup(opts);
        goto continue
    end
    if lsp_name == 'sumneko_lua' then
        opts.settings = {
            Lua = {
                diagnostics = {
                    globals = { 'vim' }
                }
            }
        }
    end
    if lsp_name == 'pyright' then
        opts.settings = {
            python = {
                analysis = {
                    autoSearchPaths = true,
                    useLibraryCodeForTypes = false,
                    diagnosticMode = 'workspace',
                },
            },
        }
    end
    if lsp_name == 'clangd' then
        opts.capabilities.offsetEncoding = 'utf-8'
    end
    if lsp_name == 'gopls' then
        opts.cmd = {"gopls", "-logfile", "/home/sriram/gopls.log", "-rpc.trace"}
        opts.filetypes = { "go", "gomod", "gowork", "gotmpl" }
        opts.root_dir = lspconfig.util.root_pattern("go.work", "go.mod", ".git")
        opts.settings = {
            gopls = {
                completeUnimported = true,
                analyses = {
                    unusedparams = true,
                },
            },
        }
        opts.single_file_support=true
    end
    lspconfig[lsp_name].setup(opts)
    ::continue::
end

-- Ex: lspconfig.lspname.setup{on_attach = onattach}
