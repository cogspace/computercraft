-- Automated bread baker

local input = turtle.suckUp
local output = turtle.drop

local function inputOrSleep()
    if not input(1) then
        ---@diagnostic disable-next-line: undefined-field
        os.sleep(30)
    end
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
end