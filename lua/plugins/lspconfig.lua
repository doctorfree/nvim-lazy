local settings = require("configuration")
local formatters_linters = settings.formatters_linters
local external_formatters = settings.external_formatters
local table_contains = require("utils.functions").table_contains

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "jose-elias-alvarez/nvim-lsp-ts-utils",
      "jose-elias-alvarez/null-ls.nvim",
      "nvim-lua/plenary.nvim",
      "b0o/schemastore.nvim",
      "folke/neodev.nvim",
    },
    config = function()
      local opts = {
        ensure_installed = settings.formatters_linters,
        ui = {
          border = "rounded",
          icons = {
            package_pending = " ",
            package_installed = " ",
            package_uninstalled = " ﮊ",
          },
        },
      }
      require("mason").setup(opts)
      local mr = require("mason-registry")
      local function install_ensured()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(install_ensured)
      else
        install_ensured()
      end
      require("mason-lspconfig").setup({
        ensure_installed = settings.lsp_servers,
        automatic_installation = true,
      })
      require("config.lspconfig")
    end,
  },

  {
    "folke/neodev.nvim",
    version = false, -- last release is way too old
    event = "VeryLazy",
    dependencies = {
      "hrsh7th/nvim-cmp",
    },
    config = function()
      require("config.neodev")
    end,
  },

  { "mfussenegger/nvim-jdtls" }, -- java lsp - https://github.com/mfussenegger/nvim-jdtls

  {
    "jose-elias-alvarez/null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "mason.nvim",
    },
    config = function()
      vim.filetype.add({
        extension = {
          zsh = "zsh",
        },
      })
      local null_ls = require("null-ls")
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics
      local actions = null_ls.builtins.code_actions
      local conf_sources = {
        actions.gitsigns,
        diagnostics.zsh.with({
          filetypes = { "zsh" },
        }),
      }
      if table_contains(external_formatters, "ruff") then
        if vim.fn.executable('ruff') == 1 then
          table.insert(conf_sources, diagnostics.ruff)
        end
      end
      if table_contains(external_formatters, "black") then
        if vim.fn.executable('black') == 1 then
          table.insert(conf_sources,
            formatting.black.with({
              timeout = 10000,
              extra_args = { "--fast" },
            }))
        end
      end
      if table_contains(external_formatters, "beautysh") then
        if vim.fn.executable('beautysh') == 1 then
          table.insert(conf_sources,
            formatting.beautysh.with({
              timeout = 10000,
              extra_args = { "--indent-size", "2" },
            }))
        end
      end
      if table_contains(formatters_linters, "prettier") then
        table.insert(conf_sources,
          formatting.prettier.with({
            -- milliseconds
            timeout = 10000,
            extra_args = { "--single-quote", "false" },
          }))
      end
      if table_contains(formatters_linters, "stylua") then
        table.insert(conf_sources,
          formatting.stylua.with({
            timeout = 10000,
            extra_args = { "--indent-type", "Spaces", "--indent-width", "2" },
          }))
      end
      if table_contains(formatters_linters, "goimports") then
        table.insert(conf_sources, formatting.goimports)
      end
      if table_contains(formatters_linters, "gofumpt") then
        table.insert(conf_sources, formatting.gofumpt)
      end
      if table_contains(formatters_linters, "shellcheck") then
        table.insert(conf_sources, actions.shellcheck)
      end
      if table_contains(formatters_linters, "google-jave-format") then
        table.insert(conf_sources, formatting.google_java_format)
      end
      if table_contains(formatters_linters, "latexindent") then
        table.insert(conf_sources,
          -- https://github.com/cmhughes/latexindent.pl/releases/tag/V3.9.3
          formatting.latexindent.with({
            timeout = 10000,
            extra_args = { "-g", "/dev/null" },
          }))
      end
      if table_contains(formatters_linters, "shfmt") then
        table.insert(conf_sources,
          formatting.shfmt.with({
            extra_args = { "-i", "2", "-ci", "-bn" },
            filetypes = { "sh", "zsh", "bash" },
          }))
      end
      if table_contains(formatters_linters, "sql_formatter") then
        table.insert(conf_sources,
          formatting.sql_formatter.with({
            timeout = 10000,
            extra_args = { "--config" },
          }))
      end
      if table_contains(formatters_linters, "markdownlint") then
        table.insert(conf_sources, formatting.markdownlint)
      end
      null_ls.setup({
        debug = false,
        sources = conf_sources,
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                if AUTOFORMAT_ACTIVE then -- global var defined in functions.lua
                  vim.lsp.buf.format({ bufnr = bufnr })
                end
              end,
            })
          end
        end,
      })
    end,
  },

  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v2.x",
    dependencies = {
      -- LSP Support
      { "neovim/nvim-lspconfig" },             -- Required
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" }, -- Optional
      -- Autocompletion
      { "hrsh7th/nvim-cmp" },                  -- Required
      { "hrsh7th/cmp-nvim-lsp" },              -- Required
      { "L3MON4D3/LuaSnip" },                  -- Required
    },
    config = function()
      local lsp = require("lsp-zero").preset({})
      lsp.on_attach(function(client, bufnr)
        lsp.default_keymaps({ buffer = bufnr })
      end)
      lsp.setup()
    end,
  },
}
