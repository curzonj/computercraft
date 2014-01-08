local tArgs = { ... }
local current_level = turtle.getFuelLevel()
local target = tonumber(tArgs[1] or "20000")

while (current_level < target) do
    turtle.placeDown()
    turtle.refuel()

    current_level = turtle.getFuelLevel()
    print("Fuel level:")
    print(current_level)
    sleep(2)
end
