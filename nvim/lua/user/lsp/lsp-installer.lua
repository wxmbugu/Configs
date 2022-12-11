local status_ok, lsp_installer = pcall(require, "nvim-lsp-installer")
if not status_ok then
  return
end
local extension_path = vim.env.HOME .. '.vscode/extensions/vadimcn.vscode-lldb-1.7.4/'
local codelldb_path = extension_path .. 'adapter/codelldb'
local liblldb_path = extension_path .. 'lldb/lib/liblldb.so'

local servers = {
  "sumneko_lua",
  "cssls",
  "html",
  "tsserver",
  --  "pyright",
  "bashls",
  "jsonls",
  "yamlls",
  "rust_analyzer",
  "taplo",
  "gopls",
  "ccls",
  "kotlin_language_server",
}

lsp_installer.setup()

local lspconfig_status_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status_ok then
  return
end

local opts = {}

for _, server in pairs(servers) do
  opts = {
    on_attach = require("user.lsp.handlers").on_attach,
    capabilities = require("user.lsp.handlers").capabilities,
  }

  if server == "sumneko_lua" then
    vim.cmd [[ autocmd BufWritePre *.lua lua vim.lsp.buf.format{ async = true }
 ]]
    local sumneko_opts = require "user.lsp.settings.sumneko_lua"
    opts = vim.tbl_deep_extend("force", sumneko_opts, opts)
  end

  if server == "pyright" then
    local pyright_opts = require "user.lsp.settings.pyright"
    opts = vim.tbl_deep_extend("force", pyright_opts, opts)
  end

  if server == "gopls" then
    vim.cmd [[ autocmd BufWritePre *.go lua vim.lsp.buf.format{ async = true }
 ]]
    lspconfig.gopls.setup {
      settings = {
        gopls = {
          env = {
            GOFLAGS = "-tags=windows,linux,unittest"
          }
        }
      }
    }
  end

  if server == "ccls" then
    vim.cmd [[ autocmd BufWritePre *.c lua vim.lsp.buf.format{ async = true }
 ]]
  end
  if server == "kotlin_language_server" then
    vim.cmd [[ autocmd BufWritePre *.kt lua vim.lsp.buf.format{ async = true }
 ]]
  end
  if server == "rust_analyzer" then
    require("rust-tools").setup {
      tools = {
        on_initialized = function()
          vim.cmd [[
            autocmd BufEnter,CursorHold,InsertLeave,BufWritePost *.rs silent! lua vim.lsp.codelens.refresh()
            autocmd BufWritePre *.rs lua vim.lsp.buf.format{ async = true }
          ]]
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
            inlay_hints = {
              show_parameter_hints = true,
              other_hints_prefix = "<< ",
              only_current_line = true,
              only_current_line_autocmd = "CursorMoved,CursorMovedI"
            },
          },
        },
      },
    }
    opts = {
      adapter = require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path)
    }
    goto continue
  end



  lspconfig[server].setup(opts)
  ::continue::
end
