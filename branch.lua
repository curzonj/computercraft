local prgm_args = {...};
if(prgm_args[1] == 'usage' or prgm_args[1] == '?' or prgm_args[1] == 'help')then
  print("miner <branches> <blocks between branches> <branch length>");
  return true;
end

local branches = tonumber(prgm_args[1]) or 20;
local branch_interval = (prgm_args[2]~=nil and tonumber(prgm_args[2])+1) or 4;
local branch_length = tonumber(prgm_args[3]) or 50;
local trunk_length = branches*branch_interval;
local torch_interval = 7;
 
function dumpJunk()
    for x = 1, 3 do
        junkCount = turtle.getItemCount(x) -- 1=cobblestone, 2=gravel, 3=dirt
        turtle.select(x)
        if junkCount > 1 then
            turtle.drop(junkCount - 1) -- keep 1
            junkCount = 0
        end
     end
     
     for i = 4, 15 do
        turtle.select(i)
        for x = 1, 3 do
            if turtle.compareTo(x) == true then
                turtle.drop()
            end
        end
    end
end

local cTrunk
local cBranch = 0;
function dig(length)
  local cLength = 0;
  local bDetect, bMoved;
  
  -- select the torches
  turtle.select(16)
  
  while(cLength < length)do
    repeat turtle.dig(); os.sleep(0.1); bDetect = turtle.detect(); until bDetect == false;
    bMoved = turtle.forward();
    if(bMoved)then
      cLength = cLength + 1;
      turtle.digUp();
      
      -- because sometimes it can move under a falling stack of gravel that blocks it's way back
      repeat turtle.digUp(); os.sleep(0.1); bDetect = turtle.detectUp(); until bDetect == false;
      
  
      if ((cLength % torch_interval) == 0) then
        turtle.back()
        turtle.placeUp()
        turtle.forward()
      end
    end
  end
end

turtle.turnLeft()
dig(branch_length)

for branch_counter = 1, branches do
  turtle.turnRight()
  dig(branch_interval)
  turtle.turnRight()
  dig(branch_length*2+1)
  
  turtle.turnLeft()
  dig(branch_interval)
  turtle.turnLeft()
  dig(branch_length*2+1)
  dumpJunk()
end

turtle.turnRight()
dig(branch_interval)
turtle.turnRight()
dig(branch_length+2)
turtle.turnRight()
dig(branch_interval*2*branches)
