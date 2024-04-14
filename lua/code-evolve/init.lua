local api = vim.api
local git_log_parser = require('code-evolve.parse-git-log')

local function open_or_create_file(file_path)
  if vim.fn.filereadable(file_path) == 1 then
    -- File exists, open it
    vim.cmd("edit " .. file_path)
  else
    -- File does not exist, create it
    vim.cmd("edit " .. file_path)
    vim.cmd("write")
  end
end

local function execute()
  local cmds = git_log_parser.parse()
  for i,c in ipairs(cmds) do
    if c[1] == 'file' then
      open_or_create_file(c[2])
    end
  end
end

local function setup(parameters)
end

api.nvim_create_user_command("EVExecute", execute, {bang = true, desc = "execute"})

return {setup = setup}

