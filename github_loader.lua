-- GitHub file loader

USER = "cogspace"
REPO = "computercraft"
BRANCH = "master"
FILENAME = "github_loader.lua"

BASE_URL = "https://raw.githubusercontent.com"

local url = (
	BASE_URL ..
	"/" .. USER ..
	"/" .. REPO ..
	"/" .. BRANCH ..
	"/" .. FILENAME ..
	"?c=" .. math.random()
)

local request = http.get( url )
if not request then
	print("Reading from URL failed: " .. url)
	exit()
end

local response = request.readAll()
request.close()

local file = fs.open( FILENAME, "w" )
file.write( response )
file.close()

print(("%d bytes written to %s"):format(#response, FILENAME))