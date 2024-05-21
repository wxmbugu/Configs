local status_ok, lsp_installer = pcall(require, "mason")
if not status_ok then
	return
end
local extension_path = vim.env.HOME .. ".vscode/extensions/vadimcn.vscode-lldb-1.7.4/"
local codelldb_path = extension_path .. "adapter/codelldb"
local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

local servers = {
	"lua_ls",
	"pyright",
}

lsp_installer.setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "",
			package_uninstalled = "➜",
		},
	},
})
require("mason-lspconfig").setup({
	automatic_installation = true,
	ensure_installed = servers,
})
local lspconfig_status_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status_ok then
	return
end

local opts = {}
require("mason-lspconfig").setup_handlers({
	function(server_name)
		opts = {
			on_attach = require("user.lsp.handlers").on_attach,
			capabilities = require("user.lsp.handlers").capabilities,
		}
		local require_ok, server = pcall(require, "user.lsp.settings." .. server_name)
		if require_ok then
			opts = vim.tbl_deep_extend("force", server, opts)
		end
		lspconfig[server_name].setup(opts) -- default handler (optional)
	end,
	["rust_analyzer"] = function()
		require("rust-tools").setup({
			tools = {
				on_initialized = function()
					vim.cmd([[
            autocmd BufEnter,CursorHold,InsertLeave,BufWritePost *.rs silent! lua vim.lsp.codelens.refresh()
           ]])
				end,
			},
			server = {
				on_attach = require("user.lsp.handlers").on_attach,
				capabilities = require("user.lsp.handlers").capabilities,
				settings = {
					["rust-analyzer"] = {
						lens = {
							enable = true,
						},
						checkOnSave = {
							command = "clippy",
						},
						inlayHints = { locationLinks = false },
					},
				},
			},
			dap = {
				adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
			},
		})
	end,
	["vuels"] = function()
		vim.cmd([[ autocmd BufWritePre *.vue lua vim.lsp.buf.format{async = true} ]])
	end,
	["pyright"] = function()
		vim.cmd([[ autocmd BufWritePre *.py lua vim.lsp.buf.format{async = true} ]])
	end,
	["emmet_ls"] = function()
		vim.cmd([[ autocmd BufWritePre *.html lua vim.lsp.buf.format{async = true} ]])
	end,
})
