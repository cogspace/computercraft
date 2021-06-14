-- Automatically refuel using the first available fuel item.
local function refuel(min)
    while turtle.getFuelLevel() < min do
        local previousSelection = turtle.getSelectedSlot()
        local fueled = false
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(1) then
                fueled = true
                break
            end
        end
        if not fueled then
            return error("[Tortuga] Ran out of fuel :(")
        end
        turtle.select(previousSelection)
    end
    return true
end

-- Dig forward, refueling first if necessary
local function dig()
    refuel(1)
    return turtle.dig()
end

-- Dig up, refueling first if necessary
local function digUp()
    refuel(1)
    return turtle.digUp()
end

-- Dig down, refueling first if neceesary
local function digDown()
    refuel(1)
    return turtle.digDown()
end

-- Move forward, refueling first if necessary
local function forward()
    refuel(1)
    return turtle.forward()
end

-- Move up, refueling first if necessary
local function up()
    refuel(1)
    return turtle.up()
end

-- Move down, refueling first if necessary
local function down()
    refuel(1)
    return turtle.down()
end

-- Dig out an entire contiguous blob of resources
-- local function digBlob(valuable)
--     return error("TODO")
-- end

local turnRight = turtle.turnRight
local turnLeft = turtle.turnLeft

--[[
    Dig multiple slots in one fell swoop (down, forward, up)
]]
local function digMulti(down, forward, up)
    if down then
        digDown()
    end
    if forward then
        dig()
    end
    if up then
        digUp()
    end
end

--[[
    Dig and move up a specified number of blocks (n)
]]
local function digAndMoveUp(n)
    if not n then
        n = 1
    end
    for _ = 1, n do
        digUp()
        up()
    end
end

--[[
    Dig and move forward a specified number of blocks (n)
]]
local function digAndMove(n)
    if not n then
        n = 1
    end
    for _ = 1, n do
        dig()
        forward()
    end
end

--[[
    Dig and move down a specified number of blocks (n)
]]
local function digAndMoveDown(n)
    if not n then
        n = 1
    end
    for _ = 1, n do
        digDown()
        down()
    end
end

local function digMultiAndMove(n, down, up)
    if not n then
        n = 1
    end
    for _ = 1, n do
        digMulti(down, true, up)
        forward()
    end
end

--[[
    Dig out a box with dimensions x (right), y (up), z (forward).
    Negative dimensions will dig left/down/backward.
]]
local function digBox(x, y, z)
    if not x or not y or not z then
        print("[Tortuga] Warning: digBox() called with zero dimension ("..x..","..y..","..z.."). Doing nothing.")
        return
    end
    -- If digging backwards, turn around and flip x and z
    if z < 0 then
        turnRight()
        turnRight()
        x = -x
        z = -z
    end
    local goingUp = y > 0
    if x < 0 then
        x, z = z, -x
        turnLeft()
    end
    if not goingUp then
        y = -y
    end

    -- At this point, x, y, z are all positive

    -- Figure out how many full-height (3) slices we need to remove.
    -- This is much faster and more fuel efficient than going layer by layer.
    local fullSlices = math.floor(y / 3)
    local sliceRemainder = y % 3

    local function uTurn(i)
        if i % 2 == 1 then
            -- Clockwise U-turn
            turnRight()
            digMultiAndMove(1, true, true)
            turnRight()
        else
            -- Anticlockwise U-turn
            turnLeft()
            digMultiAndMove(1, true, true)
            turnLeft()
        end
    end

    local function moveLayers(n)
        if goingUp then
            digAndMoveUp(n)
        else
            digAndMoveDown(n)
        end
    end

    -- Remove complete 3-slices
    if fullSlices >= 1 then
        -- Shift to the middle of the first 3-slice
        moveLayers(1)
        for j = 1, fullSlices do
            for i = 1, x-1 do
                digMultiAndMove(z-1, true, true)
                if i ~= x-1 then
                    uTurn(i)
                end
            end

            -- Rotate to cut the next layer
            turnRight()
            if x % 2 == 1 then
                --[[
                    If there were an odd number of columns, we need to turn all the way around.
                    >-----,      <-----,
                    ,-----'  >>  ,-----'
                    '----->      '-----<
                ]]
                turnRight()
            else
                --[[
                    Otherwise, we are cutting on the other horizontal axis now and need to flip x and z.
                    ,----->      ,--,  V
                    '-----,  >>  |  |  |
                    ,-----'  >>  |  |  |
                    '-----<      V  '--'
                ]]
                x, z = z, x
            end

            if j < fullSlices-1 then
                -- Shift to the middle of the next 3-slice
                moveLayers(3)
            end
        end
        -- Shift to the top (positive y) or bottom (negative y) of the last 3-slice
        moveLayers(1)
    end

    -- Remove incomplete slices
    if sliceRemainder > 0 then
        moveLayers(sliceRemainder)
        for i = 1, x-1 do
            if goingUp then
                digMultiAndMove(z-1, true, false)
            else
                digMultiAndMove(z-1, false, true)
            end
            if i ~= x-1 then
                uTurn(i)
            end
        end
    end
end

return {
    -- Movement
    forward = forward,
    up = up,
    down = down,
    turnRight = turnRight,
    turnLeft = turnLeft,

    -- Digging
    dig = dig,
    digUp = digUp,
    digDown = digDown,
    digBox = digBox,
    --digBlob = digBlob,
    digMulti = digMulti,
    digAndMove = digAndMove,
    digAndMoveUp = digAndMoveUp,
    digAndMoveDown = digAndMoveDown,
    digMultiAndMove = digMultiAndMove,

    -- Util
    refuel = refuel,
}