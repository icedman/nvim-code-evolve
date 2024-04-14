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

local function move_cursor_left()
  local winnr = 0
  local row, col = unpack(api.nvim_win_get_cursor(winnr))
  if col > 1 then api.nvim_win_set_cursor(winnr, {row, col - 1}) end
end

local function move_cursor_right()
  local winnr = 0
  local row, col = unpack(api.nvim_win_get_cursor(winnr))
  local line_content = api.nvim_buf_get_lines(winnr, row - 1, row, false)[1]

  if col > #line_content then
    api.nvim_buf_set_text(winnr, row - 1, col - 1, row - 1, col - 1, {" "})
    col = col + 1
  end

  api.nvim_win_set_cursor(winnr, {row, col + 1})
end

local function move_cursor_up()
  local winnr = 0
  local row, col = unpack(api.nvim_win_get_cursor(winnr))
  if row > 1 then api.nvim_win_set_cursor(winnr, {row - 1, col}) end
end

local function move_cursor_down()
  local winnr = 0
  local row, col = unpack(api.nvim_win_get_cursor(winnr))
  local total_lines = api.nvim_buf_line_count(winnr)
  if row == total_lines then
    api.nvim_buf_set_lines(winnr, row - 1, row - 1, false, {""})
  end
  api.nvim_win_set_cursor(winnr, {row + 1, col})
end

local function move_cursor_to_position(new_row, new_col)
  --git_log_parser.pprint({'move_cursor_to_position', new_row, new_col})
  local winnr = 0
  local current_row, current_col = unpack(api.nvim_win_get_cursor(winnr))

  --git_log_parser.pprint({'current', current_row, current_col})

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

local function strip_whitespace(str) return (string.match(str, "^%s*(.-)%s*$")) end

local function move_cursor_down_until_text_found(target_text)
  target_text = strip_whitespace(target_text)

  local current_row, _ = unpack(api.nvim_win_get_cursor(0))
  local current_line = api.nvim_buf_get_lines(0, current_row - 1, current_row,
                                              false)[1]
  local depth = 0
  -- Move down until target text is found or until end of buffer
  current_line = strip_whitespace(current_line)
  while current_line ~= nil and
      not string.find(current_line, target_text, 1, true) do
    move_cursor_down()
    current_row, _ = unpack(api.nvim_win_get_cursor(0))
    current_line =
        api.nvim_buf_get_lines(0, current_row - 1, current_row, false)[1]
    current_line = strip_whitespace(current_line)
    depth = depth + 1
    if depth > 4 then
      current_line = nil
      break
    end
  end

  --print(text)
  if current_line ~= nil then
    print('found')
  else
    print('???')
  end


  -- If target text is found, return true; otherwise, return false
  return current_line ~= nil
end

local function delete_current_line()
  local current_row, _ = unpack(api.nvim_win_get_cursor(0))
  api.nvim_buf_set_lines(0, current_row - 1, current_row, false, {""})
end

local function execute()
  if #commands == 0 then return end

  local c = table.remove(commands, 1)

  --git_log_parser.pprint(c)

  if c[1] == 'file' then
    local path = c[2]
    open_or_switch_buffer(c[2])
    api.nvim_win_set_cursor(0, {1, 0})
    lastCursorPosition = nil
  end

  print(c[1])

  if c[1] == 'cursor' then

    local deleteRow = c[2];
    local deleteRowCount = c[3];
    local insertRow = c[4];

    local row = deleteRow
    local col = 0
    local pos = {row, col}
    --git_log_parser.pprint(pos)

    move_cursor_to_position(row+1, col)
    -- api.nvim_win_set_cursor(0, pos)
    lastCursorPosition = pos

  end

  if c[1] == 'delete' then
    local text = c[2]
    local found = false
    found = move_cursor_down_until_text_found(text)
    if not found then
      if lastCursorPosition ~= nil then
        move_cursor_to_position(lastCursorPosition[1]+1, lastCursorPosition[2])
        found = move_cursor_down_until_text_found(text)
      end
      if found then delete_current_line() end
    end
  end

  if c[1] == 'find' then
    local text = c[2]
    print('find-----' .. text)
    move_cursor_down_until_text_found(text)
  end

  if c[1] == 'renameFrom' then end

  if c[1] == 'renameTo' then end

  if c[1] == 'line' then
    local text = c[2]
    -- print(text)
    api.nvim_put({text}, 'l', false, true)
  end

  if #commands > 0 then vim.defer_fn(function() execute() end, 100) end

end

local function load_and_execute()
  commands = git_log_parser.parse()
  execute()
end

local function stop() commands = {} end

local function setup(parameters) end

api.nvim_create_user_command("EVRun", load_and_execute,
                             {bang = true, desc = "execute"})
api.nvim_create_user_command("EVStop", stop, {bang = true, desc = "execute"})

return {setup = setup}

