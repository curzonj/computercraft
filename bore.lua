local cLength = 0;
local torch_interval = 7;
local use_torches = (turtle.getItemCount(16) > 1);
local last_slot = 15;

if not use_torches then
        last_slot = 16
end
  
while (turtle.getItemCount(last_slot) < 1) do
  repeat turtle.dig(); os.sleep(0.1); bDetect = turtle.detect(); until bDetect == false;
  bMoved = turtle.forward();
  if(bMoved)then
    cLength = cLength + 1;
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
