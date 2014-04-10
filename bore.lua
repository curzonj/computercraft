local cLength = 0;
local torch_interval = 7;
local use_torches = (turtle.getItemCount(16) > 1);
local last_slot = 15;
local startupParamsFile = "bore_params.txt";

if not use_torches then
  last_slot = 16
end

function writeLocation(location)
  local locationFile = io.open(startupParamsFile, "w")
  locationFile:write(location)
  locationFile:write("\n")
  locationFile:close()
end

function goback()
  if (fs.exists("resuming.txt") == false) then
    turtle.turnRight()
    turtle.turnRight()

    local locationFile = io.open("resuming.txt", "w")
    locationFile:write("\n")
    locationFile:close()
  end

  local inputFile = fs.open(startupParamsFile, "r")
  local nextLine = inputFile.readLine()
  local backwards
  
  if (nextLine ~= nil) then
    local bLength = tonumber(nextLine)
    
    while (bLength > 0) do
      local bMoved = turtle.forward()
      if(bMoved)then
        bLength = bLength - 1;
        writeLocation(bLength);
      else
        turtle.dig()
      end
    end
  else
    print("Failed to find location file")
  end
  
  fs.delete(startupParamsFile)
  fs.delete("resuming.txt")
  fs.delete("startup")
end

if(fs.exists("startup") == true) then
  goback()
  
  return
end  
    
local outputFile = io.open("startup", "w")
-- Write an info message so that people know how to get out of auto-resume
outputFile:write("\nprint(\"Running auto-restart...\")\n")
outputFile:write("print(\"If you want to stop auto-resume and restore original state:\")\n")
outputFile:write("print(\"1) Hold Ctrl-T until the program terminates\")\n")
outputFile:write("print(\"2) Type \\\"rm startup\\\" (without quotes) and hit Enter\")\n")
outputFile:write("print(\"\")\n\n")

-- Write the code required to restart the turtle
outputFile:write("shell.run(\"")
outputFile:write(shell.getRunningProgram())
outputFile:write("\")\n")
outputFile:close()
  
while (turtle.getItemCount(last_slot) < 1) do
  repeat turtle.dig(); os.sleep(0.1); bDetect = turtle.detect(); until bDetect == false;
  local bMoved = turtle.forward();
  if(bMoved)then
    cLength = cLength + 1;
    writeLocation(cLength);

    turtle.digUp();
    
    -- because sometimes it can move under a falling stack of gravel that blocks it's way back
    repeat turtle.digUp(); os.sleep(0.1); bDetect = turtle.detectUp(); until bDetect == false;
    
    bDetect = turtle.detectDown()
    if not bDetect then
        turtle.select(1)
        turtle.placeDown()
    end
    
    if use_torches and ((cLength % torch_interval) == 0) then
      turtle.back()
      turtle.select(16)
      turtle.placeUp()
      turtle.forward()
    end
  end
end

goback()
