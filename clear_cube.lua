os.loadAPI('hapi')
os.loadAPI('table_db')

table_db.init()

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
    hapi.report("saving coordinates", coordinate_offsets)
    table_db.write("coordinate_offsets", coordinate_offsets)
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
     
    saveLocation()
end

function move(direction, times)
    times = times or 1
    
    while (times > 0) do
        move_once(direction)
        times = times - 1
    end
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
        
        moveResult = turtle_call("move", direction)
    end
    
    update_coordinate_offsets(direction)
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

function uturn(direction)
    if (direction == nil) then
        orient(opposite_directions[current_facing])
    elseif (direction == "up" or direction == "down") then
        move(direction)
        orient(opposite_directions[current_facing])
    else
        local was_facing = current_facing
        orient(direction)
        move("forward")
        orient(opposite_directions[was_facing])
    end
end

local callbacks = {}

function init(onFull)
    -- TODO should also check resume files
    callbacks["onFull"] = onFull
end

function returnHome()
    hapi.report("return to y")
    if (coordinate_offsets["y"] > 0) then
        move("down", coordinate_offsets["y"])
    elseif (coordinate_offsets["y"] < 0) then
        move("up", 0 - coordinate_offsets["y"])
    end 

    hapi.report("return to frontback")
    if (coordinate_offsets["frontback"] > 0) then
        orient("back")
        move("forward", coordinate_offsets["frontback"])
    elseif (coordinate_offsets["frontback"] < 0) then
        orient("front")
        move("forward", 0 - coordinate_offsets["frontback"])
    end
    
    hapi.report("return to leftright")
    if (coordinate_offsets["leftright"] > 0) then
        orient("left")
        move("forward", coordinate_offsets["leftright"])
    elseif (coordinate_offsets["leftright"] < 0) then
        orient("right")
        move("forward", 0 - coordinate_offsets["leftright"])
    end 
end
------

local quarry_side = "right"
local dig_direction = "down"
local width = 2
local depth = -2
local distance = 2
local exit_loop = false

coordinate_offsets["dig_direction"] = dig_direction

function onInventoryFull()
    print "my inventory is full"
end

function atDigLimits()
    return ( (dig_direction == "down" and coordinate_offsets["y"] <= depth) or (dig_direction == "up" and coordinate_offsets["y"] >= 0) )
end

init(onInventoryFull)
move("down")
orient(quarry_side)

while (not exit_loop) do
    move("forward", (width-1))

    if atDigLimits() then
      if (coordinate_offsets["frontback"] >= distance) then
          returnHome()
          exit_loop = true
      else
          uturn("front")
          dig_direction = opposite_directions[dig_direction]
          coordinate_offsets["dig_direction"] = dig_direction
      end
    else
      uturn(dig_direction)
    end
end
