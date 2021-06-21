local function testForBlock(x, y, z, id)
    return exec(("execute if block %d %d %d %s"):format(x, y, z, id))
end

---Find every block of the given ID in the given volume and invoke callback for each such block.
---@param minX integer The minimum X value
---@param minY integer The minimum Y value
---@param minZ integer The minimum Z value
---@param maxX integer The maximum X value
---@param maxY integer The maximum Y value
---@param maxZ integer The maximum Z value
---@param id string The ID of the block to search for
---@param callback function Callback function to call with (x, y, z) for each matching block.
---@param stepX integer The X step size (default: 1)
---@param stepY integer The Y step size (default: 1)
---@param stepZ integer The Z step size (default: 1)
local function findBlocks(minX, minY, minZ, maxX, maxY, maxZ, id, callback, stepX, stepY, stepZ)
    if not stepX then stepX = 1 end
    if not stepY then stepY = 1 end
    if not stepZ then stepZ = 1 end

    if not callback then
        error("Callback function hit(x, y, z) must be provided.")
    end

    for x = minX, maxX, stepX do
        for z = minZ, maxZ, stepZ do
            for y = minY, maxY, stepY do
                if testForBlock(x, y, z, id) then
                    callback(x, y, z)
                end
            end
        end
    end
end

local function findDiamonds()
    findBlocks(0, 16, 0, 64, 0, 64)
    findBlocks(
        0, 16, 0,   -- Min (note: min Y > max Y)
        64, 0, 64,  -- Max (note: max Y < min Y)
        "diamond_ore", -- block ID
        function(x, y, z) -- hit callback
            print("Found diamonds at "..x.." "..y.." "..z.." !!")
        end,
        2, -2, 2    -- Step (note: Y step < 0)
    )
end

local commander = {
    testForBlock = testForBlock,
    findBlocks = findBlocks,
    findDiamonds = findDiamonds,
}

return commander
