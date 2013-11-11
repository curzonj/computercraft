os.loadAPI('hapi')

function init()
    if (fs.isDir("db_files") == false) then
        fs.makeDir("db_files")
    end
end

function print(tableInfo)
    for key, value in pairs(tableInfo) do
      print(key .. " = " .. tostring(value))
    end
end

function write(name, tableInfo)
    local path = "checkpoint_db/" .. name
    local handle = io.open(path, "w")
    
    for key, value in pairs(tableInfo) do
      handle:write(tostring(key))
      handle:write("\n")
      
      if value == nil then
          value = "---nil---"
      end
      
      handle:write(tostring(value))
      handle:write("\n")
    end
    
    handle:close()
end

function read(name)
    local path = "db_files/" .. name
    local handle = io.open(path, "r")
    
    if handle ~= nil then
       local line = handle.read()
       local part = "key"
       local resultTable = {}
       local tmpKey = nil
       
       while (line ~= nil) do
           if part == "key" then
               tmpKey = line
               part = "value"
           else
               resultTable[tmpKey] = line
               part = "key"
           end
           line = handle.read()
       end
       
       return resultTable
    else
        hapi.report("Failed to open db file: " .. name)
        return {}
    end
end
