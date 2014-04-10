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
  local inputFile = fs.open(startupParamsFile, "r")
  local nextLine = inputFile.readLine()
  local backwards
  
  if (nextLine ~= nil) then
    backwards = tonumber(nextLine)
    local bLength = backwards;
    
    for i=1, backwards do
      turtle.back()
      bLength = bLength - 1;
      writeLocation(bLength);
    end
  else
    print("Failed to find location file")
  end
  
  if (fs.exists(startupParamsFile) == true) then
    fs.delete(startupParamsFile)
  end

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
  bMoved = turtle.forward();
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
