-- GitHub file loader

USER = "cogspace"
REPO = "computercraft"
BRANCH = "master"
FILENAME = "example.lua"

BASE_URL = "https://raw.githubusercontent.com"

local url = BASE_URL .. "/" ..  USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILENAME

local request = http.get( url )
local response = request.readAll()
request.close()

local file = fs.open( FILENAME, "w" )
file.write( response )
file.close()
