-- CONSTANTS


local NUM_SLOTS = 16


-- UTILS


---Check that `test` is true, else throw err
---@param test boolean|nil Test value
---@param err string Error message
local function check(test, err)
    if not test then
        error(err)
    end
end

---Automatically refuel using the first available fuel item.
---Maintains previous selection.
---@param min number The minimum level to fuel up to
---@return boolean success If the refueling succeeded (else error)
local function refuel(min)
    local previousSelection = turtle.getSelectedSlot()
    while turtle.getFuelLevel() < min do
        local fueled = false
        for slot = 1, NUM_SLOTS do
            turtle.select(slot)
            if refuel(1) then
                fueled = true
                break
            end
        end
        if not fueled then
            -- If there's no fuel, throw an error.
            -- TODO: Make this optional?
            error("Ran out of fuel :(")
        end
    end
    turtle.select(previousSelection)
    return true
end

---Find and select an item with the provided name
---@param itemName string The name of the item to select (e.g. "minecraft:stone")
---@return boolean success Whether the item was successfully selected (else, error)
local function findAndSelect(itemName)
    if not itemName then
        return false
    end
    -- If the right item is already selected, don't do anything.
    local currentItem = turtle.getItemDetail()
    if currentItem and currentItem.name == itemName then
        return true
    end
    -- Otherwise, try to find the item.
    for slot = 1, NUM_SLOTS do
        local item = turtle.getItemDetail(slot)
        if item and item.name == itemName then
            return turtle.select(slot)
        end
    end
    -- If we can't find it, throw an error.
    -- TODO: Make this optional?
    error("Ran out of item '"..itemName.."' :(")
end

---Get the name of the currently selected item
---@return string|nil itemName The currently selected item name (or nil)
local function getSelectedItemName()
    local currentItem = turtle.getItemDetail()
    if currentItem then
        return currentItem.name
    end
    return nil
end

---Get the total count of a given item name including all stacks
---@param itemName string The name of the item to count
---@return integer total The total count of the item
local function getItemTotal(itemName)
    local count = 0
    for slot = 1, NUM_SLOTS do
        local item = turtle.getItemDetail(slot)
        if item and item.name == itemName then
            count = count + turtle.getItemCount(slot)
        end
    end
    return count
end


-- MOVEMENT


---Move forward, refueling first if necessary
---@return boolean success Whether moving succeeded or not
local function forward()
    refuel(1)
    return turtle.forward()
end

---Move back, refueling first if necessary
---@return boolean success Whether moving succeeded or not
local function back()
    refuel(1)
    return turtle.back()
end

---Move up, refueling first if necessary
---@return boolean success Whether moving succeeded or not
local function up()
    refuel(1)
    return turtle.up()
end

---Move down, refueling first if necessary
---@return boolean success Whether moving succeeded or not
local function down()
    refuel(1)
    return turtle.down()
end

local turnRight = turtle.turnRight
local turnLeft = turtle.turnLeft

