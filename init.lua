-- ========================================
-- Basic Neovim Settings
-- ========================================

-- Source the existing Vimscript configuration
vim.cmd("source ~/.config/nvim/base_init.vim")

-- Enable true color support
vim.opt.termguicolors = true

-- Set tab width and indent size to 2 spaces
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.wrap = false

-- Remap indenting in visual mode to stay in visual mode
vim.api.nvim_set_keymap("v", "<", "<gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", ">", ">gv", { noremap = true, silent = true })

-- ========================================
-- Plugin Management with lazy.nvim
-- ========================================

-- Initialize lazy.nvim
vim.opt.rtp:prepend("~/.local/share/nvim/lazy/lazy.nvim")

-- Set up plugins
require("lazy").setup({
	-- Syntax Highlighting and Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "javascript", "html", "css", "php", "python", "cpp" },
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
			})
		end,
	},

	-- File Explorer: Neo-Tree
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function()
			require("neo-tree").setup({
				auto_clean_after_session_restore = true,
				filesystem = {
					filtered_items = {
						visible = true, -- Show hidden files by default
						hide_dotfiles = false, -- Do not hide files that start with a dot
						hide_gitignored = false, -- Show files ignored by Git
						hide_hidden = false, -- Do not hide hidden files
					},
				},
				enable_git_status = true,
				enable_diagnostics = true,
				default_component_configs = {
					icon = {
						folder_closed = "",
						folder_open = "",
						folder_empty = "",
						default = "",
					},
				},
			})
		end,
	},

	-- Fuzzy Finder: Telescope
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").setup({
				defaults = {
					file_ignore_patterns = { "node_modules", ".git" },
					vimgrep_arguments = {
						"rg",
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
						"--hidden", -- Include hidden files
					},
				},
			})
		end,
	},

	-- Code Formatting: conform.nvim
	{ "stevearc/conform.nvim" },

	-- Commenting: Comment.nvim
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	-- GitHub Copilot
	{
		"github/copilot.vim",
		config = function()
			vim.g.copilot_no_tab_map = true
		end,
	},

	{
		"mattn/emmet-vim",
		config = function()
			-- Set up Emmet options if needed
			vim.g.user_emmet_leader_key = "<C-y>"
			vim.g.user_emmet_settings = {
				php = {
					extends = "html",
				},
			}
		end,
	},

	{
		"letieu/hacker.nvim",
	},

	-- Themes
	{ "sainnhe/gruvbox-material" },
	{ "navarasu/onedark.nvim" },
	{ "folke/tokyonight.nvim" },
	{ "catppuccin/nvim" },
})

-- ========================================
-- Theme Configuration
-- ========================================

require("catppuccin").setup({
	transparent_background = true,
})

local function apply_theme(theme_name)
	vim.cmd("colorscheme " .. theme_name)
end

apply_theme("catppuccin") -- Apply the desired theme

-- ========================================
-- Code Formatting Configuration
-- ========================================

require("conform").setup({
	formatters_by_ft = {
		javascript = { "prettier" },
		typescript = { "prettier" },
		json = { "prettier" },
		php = { "php-cs-fixer" },
		python = { "black" },
		cpp = { "clang-format" },
		lua = { "stylua" },
		css = { "prettier" },
		scss = { "prettier" },
		html = { "prettier" },
	},
	formatters = {
		["stylua"] = {
			command = "stylua",
			args = { "--config-path", vim.fn.expand("~/.config/stylua.toml"), "-" },
			stdin = true,
		},
		["php-cs-fixer"] = {
			command = "/Users/kevingarubba/.composer/vendor/bin/php-cs-fixer",
			args = {
				"fix",
				"--config=/Users/kevingarubba/.php-cs-fixer.php",
				"--using-cache=no",
				"$FILENAME",
			},
			stdin = false,
		},
		["prettier"] = {
			command = "prettier",
			args = function()
				local ft = vim.bo.filetype
				if ft == "scss" then
					return { "--stdin-filepath", vim.fn.expand("%:p"), "--parser", "scss" }
				elseif ft == "css" then
					return { "--stdin-filepath", vim.fn.expand("%:p"), "--parser", "css" }
				else
					return { "--stdin-filepath", vim.fn.expand("%:p") }
				end
			end,
			stdin = true,
		},
	},
})

vim.api.nvim_create_user_command("Format", function(args)
	local range = nil
	if args.count ~= -1 then
		local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
		range = {
			start = { args.line1, 0 },
			["end"] = { args.line2, end_line:len() },
		}
	end
	require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })

