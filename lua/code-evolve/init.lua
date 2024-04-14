local api = vim.api
local git_log_parser = require('code-evolve.parse-git-log')

local current_bufnr = nil
local commands = {}
local lastCursorPosition = nil

local function open_or_switch_buffer(file_path)
  local buffer_number = vim.fn.bufnr(file_path)

  if buffer_number == -1 then
    vim.cmd('edit ' .. file_path)
  else
    vim.cmd('buffer ' .. buffer_number)
  end

  bufnr = vim.fn.bufnr(file_path)
end

function move_cursor_left()
  local winnr = 0
  local row, col = unpack(api.nvim_win_get_cursor(winnr))
  if col > 1 then api.nvim_win_set_cursor(winnr, {row, col - 1}) end
end

function move_cursor_right()
  local winnr = 0
  local row, col = unpack(api.nvim_win_get_cursor(winnr))
  local line_content = api.nvim_buf_get_lines(winnr, row - 1, row, false)[1]

  if col > #line_content then
    api.nvim_buf_set_text(winnr, row - 1, col - 1, row - 1, col - 1, {" "})
    col = col + 1
  end

  api.nvim_win_set_cursor(winnr, {row, col + 1})
end

function move_cursor_up()
  local winnr = 0
  local row, col = unpack(api.nvim_win_get_cursor(winnr))
  if row > 1 then api.nvim_win_set_cursor(winnr, {row - 1, col}) end
end

function move_cursor_down()
  local winnr = 0
  local row, col = unpack(api.nvim_win_get_cursor(winnr))
  local total_lines = api.nvim_buf_line_count(winnr)
  if row == total_lines then
    api.nvim_buf_set_lines(winnr, row - 1, row - 1, false, {""})
  end
  api.nvim_win_set_cursor(winnr, {row + 1, col})
end

function move_cursor_to_position(new_row, new_col)
  local winnr = 0
  local current_row, current_col = unpack(api.nvim_win_get_cursor(winnr))

  -- Move vertically, one line at a time
  while current_row < new_row do
    move_cursor_down()
    current_row = current_row + 1
  end
  while current_row > new_row do
    move_cursor_up()
    current_row = current_row - 1
  end

  -- Move horizontally, one column at a time
  while current_col < new_col do
    move_cursor_right()
    current_col = current_col + 1
  end
  while current_col > new_col do
    move_cursor_left()
    current_col = current_col - 1
  end
end

local function execute()
  if #commands == 0 then return end

  local c = table.remove(commands, 1)

  print(c[1])

  if c[1] == 'file' then
    local path = c[2]
    open_or_switch_buffer(c[2])
    lastCursorPosition = nil
  end

  if c[1] == 'cursor' then

    local deleteRow = c[2];
    local deleteRowCount = c[3];
    local insertRow = c[4];

    local row = deleteRow
    local col = 1
    local pos = {row, col}
    git_log_parser.pprint(pos)

    move_cursor_to_position(row, col)
    -- api.nvim_win_set_cursor(0, pos)
    lastCursorPosition = pos

  end

  if c[1] == 'delete' then end

  if c[1] == 'find' then end

  if c[1] == 'renameFrom' then end

  if c[1] == 'renameTo' then end

  if c[1] == 'line' then
    local text = c[2]
    -- print(text)
    api.nvim_put({text}, 'l', true, true)
  end

  if #commands > 0 then vim.defer_fn(function() execute() end, 100) end

end

local function load_and_execute()
  commands = git_log_parser.parse()
  execute()
end

local function setup(parameters) load_and_execute() end

api.nvim_create_user_command("EVExecute", load_and_execute,
                             {bang = true, desc = "execute"})

return {setup = setup}

