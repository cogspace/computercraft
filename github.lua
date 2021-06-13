-- GitHub file loader
BASE_URL = "https://raw.githubusercontent.com"

local args = {...}
if #args < 3 or #args > 4 then
	print("Usage: github <user> <repo> <filename> [branch]")
	return
end

local user     = args[1]
local repo     = args[2]
local filename = args[3]
local branch   = args[4]

local cacheBuster = math.random(99999999999)

local url = BASE_URL.."/"..user.."/"..repo.."/"..branch.."/"..filename.."?"..cacheBuster
local request = http.get(url)

if not request then
	print("Reading from URL failed: " .. url)
	print("Note: Only public repositories are supported.")
	return
end

local response = request.readAll()
request.close()

local file = fs.open(filename, "w")
file.write(response)
file.close()

print(("%d bytes written to %s"):format(#response, filename))