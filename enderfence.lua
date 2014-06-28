local tArgs = { ... }
local size = tonumber(tArgs[1])
local action = tArgs[2] or "build"
local current_slot = 16

turtle.select(current_slot)

if (size == nil) then
    error("Usage: enderfence 64 [remove]")
end

function buildRow(rowSize)
  for i=1, rowSize do
    if turtle.detect() then
      turtle.dig()
    end
    
    local bMoved = turtle.forward()
    while (not bMoved) do
            turtle.dig()
            turtle.attack();
            bMoved = turtle.forward()
    end
    
    if turtle.detectUp() then
        turtle.digUp()
    end
    
    if action == "build" then
    while (turtle.getItemCount(current_slot) == 0) do
        current_slot = current_slot - 1
        turtle.select(current_slot)

        if (current_slot == 0) then
            error("The turtle is empty")
        end
    end
    
    turtle.placeUp()
    end
  end
end

size = size - 1
buildRow(size)

turtle.turnLeft()
buildRow(size)

turtle.turnLeft()
buildRow(size)

turtle.turnLeft()
buildRow(size - 1)
