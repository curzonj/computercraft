local cLength = 0;
local torch_interval = 7;
  
while(turtle.getItemCount(15) < 1) and (turtle.getItemCount(16) > 1)do
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
    
    if ((cLength % torch_interval) == 0) then
      turtle.back()
      turtle.select(16)
      turtle.placeUp()
      turtle.forward()
    end
  end
end
