FUEL_SLOT = 1
LOGS_TAG = "minecraft:logs"
LEAVES_TAG = "minecraft:leaves"
IGNORE = {
    ['minecraft:fern'] = true,
    ['minecraft:large_fern'] = true,
    ['minecraft:grass'] = true,
    ['minecraft:dead_bush'] = true,
}

local function ensureFuel(n)
    while turtle.getFuelLevel() < n do
        local prevSelSlot = turtle.getSelectedSlot()
        turtle.select(FUEL_SLOT)
        if turtle.getItemCount() == 0 then
            error("Ran out of fuel :(")
        end
        turtle.refuel(1)
        turtle.select(prevSelSlot)
    end
end

local function settle()
    while not turtle.detectDown() do
        ensureFuel(1)
        turtle.down()
    end
end

local function cutWoodFront()
    local isBlock, block = turtle.inspect()
    if isBlock and block.tags[LOGS_TAG] then
        ensureFuel(1)
        turtle.dig()
    end
end

local function fellTree()
    -- Get into the tree meat (wood)
    ensureFuel(2)
    turtle.dig()
    turtle.forward()

    -- Face left so we can cut two columns at once if it's a big tree
    turtle.turnLeft()
    cutWoodFront()

    while true do
        local isBlock, block = turtle.inspectUp()
        if not isBlock or not block.tags[LOGS_TAG] then
            break
        end
        ensureFuel(2)
        turtle.digUp()
        turtle.up()
        cutWoodFront()
    end
    settle()
    while true do
        local isBlock, block = turtle.inspectDown()
        if not isBlock or not block.tags[LOGS_TAG] then
            break
        end
        ensureFuel(2)
        turtle.digDown()
        turtle.down()
        cutWoodFront()
    end

    -- Stop facing left
    turtle.turnRight()
end

-- Move forward exactly one step, cutting down trees
-- and moving around or through obstacles.
local function step()
    settle()
    local isBlock, block = turtle.inspect()
    if not isBlock or IGNORE[block.name] then
        ensureFuel(1)
        turtle.forward()
    elseif block.tags[LOGS_TAG] then
        fellTree()
    else
        -- It's some other block. Go over it.
        while true do
            ensureFuel(2)
            turtle.digUp()
            turtle.up()

            local isBlock, block = turtle.inspectUp()
            if not isBlock then
                ensureFuel(1)
                turtle.forward()
                break
            elseif block.tags[LEAVES_TAG] then
                ensureFuel(2)
                turtle.dig()
                turtle.forward()
                break
            elseif block.tags[LOGS_TAG] then
                fellTree()
                break
            end
        end
    end
end

local function cutLine(dist)
    for i = 1, dist do
        step()
    end
end

local function clearCut(diameter)
    for d = 1, diameter - 1 do
        cutLine(d)
        turtle.turnRight()
        cutLine(d)
        turtle.turnRight()
    end
    cutLine(diameter - 1)
end

clearCut(32)