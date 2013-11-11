-- http://collabedit.com/tjwqb

os.loadAPI('hapi')
os.loadAPI('table_db')

table_db.init()

---- Stack API

-- Create a Table with stack functions
function create_stack()

  -- stack table
  local t = {}
  -- entry table
  t._et = {}

  -- push a value on to the stack
  function t:push(...)
    if ... then
      local targs = {...}
      -- add values
      for _,v in pairs(targs) do
        table.insert(self._et, v)
      end
    end
  end

  -- pop a value from the stack
  function t:pop(num)

    -- get num values from stack
    local num = num or 1

    -- return table
    local entries = {}

    -- get values into entries
    for i = 1, num do
      -- get last entry
      if #self._et ~= 0 then
        table.insert(entries, self._et[#self._et])
        -- remove last value
        table.remove(self._et)
      else
        break
      end
    end
    -- return unpacked entries
    return unpack(entries)
  end

  -- get entries
  function t:getn()
    return #self._et
  end

  -- list values
  function t:list()
    for i,v in pairs(self._et) do
      print(i, v)
    end
  end
  return t
end


---- Persistance API

local startupBackup = "startup_bak"

function relaunchAtStartup(program_name)
      program_name = program_name or shell.getRunningProgram()
      
      if (fs.exists("startup") == true) then
        fs.delete(startupBackup)
        fs.copy("startup", startupBackup)
        outputFile = io.open("startup", "a")
      else
        outputFile = io.open("startup", "w")
      end
      
      -- Write an info message so that people know how to get out of auto-resume
      outputFile:write("\nprint(\"Running auto-restart...\")\n")
      outputFile:write("print(\"If you want to stop auto-resume and restore original state:\")\n")
      outputFile:write("print(\"1) Hold Ctrl-T until the program terminates\")\n")
      outputFile:write("print(\"2) Type \\\"rm startup\\\" (without quotes) and hit Enter\")\n")
      outputFile:write("print(\"\")\n\n")

      -- Write the code required to restart the turtle
      outputFile:write("shell.run(\"")
      outputFile:write(program_name)
      outputFile:write("\")\n")
      outputFile:close()
end

function cancelRelaunchAtStartup()
      fs.delete("startup")
      if (fs.exists(startupBackup) == true) then
        fs.move(startupBackup, "startup")
      end
end


----- Move API
-- dig is redundant on all methodcalls

function titlize(str)
    return str:gsub("^%l", string.upper)
end

function turtle_call(fn_name, direction, fn_arg)
    local resolved_name
    
    if (fn_name == "move") then
        resolved_name = direction
    elseif (direction == "forward") then
        resolved_name = fn_name
    else
        resolved_name = fn_name .. titlize(direction)
    end
    
    local fn = turtle[resolved_name]
    
    if(fn == nil) then
        error("No such method on turtle: " .. resolved_name)
    else
        return fn()
    end
end

local current_facing = "front"
local coordinate_offsets = { frontback = 0, y = 0, leftright = 0 }

function saveLocation()
    table_db.write("coordinate_offsets", coordinate_offsets)
    hapi.report("saved coordinates", coordinate_offsets)
end

function update_coordinate_offsets(direction)
    local axis
    local offset
    
    if (direction == "forward") then
        if (current_facing == "front") then
            axis = "frontback"
            offset = 1
        elseif (current_facing == "back") then
            axis = "frontback"
            offset = -1
        elseif (current_facing == "left") then
            axis = "leftright"
            offset = -1
        elseif (current_facing == "right") then
            axis = "leftright"
            offset = 1
        else
            error("Invalid current_facing: " .. current_facing)
        end
    else
        axis = "y"
        
        if (direction == "down") then
            offset = -1
        else
            offset = 1
        end
    end
    
    coordinate_offsets[axis] = coordinate_offsets[axis] + offset
end

function move(direction, times)
    times = times or 1
    
    while (times > 0) do
        move_once(direction)
        times = times - 1
    end
end

function atomic_move(direction)
    moveResult = turtle_call("move", direction)
    
    if (moveResult == true) then
        update_coordinate_offsets(direction)
        saveLocation()
    end

    return moveResult    
end

function move_once(direction)
    if (direction ~= "forward" and direction ~= "up" and direction ~= "down") then
        error("Invalid movement direction: " .. direction)
    end
    
    local digResult = turtle_call("dig", direction)
    local moveResult = turtle_call("move", direction) 
    local digCount = 0
    
    while (moveResult == false) do
        if (turtle_call("detect", direction)) then
            if (digCount ~= 0) then
                -- we dug, but we still couldn't move? Wait for sand and gravel
                sleep(0.1)
            end
            
            -- TODO check if inventory is full and deal with it
            turtle_call("dig", direction)
            digCount = digCount + 1
        elseif (turtle.getFuelLevel() == 0) then
            hapi.report("turtle is out of fuel")
            error("ran out of fuel")
        else
            -- we failed to move, but there's no blocks, must be a mob
            turtle_call("attack", direction)
        end
        
        moveResult = atomic_move(direction)
    end
end

-- [current_facing][target_facing]
local orientation_degrees = {
    left = {
        right = 180,
        front = 90,
        back = -90
    },
    right = {
        left = 180,
        front = -90,
        back = 90
    },
    front = {
        right = 90,
        left = -90,
        back = 180
    },
    back = {
        right = -90,
        left = 90,
        front = 180
    }
}

local opposite_directions = {
    left = "right",
    right = "left",
    front = "back",
    back = "front",
    up = "down",
    down = "up"
}

function orient(direction)
    if (direction ~= current_facing) then
        local degrees = orientation_degrees[current_facing][direction]
        
        if (degrees == 90) then
            turtle.turnRight()
        elseif (degrees == -90) then
            turtle.turnLeft()
        elseif (degrees == 180) then
            turtle.turnRight()
            turtle.turnRight()
        else
            error("Invalid orientation: " .. current_facing .. " transitioning to " .. direction)
        end
        
        current_facing = direction
    else
        error("Invalid orientation: " ..direction)
    end
end


function move_to(target)
    if (target["y"]) then
        if (coordinate_offsets["y"] > target["y"]) then
            move("down", coordinate_offsets["y"])
        elseif (coordinate_offsets["y"] < target["y"]) then
            move("up", 0 - coordinate_offsets["y"])
        end 
    end

    if (target["frontback"]) then
        if (coordinate_offsets["frontback"] > target["frontback"]) then
            orient("back")
            move("forward", coordinate_offsets["frontback"])
        elseif (coordinate_offsets["frontback"] < target["frontback"]) then
            orient("front")
            move("forward", 0 - coordinate_offsets["frontback"])
        end
    end
    
    if (target["leftright"]) then
        if (coordinate_offsets["leftright"] > target["leftright"]) then
            orient("left")
            move("forward", coordinate_offsets["leftright"])
        elseif (coordinate_offsets["leftright"] < target["leftright"]) then
            orient("right")
            move("forward", 0 - coordinate_offsets["leftright"])
        end
    end
end

local callbacks = {}
local myStack = create_stack()

function init(onFull)
    -- TODO should also check resume files
    -- TODO we need a callback to look for good ores on each move
    callbacks["onFull"] = onFull
end

function stack(method_n, limits_n)
    hapi.report("putting " .. method_n .. " on the stack", limits_n)
    myStack:push({ method = method_n, limits = limits_n })
end

function runStack(myCalltable)
    local executingStack = create_stack()
    local item = { method = "noop", limits = { } }
    
    for inventoryLoop = 1, 4 do
        if (item == nil) then
            break
        end
        
      method_n = item["method"]
      limits = item["limits"]
      
      print(method_n)
      table_db.printTable(limits)
      table_db.printTable(coordinate_offsets)
      
      if (limits_not_met(limits)) do
          hapi.report("limits not met, executing " .. method_n, limits)
          
          -- we put the item back on the stack so that it can reevaluate the
          -- limits when we finish what it asked us to do
          executingStack:push(item)
      
          myCalltable[method_n](limits)
          
          local myItem = myStack:pop()
        
          while (myItem) do
            executingStack:push(myItem)
            myItem = myStack:pop()
          end
      end
      
      -- TODO save the stack here
      
      item = executingStack:pop()
    end
end

function limits_not_met(target)
    return (
        ( target["y"] ~= nil and coordinate_offsets["y"] ~= target["y"] ) or
        ( target["frontback"] ~= nil and coordinate_offsets["frontback"] ~= target["frontback"] ) or
        ( target["leftright"] ~= nil and coordinate_offsets["leftright"] ~= target["leftright"] )
    )
end
------

local quarry_side = "right"
local dig_direction = "down"
local width = 2
local depth = -2
local distance = 2

function onInventoryFull()
    print "my inventory is full"
end

local calltable = { move_to = move_to }

-- TODO cutslice should be rewritten to only cut every 3rd row
function calltable:cutslice(conditions)
    stack("move", { frontback = coordinate_offsets["frontback"] + 1 })
    
    -- TODO a pattern matching cutline, refactor
    if (coordinate_offsets["y"] == 0) then
        stack("cutline", { y = depth })
    else
        stack("cutline", { y = 0 })
    end
end

function calltable:cutline(conditions)
    if (coordinate_offsets["leftright"] == 0) then
        stack("move_to", { leftright = width })
    else
        stack("move_to", { leftright = 0 })
    end
end


function main()
    -- relaunchAtStartup("tjwqb")
    
    init(onInventoryFull)

    stack("cutslice", { frontback= distance })
    stack("move_to", { frontback = 0, leftright = 0, y = 0 })
    runStack(calltable)
    
    -- cancelRelaunchAtStartup()
end

main()