---Turn 180 degrees
---@return boolean success If turning around succeeded (I don't think it can actually fail?)
local function turnAround()
    return turnRight() and turnRight()
end


-- DIGGING


---Dig forward, refueling first if necessary
---@return boolean success Whether digging succeeded or not
local function dig()
    refuel(1)
    return turtle.dig()
end

---Dig up, refueling first if necessary
---@return boolean success Whether digging succeeded or not
local function digUp()
    refuel(1)
    return turtle.digUp()
end

---Dig down, refueling first if necessary
---@return boolean success Whether digging succeeded or not
local function digDown()
    refuel(1)
    return turtle.digDown()
end

-- Dig out an entire contiguous blob of resources
-- local function digBlob(valuable)
--     return error("TODO")
-- end

---Dig multiple slots in one fell swoop
---@param down boolean Whether to dig downward
---@param forward boolean Whether to dig forward
---@param up boolean Whether to dig upward
---@return boolean|nil downSuccess, boolean|nil forwardSuccess, boolean|nil upSuccess Whether each requested digging operation succeeded
local function digMulti(down, forward, up)
    local downSuccess
    local forwardSuccess
    local upSuccess
    if down then
        downSuccess = digDown()
    end
    if forward then
        forwardSuccess = dig()
    end
    if up then
        upSuccess = digUp()
    end
    return downSuccess, forwardSuccess, upSuccess
end

---Dig and move up a specified number of blocks
---@param n integer The number of blocks to move upward (default: 1)
---@return boolean success Whether all moves succeeded
local function digAndMoveUp(n)
    if not n then
        n = 1
    end
    for _ = 1, n do
        digUp()
        if not up() then
            return false
        end
    end
    return true
end

---Dig and move forward a specified number of blocks
---@param n integer The number of blocks to move forward (default: 1)
---@return boolean success Whether all moves succeeded
local function digAndMove(n)
    if not n then
        n = 1
    end
    for _ = 1, n do
        dig()
        if not forward() then
            return false
        end
    end
    return true
end

---Dig and move down a specified number of blocks
---@param n integer The number of blocks to move downward (default: 1)
---@return boolean success Whether all moves succeeded
local function digAndMoveDown(n)
    if not n then
        n = 1
    end
    for _ = 1, n do
        digDown()
        if not down() then
            return false
        end
    end
    return true
end

---Dig forward (and optionally up and down) and move forward the specified distance
---@param n integer The number of blocks to move forward (default: 1)
---@param down boolean Whether to dig downward each step
---@param up boolean Whether to dig upward each step
---@return boolean success Whether all moves succeeded
local function digMultiAndMove(n, down, up)
    if not n then
        n = 1
    end
    for _ = 1, n do
        digMulti(down, true, up)
        if not forward() then
            return false
        end
    end
    return true
end

---Dig out a box with specified dimensions. Negative dimensions will dig left / down / backward.
---@param x integer Width of the box (including the turtle). Positive = right.
---@param y integer Height of the box (including the turtle). Positive = up.
---@param z integer Depth of the box (including the turtle). Positive = forward.
local function digBox(x, y, z)
    if not x or not y or not z then
        warn("[Tortuga] digBox() called with zero dimension (x="..x..", y="..y..", z="..z.."). Doing nothing.")
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

    local function uTurn(i, doDigDown, doDigUp)
        if i % 2 == 1 then
            -- Clockwise U-turn
            turnRight()
            digMultiAndMove(1, doDigDown, doDigUp)
            turnRight()
        else
            -- Anticlockwise U-turn
            turnLeft()
            digMultiAndMove(1, doDigDown, doDigUp)
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
            for i = 1, x do
                digMultiAndMove(z-1, true, true)
                if i < x then
                    uTurn(i, true, true)
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

            digUp()
            digDown()
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
        moveLayers(sliceRemainder-1)
        for i = 1, x do
            digMultiAndMove(z-1, true, true)
            if i < x then
                uTurn(i, true, true)
            end
        end
        if goingUp then
            digUp()
        else
            digDown()
        end
    end
end


-- PLACEMENT


---Place a specified item (or the currently selected item) in front of the turtle
---@param itemName string|nil The name of the item to place (or whatever is selected)
---@return boolean success Whether placing the item succeeded
local function place(itemName)
    refuel(1)
    if itemName then
        findAndSelect(itemName)
    end
    return turtle.place()
end

---Place a specified item (or the currently selected item) above the turtle
---@param itemName string|nil The name of the item to place (or whatever is selected)
---@return boolean success Whether placing the item succeeded
local function placeUp(itemName)
    refuel(1)
    if itemName then
        findAndSelect(itemName)
    end
    return turtle.placeUp()
end

---Place a specified item (or the currently selected item) below the turtle
---@param itemName string|nil The name of the item to place (or whatever is selected)
---@return boolean success Whether placing the item succeeded
local function placeDown(itemName)
    refuel(1)
    if itemName then
        findAndSelect(itemName)
    end
    return turtle.placeDown()
end

---Place a line of the same item.
---@param length integer The length of the line
---@param itemName string|nil The name of the item to place (or whatever is selected)
local function placeLine(length, itemName)
    for i = 1, length do
        if itemName then
            findAndSelect(itemName)
        end
        place(itemName)
        back()
    end
end

-- Place the same item multiple times (options: down, forward, and up)
---comment
---@param doPlaceDown boolean Whether to place an item downward
---@param doPlaceForward boolean Whether to place an item forward
---@param doPlaceUp boolean Whether to place an item upward
---@param itemName string|nil The name of the item to place (or whatever is selected)
---@return boolean success Whether all requested placements succeeded
local function placeMulti(doPlaceDown, doPlaceForward, doPlaceUp, itemName)
    if doPlaceDown and not placeDown(itemName) then
        return false
    end
    if doPlaceForward and not place(itemName) then
        return false
    end
    if doPlaceUp and not placeUp(itemName) then
        return false
    end
    return true
end

---Builds a wall up to 3 blocks tall
---@param length integer The length of the wall
---@param height integer The height of the wall (must be 1-3)
---@param itemName string The name of the item to place (default: the currently selected item)
---@param dontMoveUpAtStart boolean|nil Whether to skip moving up at the start (and down at end), in which case it must be done manually.
local function placeWall(length, height, itemName, dontMoveUpAtStart)
    check(length and length >= 1, "placeWall() called with non-positive length: "..length)
    check(height and height >= 1 and height <= 3, "placeWall() called with invalid height: "..height.." (must be 1-3)")
    if not itemName then
        itemName = getSelectedItemName()
    end
    local qty = length * height
    check(
        getItemTotal(itemName) >= qty,
        "Not enough of item '"..itemName.."' to complete construction ("..qty.." needed)"
    )

    if not dontMoveUpAtStart then
        check(up(), "Not enough room to place wall / maneuver")
    end
    for _ = 1, length do
        check(placeDown(itemName), "Failed to place item")
        if height > 2 then
            check(placeUp(itemName), "Failed to place item")
        end
        check(back(), "Not enough room to place wall / maneuver")
        if height > 1 then
            check(place(itemName), "Failed to place item")
        end
    end
    if not dontMoveUpAtStart then
        check(down(), "Not enough room to place wall / maneuver")
    end
    return true
end

---Place a rectangle of walls using the specified item
---@param width integer Width of the rectangular area (including walls)
---@param height integer Height of the walls (1-3)
---@param length integer Length of the rectangular area (including walls)
---@param itemName string|nil Name of the item to use (or whatever is selected)
local function placeWalls(width, height, length, itemName)
    check(length and length >= 1, "placeWall() called with non-positive length: "..length)
    check(width and width >= 1, "placeWalls() called with non-positive width: "..width)
    check(height and height >= 1 and height <= 3, "placeWall() called with invalid height: "..height.." (must be 1-3)")

    if not itemName then
        itemName = getSelectedItemName()
    end

    local qty = (width-1)*2*height + (length-1)*2*height
    check(
        getItemTotal(itemName) >= qty,
        "Not enough of item '"..itemName.."' to complete construction ("..qty.." needed)"
    )

    turnAround()
    check(up(), "Not enough space to place walls / maneuver")
    placeWall(length-1, height, itemName, true)
    turnRight()
    placeWall(width-1, height, itemName, true)
    turnRight()
    placeWall(length-1, height, itemName, true)
    turnRight()
    -- Stop one block shy of filling the last wall so the turtle doesn't back into the first wall
    placeWall(width-2, height, itemName, true)
    -- Place the last column of blocks
    for _ = 1, height do
        check(placeDown(itemName), "Failed to place item")
        check(up(), "Not enough space to place walls / maneuver")
    end
end


-- EXPORT


local tortuga = {
    -- Constants
    NUM_SLOTS = NUM_SLOTS,

    -- Utils
    check = check,
    refuel = refuel,
    findAndSelect = findAndSelect,
    getItemTotal = getItemTotal,
    getSelectedItemName = getSelectedItemName,

    -- Movement
    forward = forward,
    back = back,
    up = up,
    down = down,
    turnRight = turnRight,
    turnLeft = turnLeft,
    turnAround = turnAround,

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

    -- Placement
    place = place,
    placeUp = placeUp,
    placeDown = placeDown,
    placeLine = placeLine,
    placeMulti = placeMulti,
    placeWall = placeWall,
    placeWalls = placeWalls,
}

return tortuga