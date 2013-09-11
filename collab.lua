
local tArgs = { ... }
local id = tArgs[1]

if ( not id ) then
  print("No script ID received")
  return true
end

local contents_url = "http://collabedit.com/download?id=" .. id
 
local request = http.get(contents_url)
if(request) then
  local response = request.readAll()
  request.close()
 
  local file = fs.open(id, "w")
  file.write(response)
  file.close()
 
  os.run({}, id)
else
  print "Failed to fetch file"
end
