-- Automated bread baker

local input = turtle.suckUp
local output = turtle.drop

local function inputOrSleep()
    while not input(1) do
        ---@diagnostic disable-next-line: undefined-field
        os.sleep(30)
    end
end

term.write("Loaves baked: ")
local writeX, writeY = term.getCursorPos()
local loavesBaked = 0

local function incrementBreadCounter()
    loavesBaked = loavesBaked + 1
    term.setCursorPos(writeX, writeY)
    term.write(loavesBaked)
end

while true do
    -- Get 3 wheat in the right slots
    turtle.select(1)
    inputOrSleep()
    turtle.select(2)
    inputOrSleep()
    turtle.select(3)
    inputOrSleep()

    -- Craft bread
    turtle.select(16)
    turtle.craft()

    -- Output bread
    output()

    incrementBreadCounter()
end