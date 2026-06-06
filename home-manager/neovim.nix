{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      telescope-nvim
      plenary-nvim
      telescope-fzf-native-nvim
      nvim-treesitter.withAllGrammars
      nvim-lspconfig
      tokyonight-nvim
    ];

    initLua = ''
      -- Options
      vim.opt.expandtab = true
      vim.opt.tabstop = 4
      vim.opt.shiftwidth = 4
      vim.opt.shiftround = true
      vim.opt.autoindent = true
      vim.opt.smartindent = true
      vim.opt.clipboard = "unnamedplus"

      -- Keymaps
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {silent=true})
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, {silent=true})

      -- Telescope
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
      vim.keymap.set("n", "<leader>fj", builtin.jumplist, { desc = "Telescope jump list" })

      -- Colorscheme
      require("tokyonight").setup({
        style = "storm",
        transparent = false,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          functions = {},
          variables = {},
        },
      })
      vim.cmd([[colorscheme tokyonight-storm]])

      -- LSP Config
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({})
      lspconfig.clangd.setup({})
      lspconfig.pylsp.setup({})
    '';
  };

  home.packages = with pkgs; [
    ripgrep
    fd
    lua-language-server
    clang-tools
    python3Packages.python-lsp-server
  ];
}
