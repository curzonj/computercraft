function report(str, tb)
  local url = "http://50.53.175.222:3000/logs?"

  for key, value in pairs(tb) do
    url_tmp = url .. key .. "=" .. tostring(value) .. "&"
    url = url_tmp
  end
  
  print(str)
  http.request(url, str)
end
