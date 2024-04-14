-- function pprint(array) for i, v in ipairs(array) do print(i, v) end end
function pprint(obj, indent)
  indent = indent or 0
  if type(obj) == "table" then
    for k, v in pairs(obj) do
      if type(v) == "table" then
        print(string.rep(" ", indent) .. tostring(k) .. ":")
        pprint(v, indent + 4)
      else
        print(string.rep(" ", indent) .. tostring(k) .. ": " .. tostring(v))
      end
    end
  else
    print(string.rep(" ", indent) .. tostring(obj))
  end
end

function split(str, delimiter)
  local result = {}
  local pattern = string.format("([^%s]+)", delimiter)
  str:gsub(pattern, function(c) result[#result + 1] = c end)
  return result
end

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function lines_from(file)
  if not file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do lines[#lines + 1] = line end
  return lines
end

function parse_git_log(lines)
  local diffs = {}
  for k, v in pairs(lines) do
    if string.find(v, '^diff%s%-%-git%sa/') ~= nil then
      -- print('line[' .. k .. ']', v)
      table.insert(diffs, k)
    end
  end
  return diffs
end

function parse_diffs(diffs, lines)
  local commands = {}
  for i = 1, #diffs do
    local d = diffs[i]
    for j = d, #lines do
      local l = lines[j]
      if string.find(l, '^diff%s') ~= nil and j ~= d then break end

      if string.find(l, '^diff%s') ~= nil then
        local ss = split(l, ' b/')
        local file = ss[#ss]
        table.insert(commands, {'file', file})
      end

      if string.find(l, '^rename%sfrom') ~= nil then
        local file = l:gsub('rename from ', '')
        table.insert(commands, {'renameFrom', file})
      end

      if string.find(l, '^rename%sto') ~= nil then
        local file = l:gsub('rename to ', '')
        table.insert(commands, {'renameTo', file})
      end

      if string.find(l, '^commit') ~= nil then break end

      if (string.find(l, '^@@')) then
        local ss = l
        ss = ss:gsub('@@ ', '')
        ss = ss:gsub(' @@', '')
        ss = ss:gsub('-', '')
        ss = ss:gsub('+', '|')
        ss = ss:gsub(' ', '')
        ss = split(ss, '|')

        local ds = split(ss[1], ',')
        local deleteRow = tonumber(ds[1])
        local deleteRowCount = tonumber(ds[2]) - deleteRow

        local si = split(ss[2], ',')
        local insertRow = tonumber(si[1])

        table.insert(commands, {'cursor', deleteRow, deleteRowCount, insertRow})
      end

      if string.find(l, '^+') ~= nil and string.find(l, '^++') == nil then
        local lt = '>>' .. l
        lt = lt:gsub('>>+', '')
        lt = lt:gsub('\t', '  ')
        table.insert(commands, {'line', lt})
      end

      if string.find(l, '^ ') ~= nil then
        local lt = '>>' .. l
        lt = lt:gsub('>> ', '')
        lt = lt:gsub('\t', '  ')
        table.insert(commands, {'line', lt})
      end

      if string.find(l, '^-') ~= nil and string.find(l, '^--') == nil then
        local lt = '>>' .. l
        lt = lt:gsub('>>-', '')
        lt = lt:gsub('\t', '  ')
        table.insert(commands, {'delete', lt})
      end

      -- print(l)
    end
  end

  return commands
end

function git_log_to_commands(path)
  path = path or '/tmp/git.log'
  local lines = lines_from(path)
  local diffs = parse_git_log(lines)
  local commands = parse_diffs(diffs, lines)
  return commands
end

-- pprint(git_log_to_commands())

return {parse = git_log_to_commands}

