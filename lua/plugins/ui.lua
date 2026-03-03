return {
  -- telescope
  -- a nice seletion UI also to find and open files
  {
    'nvim-telescope/telescope.nvim',
    event = 'VeryLazy',
    dependencies = {
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      { 'nvim-telescope/telescope-dap.nvim' },
      {
        'jmbuhr/telescope-zotero.nvim',
        enabled = false,
        dev = false,
        dependencies = {
          { 'kkharji/sqlite.lua' },
        },
        config = function()
          -- vim.keymap.set('n', '<leader>fz', ':Telescope zotero<cr>', { desc = '[z]otero' })
        end,
      },
    },
    config = function()
      local telescope = require 'telescope'
      local actions = require 'telescope.actions'
      local previewers = require 'telescope.previewers'
      local new_maker = function(filepath, bufnr, opts)
        opts = opts or {}
        filepath = vim.fn.expand(filepath)
        vim.loop.fs_stat(filepath, function(_, stat)
          if not stat then
            return
          end
          if stat.size > 100000 then
            return
          else
            previewers.buffer_previewer_maker(filepath, bufnr, opts)
          end
        end)
      end

      local telescope_config = require 'telescope.config'
      -- Clone the default Telescope configuration
      local vimgrep_arguments = { unpack(telescope_config.values.vimgrep_arguments) }
      table.insert(vimgrep_arguments, '--glob')
      table.insert(vimgrep_arguments, '!docs/*')

      telescope.setup {
        defaults = {
          buffer_previewer_maker = new_maker,
          vimgrep_arguments = vimgrep_arguments,
          file_ignore_patterns = {
            'node_modules',
            '%_cache',
            '.git/',
            'site_libs',
            '.venv',
          },
          layout_strategy = 'flex',
          sorting_strategy = 'ascending',
          layout_config = {
            prompt_position = 'top',
          },
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
              ['<esc>'] = actions.close,
              ['<c-j>'] = actions.move_selection_next,
              ['<c-k>'] = actions.move_selection_previous,
            },
          },
        },
        pickers = {
          find_files = {
            hidden = false,
            find_command = {
              'rg',
              '--files',
              '--hidden',
              '--glob',
              '!.git/*',
              '--glob',
              '!**/.Rpro.user/*',
              '--glob',
              '!_site/*',
              '--glob',
              '!docs/**/*.html',
              '-L',
            },
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
          },
        },
      }
      telescope.load_extension 'fzf'
      telescope.load_extension 'ui-select'
      telescope.load_extension 'dap'
    end,
  },

  { -- Highlight todo, notes, etc in comments
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },

  { -- edit the file system as a buffer
    'stevearc/oil.nvim',
    config = function()
      require('oil').setup({
        keymaps = {
          ['<C-s>'] = false,
          ['<C-h>'] = false,
          ['<C-l>'] = false,
          -- Fuzzy find files in current directory
          ['<leader>ff'] = {
            function()
              require('misc.pickers').find_files({ cwd = require('oil').get_current_dir() })
            end,
            desc = '[f]ind files in dir',
          },
          -- Live grep in current directory
          ['<leader>fg'] = {
            function()
              require('misc.pickers').live_grep({ cwd = require('oil').get_current_dir() })
            end,
            desc = '[g]rep in dir',
          },
        },
        view_options = {
          show_hidden = true,
        },
      })
    end,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      -- ORIGINAL: { '-', ':Oil<cr>', desc = 'oil' }, -- Changed to <leader>eo to free '-' for decrement
      { '<leader>eo', ':Oil<cr>', desc = '[o]il' },
      { '<leader>ef', ':Oil<cr>', desc = 'edit [f]iles' },
    },
    cmd = 'Oil',
  },

  { -- statusline
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    config = function()
      local function macro_recording()
        local reg = vim.fn.reg_recording()
        if reg == '' then return '' end
        return '📷[' .. reg .. ']'
      end

      -- Short filename with parent dir (e.g., "plugins/ui.lua")
      local function short_path()
        local filename = vim.fn.expand('%:t')
        if filename == '' then
          -- Scratch buffer - show cwd
          return '[' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t') .. ']'
        end
        local parent = vim.fn.expand('%:p:h:t')
        if parent == '' or parent == filename then return filename end
        return parent .. '/' .. filename
      end

      -- Truncated full path - shows full path, truncates if too long
      local function truncated_path()
        -- %:p = full path, %:~ = replace home with ~
        local path = vim.fn.expand('%:p:~')
        if path == '' then
          -- Scratch buffer - show full cwd path
          return vim.fn.fnamemodify(vim.fn.getcwd(), ':~')
        end

        local max_len = math.floor(vim.o.columns * 0.3)  -- 30% of screen width
        if #path <= max_len then return path end

        -- Truncate from the left, keeping the filename and some path context
        local sep = vim.fn.has('win32') == 1 and '\\' or '/'
        local parts = vim.split(path, '[/\\]')
        if #parts <= 2 then
          return '…' .. path:sub(-(max_len - 1))
        end

        -- Keep first part (~ or drive), ellipsis, and some trailing context
        local first = parts[1]
        local remaining = max_len - #first - 4  -- 4 for sep + "…" + sep

        -- Build path from the end until we run out of space
        local tail = ''
        for i = #parts, 2, -1 do
          local part = parts[i]
          if #tail + #part + 1 > remaining then break end
          tail = sep .. part .. tail
        end

        if tail ~= '' then
          return first .. sep .. '…' .. tail
        end
        return '…' .. sep .. parts[#parts]
      end

      require('lualine').setup {
        options = {
          section_separators = '',
          component_separators = '│',
          globalstatus = true,
          theme = 'auto',
        },
        sections = {
          lualine_a = { 'mode', macro_recording },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { short_path, truncated_path, 'searchcount' },
          lualine_x = { 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
        extensions = { 'quickfix', 'lazy' },
      }
    end,
  },

  { -- nicer-looking tabs with close icons
    'nanozuki/tabby.nvim',
    enabled = false,
    config = function()
      require('tabby.tabline').use_preset 'tab_only'
    end,
  },

  { -- scrollbar
    'dstein64/nvim-scrollview',
    enabled = false,
    event = 'VeryLazy',
    opts = {
      current_only = true,
    },
  },

  { -- highlight occurences of current word
    'RRethy/vim-illuminate',
    enabled = true,
  },

  { -- filetree
    'nvim-tree/nvim-tree.lua',
    enabled = false,
    keys = {
      { '<c-b>', ':NvimTreeToggle<cr>', desc = 'toggle nvim-tree' },
    },
    config = function()
      require('nvim-tree').setup {
        disable_netrw = true,
        update_focused_file = {
          enable = true,
        },
        git = {
          enable = true,
          ignore = false,
          timeout = 500,
        },
        diagnostics = {
          enable = true,
        },
      }
    end,
  },

  -- or a different filetree
  {
    'nvim-neo-tree/neo-tree.nvim',
    enabled = false,
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree',
    keys = {
      { '<c-b>', ':Neotree toggle<cr>', desc = 'toggle nvim-tree' },
    },
  },

  -- show keybinding help window
  {
    'folke/which-key.nvim',
    enabled = true,
    event = 'VeryLazy',
    config = function()
      require('which-key').setup {}
      require 'config.keymap'
    end,
  },

  { -- show tree of symbols in the current file
    'simrat39/symbols-outline.nvim',
    enabled = false,
    cmd = 'SymbolsOutline',
    keys = {
      { '<leader>lo', ':SymbolsOutline<cr>', desc = 'symbols outline' },
    },
    opts = {},
  },

  { -- or show symbols in the current file as breadcrumbs
    'Bekaboo/dropbar.nvim',
    enabled = function()
      return vim.fn.has 'nvim-0.10' == 1
    end,
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim',
    },
    config = function()
      -- turn off global option for windowline
      vim.opt.winbar = nil
      vim.keymap.set('n', '<leader>ls', require('dropbar.api').pick, { desc = '[s]ymbols' })
    end,
  },

  { -- terminal
    'akinsho/toggleterm.nvim',
    enabled = false,
    opts = {
      open_mapping = [[<c-\>]],
      direction = 'horizontal',
    },
  },

  { -- show diagnostics list
    -- PERF: Slows down insert mode if open and there are many diagnostics
    'folke/trouble.nvim',
    enabled = false,
    config = function()
      local trouble = require 'trouble'
      trouble.setup {}
      local function next()
        trouble.next { skip_groups = true, jump = true }
      end
      local function previous()
        trouble.previous { skip_groups = true, jump = true }
      end
      vim.keymap.set('n', ']t', next, { desc = 'next [t]rouble item' })
      vim.keymap.set('n', '[t', previous, { desc = 'previous [t]rouble item' })
    end,
  },

  { -- show indent lines
    'lukas-reineke/indent-blankline.nvim',
    enabled = true,
    main = 'ibl',
    event = 'VeryLazy',
    config = function()
      local highlight = {
        'RainbowRed',
        'RainbowYellow',
        'RainbowBlue',
        'RainbowOrange',
        'RainbowGreen',
        'RainbowViolet',
        'RainbowCyan',
      }

      local hooks = require 'ibl.hooks'
      -- create the highlight groups in the highlight setup hook, so they are reset
      -- every time the colorscheme changes
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, 'RainbowRed', { fg = '#E06C75' })
        vim.api.nvim_set_hl(0, 'RainbowYellow', { fg = '#E5C07B' })
        vim.api.nvim_set_hl(0, 'RainbowBlue', { fg = '#61AFEF' })
        vim.api.nvim_set_hl(0, 'RainbowOrange', { fg = '#D19A66' })
        vim.api.nvim_set_hl(0, 'RainbowGreen', { fg = '#98C379' })
        vim.api.nvim_set_hl(0, 'RainbowViolet', { fg = '#C678DD' })
        vim.api.nvim_set_hl(0, 'RainbowCyan', { fg = '#56B6C2' })
      end)
      require('ibl').setup {
        indent = {
          highlight = highlight,
          -- Use dot for indedtation character
          -- char = '∘',
          char = '·',
          -- char = { '∘', '·' },
          tab_char = '»',
        },
        scope = {
          char = '┃',
        },
      }
    end,
  },

  { -- highlight markdown headings and code blocks etc.
    'lukas-reineke/headlines.nvim',
    enabled = false,
    dependencies = 'nvim-treesitter/nvim-treesitter',
    config = function()
      require('headlines').setup {
        markdown = {
          query = vim.treesitter.query.parse(
            'markdown',
            [[
                (fenced_code_block) @codeblock
                ]]
          ),
          codeblock_highlight = 'CodeBlock',
        },
      }
    end,
    init = function()
      require("vim.treesitter.query").add_predicate("is-mise?", function(_, _, bufnr, _)
        local filepath = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0)
        local filename = vim.fn.fnamemodify(filepath, ":t")
        return string.match(filename, ".*mise.*%.toml$") ~= nil
      end, { force = true, all = false })
    end,
  },

  { -- render markdown with icons and formatting
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      anti_conceal = { enabled = false },
      file_types = { 'markdown', 'opencode_output' },
      heading = {
        -- Disable heading icons to avoid overlapping symbols
        enabled = false,
      },
      bullet = {
        -- Disable bullet rendering to avoid double-bullet issue
        enabled = false,
      },
      render_modes = { 'n', 'c' },
      win_options = {
        conceallevel = { rendered = 2 },
      },
    },
    ft = { 'markdown', 'Avante', 'copilot-chat', 'opencode_output' },
  },

  { -- show images in nvim!
    '3rd/image.nvim',
    enabled = false,
    dev = false,
    ft = { 'markdown', 'vimwiki' },
    config = function()
      -- Requirements
      -- https://github.com/3rd/image.nvim?tab=readme-ov-file#requirements
      -- check for dependencies with `:checkhealth kickstart`
      -- needs:
      -- sudo apt install imagemagick
      -- sudo apt install libmagickwand-dev
      -- sudo apt install liblua5.1-0-dev
      -- sudo apt install lua5.1
      -- sudo apt installl luajit

      local image = require 'image'
      image.setup {
        backend = 'kitty',
        integrations = {
          markdown = {
            enabled = true,
            only_render_image_at_cursor = true,
            filetypes = { 'markdown', 'vimwiki' },
          },
        },
        editor_only_render_when_focused = false,
        window_overlap_clear_enabled = true,
        -- window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', 'scrollview' },
        tmux_show_only_in_active_window = true,
        window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', 'scrollview', 'scrollview_sign' },
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 30,
        kitty_method = 'normal',
      }

      local function clear_all_images()
        local bufnr = vim.api.nvim_get_current_buf()
        local images = image.get_images { buffer = bufnr }
        for _, img in ipairs(images) do
          img:clear()
        end
      end

      local function get_image_at_cursor(buf)
        local images = image.get_images { buffer = buf }
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        for _, img in ipairs(images) do
          if img.geometry ~= nil and img.geometry.y == row then
            local og_max_height = img.global_state.options.max_height_window_percentage
            img.global_state.options.max_height_window_percentage = nil
            return img, og_max_height
          end
        end
        return nil
      end

      local create_preview_window = function(img, og_max_height)
        local buf = vim.api.nvim_create_buf(false, true)
        local win_width = vim.api.nvim_get_option_value('columns', {})
        local win_height = vim.api.nvim_get_option_value('lines', {})
        local win = vim.api.nvim_open_win(buf, true, {
          relative = 'editor',
          style = 'minimal',
          width = win_width,
          height = win_height,
          row = 0,
          col = 0,
          zindex = 1000,
        })
        vim.keymap.set('n', 'q', function()
          vim.api.nvim_win_close(win, true)
          img.global_state.options.max_height_window_percentage = og_max_height
        end, { buffer = buf })
        return { buf = buf, win = win }
      end

      local handle_zoom = function(bufnr)
        local img, og_max_height = get_image_at_cursor(bufnr)
        if img == nil then
          return
        end

        local preview = create_preview_window(img, og_max_height)
        image.hijack_buffer(img.path, preview.win, preview.buf)
      end

      vim.keymap.set('n', '<leader>io', function()
        local bufnr = vim.api.nvim_get_current_buf()
        handle_zoom(bufnr)
      end, { buffer = true, desc = 'image [o]pen' })

      vim.keymap.set('n', '<leader>ic', clear_all_images, { buffer = true, desc = 'image [c]lear' })
    end,
  },
}
