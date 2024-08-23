-- Source the existing Vimscript configuration
vim.cmd('source ~/.config/nvim/base_init.vim')

-- Initialize lazy.nvim
vim.opt.rtp:prepend('~/.local/share/nvim/lazy/lazy.nvim')

-- set tab width and indent size to 2 spaces
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- Initialize lazy.nvim and set up plugins
require('lazy').setup({
    -- nvim-treesitter for advanced syntax highlighting
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup({
                ensure_installed = { 'javascript', 'html', 'css', 'php', 'python', 'cpp' }, -- Add more languages as needed
                highlight = {
                    enable = true,              -- Enable Treesitter-based syntax highlighting
                    additional_vim_regex_highlighting = false, -- Disable regex-based highlighting
                },
            })
        end,
    },

    -- Neo-Tree and dependencies
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- Icons
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require('neo-tree').setup({
                -- Add any Neo-Tree-specific configuration here
		auto_clean_after_session_restore = true,
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
    {
      'nvim-telescope/telescope.nvim'
    },
    {
        'github/copilot.vim',
        config = function()
            vim.g.copilot_no_tab_map = true  -- Disable default tab mapping
        end
    },

    { 
      'mhartington/formatter.nvim',
    },
    
    -- Theme plugins
    { 'sainnhe/gruvbox-material' },
    { 'navarasu/onedark.nvim' },  -- OneDark theme plugin
    { 'folke/tokyonight.nvim' },
    { 'catppuccin/nvim' },
})

require("catppuccin").setup({
	transparent_background = true
})

-- Set up function to manage theme application without re-initializing lazy.nvim
local function apply_theme(theme_name)
    vim.cmd('colorscheme ' .. theme_name)
end

-- Apply the desired theme
apply_theme('catppuccin')  -- Current theme applied

-- Formatter.nvim setup
require('formatter').setup({
    logging = true,
    log_level = vim.log.levels.DEBUG,
    filetype = {
        javascript = {
            function()
                return {
                    exe = "prettier",  -- Ensure this is the correct path if you're using pnpm
                    args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
                    stdin = true,
                }
            end
        },
        typescript = {
            function()
                return {
                    exe = "prettier",
                    args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
                    stdin = true,
                }
            end
        },
        json = {
            function()
                return {
                    exe = "prettier",
                    args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
                    stdin = true,
                }
            end
        },
        cpp = {
          function()
            return {
              exe = "clang-format",
              args = { "--assume-filename=" .. vim.api.nvim_buf_get_name(0) },
              stdin = true,
              cwd = vim.fn.expand("%:p:h")
            }
          end
        },
        python = {
            function()
                return {
                    exe = "/opt/homebrew/bin/black",
                    args = { "-" },  -- Black reads from stdin when using the "-" flag
                    stdin = true
                }
            end
        },

        php = {
           function()
                -- Get the current file path
                local filepath = vim.api.nvim_buf_get_name(0)
                return {
                    exe = "/Users/kevingarubba/.composer/vendor/bin/php-cs-fixer",
                    args = {
                        "fix",
                        "--config=/Users/kevingarubba/.php-cs-fixer.php",  -- Ensure this path is correct
                        "--using-cache=no",
                        "--quiet",
                        filepath,
                    },
                    stdin = false,
                    cwd = vim.fn.expand('%:p:h'),  -- Run php-cs-fixer in the directory of the file
                    temp_file = true,  -- Use a temporary file for formatting
                }
            end
        },
        -- Add more filetypes as needed
    }
})

-- Format on save
vim.api.nvim_exec([[
  augroup FormatAutogroup
    autocmd!
    autocmd BufWritePost *.js,*.ts,*.json,*.cpp,*.py,*.php FormatWrite
  augroup END
]], true)

-- Function to browse and load sessions
local function load_session()
    require('telescope.builtin').find_files({
        prompt_title = "Load Session",
        cwd = vim.fn.expand("~/.config/nvim/sessions/"),
        attach_mappings = function(_, map)
            map('i', '<CR>', function(prompt_bufnr)
                local selection = require('telescope.actions.state').get_selected_entry()
                require('telescope.actions').close(prompt_bufnr)
                vim.cmd('source ' .. selection.cwd .. '/' .. selection.value)
                print("Loaded session: " .. selection.value)
                vim.cmd('Neotree toggle')  -- Reopen Neo-Tree to ensure it displays correctly
            end)
            return true
        end,
    })
end

-- Create a custom command to load sessions
vim.api.nvim_create_user_command('LoadSession', load_session, {})

-- Function to save the current session
local function save_session()
    -- Get the current working directory
    local cwd = vim.fn.getcwd()
    -- Get the directory name as the default session name
    local default_name = vim.fn.fnamemodify(cwd, ":t")
    -- Prompt the user to enter a session name
    local session_name = vim.fn.input("Session Name (default: " .. default_name .. "): ")

    -- If the input is blank, use the default name (current directory name)
    if session_name == "" then
        session_name = default_name
    end

    -- Construct the full path for the session file
    local session_file = "~/.config/nvim/sessions/" .. session_name .. ".vim"
    -- Save the session
    vim.cmd("mksession! " .. session_file)
    print("Session saved as: " .. session_file)
end


-- Create a custom command to save the session
vim.api.nvim_create_user_command('SaveSession', save_session, {})

-- Enable true color support
vim.opt.termguicolors = true

-- Example: Custom highlighting settings (optional)
vim.api.nvim_set_hl(0, "TSKeyword", { fg = "#ff007c", bold = true })
vim.api.nvim_set_hl(0, "TSFunction", { fg = "#00dfff", bold = true })

-- Toggle Neo-Tree with <leader>b
vim.api.nvim_set_keymap('n', '<leader>b', ':Neotree toggle<CR>', { noremap = true, silent = true })

-- Keybindings for SaveSession and LoadSession
vim.api.nvim_set_keymap('n', '<leader>ss', ':SaveSession<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>ls', ':LoadSession<CR>', { noremap = true, silent = true })

-- Map <C-j> to accept Copilot suggestions
vim.api.nvim_set_keymap('i', '<C-j>', 'copilot#Accept("<CR>")', { noremap = true, silent = true, expr = true })
