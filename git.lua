local tArgs = { ... }
local contents_name = tArgs[1]
 
local repo = "curzonj/computercraft/master"
local contents_url = "https://raw.github.com/" .. repo .. "/" .. contents_name .. ".lua"
 
local request = http.get(contents_url)
if(request) then
  local response = request.readAll()
  request.close()
 
  local file = fs.open(contents_name, "w")
  file.write(response)
  file.close()
 
  os.run({}, contents_name)
else
  print "Failed to fetch file"
end