-- Auto format on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.php", "*.js", "*.ts", "*.json", "*.py", "*.cpp", "*.lua", "*.css", "*.scss", "*.html" },
	callback = function()
		require("conform").format()
	end,
})

-- ========================================
-- Session Management
-- ========================================

local function load_session()
	require("telescope.builtin").find_files({
		prompt_title = "Load Session",
		cwd = vim.fn.expand("~/.config/nvim/sessions/"),
		attach_mappings = function(_, map)
			map("i", "<CR>", function(prompt_bufnr)
				local selection = require("telescope.actions.state").get_selected_entry()
				require("telescope.actions").close(prompt_bufnr)
				vim.cmd("source " .. selection.cwd .. "/" .. selection.value)
				print("Loaded session: " .. selection.value)
				vim.cmd("Neotree toggle")
			end)
			return true
		end,
	})
end

local function save_session()
	local cwd = vim.fn.getcwd()
	local default_name = vim.fn.fnamemodify(cwd, ":t")
	local session_name = vim.fn.input("Session Name (default: " .. default_name .. "): ")

	if session_name == "" then
		session_name = default_name
	end

	local session_file = "~/.config/nvim/sessions/" .. session_name .. ".vim"
	vim.cmd("mksession! " .. session_file)
	print("Session saved as: " .. session_file)
end

vim.api.nvim_create_user_command("LoadSession", load_session, {})
vim.api.nvim_create_user_command("SaveSession", save_session, {})

-- ========================================
-- Pane Management
-- ========================================
-- Global variables to track the terminal buffer and window
local terminal_bufnr = nil
local terminal_winid = nil

-- Function to toggle terminal pane
function toggle_terminal()
	if terminal_winid and vim.api.nvim_win_is_valid(terminal_winid) then
		-- Terminal window is open, close it
		vim.api.nvim_win_hide(terminal_winid)
		terminal_winid = nil
	else
		if terminal_bufnr and vim.api.nvim_buf_is_valid(terminal_bufnr) then
			-- Reopen the existing terminal buffer in a new split
			vim.cmd("botright split")
			vim.api.nvim_win_set_buf(0, terminal_bufnr)
			terminal_winid = vim.api.nvim_get_current_win()
		else
			-- Create a new terminal buffer
			vim.cmd("botright split term://$SHELL")
			terminal_bufnr = vim.api.nvim_get_current_buf()
			terminal_winid = vim.api.nvim_get_current_win()
			vim.cmd("resize 10") -- Adjust this height as needed
		end
		vim.cmd("startinsert") -- Start in insert mode for terminal input
	end
end

-- Autocommand to ensure terminal is always in Terminal mode
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TermOpen" }, {
	pattern = "*",
	callback = function()
		if terminal_bufnr and vim.api.nvim_buf_is_valid(terminal_bufnr) then
			if vim.api.nvim_get_current_buf() == terminal_bufnr then
				vim.cmd("startinsert")
			end
		end
	end,
})

-- Set up a key mapping to search for a string in all files
vim.api.nvim_set_keymap("n", "<leader>f", ":Telescope live_grep<CR>", { noremap = true, silent = true })

-- Map Ctrl+t to toggle the terminal pane
vim.api.nvim_set_keymap("n", "<C-t>", ":lua toggle_terminal()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<C-t>", "<C-\\><C-n>:lua toggle_terminal()<CR>", { noremap = true, silent = true })

-- ========================================
-- Key Mappings
-- ========================================

-- Toggle Neo-Tree with <leader>b
vim.api.nvim_set_keymap("n", "<leader>b", ":Neotree toggle<CR>", { noremap = true, silent = true })

-- SaveSession and LoadSession key mappings
vim.api.nvim_set_keymap("n", "<leader>ss", ":SaveSession<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>ls", ":LoadSession<CR>", { noremap = true, silent = true })

-- Telescope file finder
vim.api.nvim_set_keymap("n", "<leader>p", ":Telescope find_files<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<D-p>", ":Telescope find_files<CR>", { noremap = true, silent = true }) -- macOS

vim.g.user_emmet_leader_key = "<C-e>" -- Change Emmet leader key to Ctrl-e, for example

-- GitHub Copilot suggestion acceptance
vim.api.nvim_set_keymap("i", "<C-j>", 'copilot#Accept("<CR>")', { noremap = true, silent = true, expr = true })

-- Comment.nvim key mappings
vim.api.nvim_set_keymap(
	"n",
	"<leader>/",
	'<cmd>lua require("Comment.api").toggle.linewise.current()<CR>',
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap(
	"v",
	"<leader>/",
	'<ESC><cmd>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>',
	{ noremap = true, silent = true }
)
