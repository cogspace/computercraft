-- Digs a single column down to bedrock, filling in gaps as it goes.
-- A player can safely ride down on top of the turtle.

FUEL_SLOT = 1
FILL_SLOT = 2
CLEAR_SLOT = 3

-- Fuel up
while turtle.getFuelLevel() < 100 do
    turtle.select(FUEL_SLOT)
    turtle.refuel(1)
end

-- Descend
while true do
    -- Use fill material to destroy lava or water
    turtle.select(CLEAR_SLOT)
    turtle.placeDown()

    -- Dig down
    turtle.digDown()
    turtle.down()

    -- Fill gaps
    turtle.select(FILL_SLOT)
    turtle.place()
    turtle.turnRight()
    turtle.place()
    turtle.turnRight()
    turtle.place()
    turtle.turnRight()
    turtle.place()

    -- Stop loop when we hit bedrock
    local isBlock, block = turtle.inspectDown()
    if isBlock and block.name == "minecraft:bedrock" then
        break
    end
end