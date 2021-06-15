local t = require("tortuga")

local WHEAT = "minecraft:wheat"
local SEEDS = "minecraft:wheat_seeds"

local function cropReady()
    local isBlock, data = turtle.inspectDown()
    return isBlock and data.state and data.state.age == 7
end

local function farm()
    if cropReady() then
        t.digDown()
        t.placeDown(SEEDS)
    end
end

while true do
    -- Wait for the crop to be ready to harvest
    if cropReady() then
        -- Harvest and replant crop
        t.layer(7, 7, farm)
        -- Deposit wheat
        t.dropAllDown(WHEAT)
        -- Return to start position
        t.turnLeft()
        t.forward(6)
        t.turnLeft()
        t.forward(6)
        t.turnAround()
    end
    ---@diagnostic disable-next-line: undefined-field
    os.sleep(60)
end
