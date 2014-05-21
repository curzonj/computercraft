--Computer Craft script to set up a fence boundary for an ender quarry
--Just run the program and give it the size of the quarry you want
--Author: Vanhal
--http://www.youtube.com/VanhalMinecraft

local currentSlot = -1

function refuel()
  if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < 10 then
    for i = 1, 16 do
      turtle.select(i)
      if turtle.refuel(0) then
        turtle.refuel(1)
      end
    end
  end
end


function moveForward()
  refuel()
  if turtle.detect() then
    turtle.dig()
  end
  turtle.forward()
end

function placeFence()
  if turtle.detectUp() then
    turtle.digUp()
  end
  turtle.select(2)
  if turtle.getItemCount(2) > 0 then
    if currentSlot > 0 and turtle.compareTo(currentSlot) and turtle.getItemCount(currentSlot) > 0 then
      turtle.select(currentSlot)
    else
      currentSlot = 2
      for i=3, 16 do
        if turtle.compareTo(i) then
          currentSlot = i
          turtle.select(i)
        end
      end
    end
    turtle.placeUp()
  else
    error("No fences found in slot 2")
  end
end

--start script and prompt for size
shell.run('clear')
print("Please put some fuel in the first slot and put loads stacks of fences in at least the second slot")

--just do some error checking
if turtle.getItemCount(1) == 0 then
  error("No fuel in slot 1")
end
if turtle.getItemCount(2) == 0 then
  error("No Fences in slot 2")
end
turtle.select(1)
if turtle.refuel(0) == false then
  error("No fuel in slot 1")
end

print("How big you want each side of your quarry to be, max 240?")
local size = io.read()

size = tonumber(size)

function buildRow(rowSize)
  for i=1, rowSize do
    moveForward()
    placeFence()
  end
end

if size > 2 then
  size = size - 1
  buildRow(size)
  
  turtle.turnLeft()
  buildRow(size)

  turtle.turnLeft()
  buildRow(size)
  
  turtle.turnLeft()
  buildRow(size - 1)
  moveForward()
else
  error("Can't make a square of size 1")
end
