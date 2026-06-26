return {
  {
    'MunifTanjim/nui.nvim',
    keys = {
      {
        '<leader>tm',
        function()
          require('custom.tasks_ui').toggle()
        end,
        desc = 'Task panel',
      },
      {
        '<leader>tr',
        function()
          require('custom.tasks').quick_run()
        end,
        desc = 'Run task',
      },
      {
        '<leader>ts',
        function()
          local tasks = require 'custom.tasks'
          local name = tasks.current_name()
          if not name then
            require('custom.msgarea').echo_warn 'tasks: no task to stop'
            return
          end
          tasks.stop(name)
        end,
        desc = 'Stop task',
      },
      {
        '<leader>tK',
        function()
          local tasks = require 'custom.tasks'
          local name = tasks.current_name()
          if not name then
            require('custom.msgarea').echo_warn 'tasks: no task to kill'
            return
          end
          tasks.kill(name)
        end,
        desc = 'Kill task',
      },
      {
        '<leader>tv',
        function()
          require('custom.tasks').show_picker()
        end,
        desc = 'Open task panel',
      },
      {
        '<leader>th',
        function()
          local tasks = require 'custom.tasks'
          if not tasks.hide() then
            require('custom.msgarea').echo_warn 'tasks: task panel not open'
          end
        end,
        desc = 'Close task panel',
      },
      {
        '<leader>tH',
        function()
          require('custom.tasks').hide_all()
        end,
        desc = 'Close task panel',
      },
      {
        '<leader>ta',
        function()
          require('custom.tasks_ui').prompt_add()
        end,
        desc = 'Add task',
      },
      {
        '<leader>tT',
        function()
          require('custom.tasks_ui').toggle_terminal({ focus = true })
        end,
        desc = 'Toggle shell above task panel',
      },
    },
    config = function()
      local tasks = require 'custom.tasks'
      local tasks_ui = require 'custom.tasks_ui'

      vim.api.nvim_create_user_command('TaskUI', function()
        tasks_ui.toggle()
      end, { desc = 'Toggle workspace task panel' })

      vim.api.nvim_create_user_command('TaskRun', function(cmd_opts)
        local task = tasks.find_task(cmd_opts.args)
        if task then
          tasks.start(task)
        else
          tasks_ui.open({ focus = true })
        end
      end, {
        nargs = '?',
        complete = function()
          return vim.tbl_map(function(t)
            return t.name
          end, tasks.load())
        end,
        desc = 'Run a workspace task',
      })

      vim.api.nvim_create_user_command('TaskStop', function(cmd_opts)
        local name = cmd_opts.args ~= '' and cmd_opts.args or tasks.current_name()
        if name then
          tasks.stop(name)
        end
      end, {
        nargs = '?',
        complete = function()
          return vim.tbl_map(function(t)
            return t.name
          end, tasks.load())
        end,
        desc = 'Stop a workspace task',
      })

      vim.api.nvim_create_user_command('TaskKill', function(cmd_opts)
        local name = cmd_opts.args ~= '' and cmd_opts.args or tasks.current_name()
        if name then
          tasks.kill(name)
        end
      end, {
        nargs = '?',
        complete = function()
          return vim.tbl_map(function(t)
            return t.name
          end, tasks.load())
        end,
        desc = 'Hard kill a workspace task',
      })

      vim.api.nvim_create_user_command('TaskShow', function(cmd_opts)
        local task = tasks.find_task(cmd_opts.args)
        if task then
          tasks.show(task.name)
        else
          tasks_ui.open({ focus = true })
        end
      end, {
        nargs = '?',
        complete = function()
          return vim.tbl_map(function(t)
            return t.name
          end, tasks.load())
        end,
        desc = 'Show task output in panel',
      })

      vim.api.nvim_create_user_command('TaskHide', function()
        tasks.hide()
      end, { desc = 'Close the task panel' })

      vim.api.nvim_create_user_command('TaskAdd', function()
        tasks_ui.prompt_add()
      end, { desc = 'Add a workspace task' })

      vim.api.nvim_create_user_command('TaskTerminal', function()
        tasks_ui.toggle_terminal({ focus = true })
      end, { desc = 'Toggle shell above task panel' })
    end,
  },
}
