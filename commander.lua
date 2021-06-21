if not exec then
    error("This module can only be used on a Command Computer.")
end

---Check whether the block at coordinates (x, y, z) has the specified ID
---@param x integer The X coordinate of the block to check
---@param y integer The Y coordinate of the block to check
---@param z integer The Z coordinate of the block to check
---@param id string The block ID to check for
---@return boolean match Whether the specified block has the specified ID
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
---@param progress function Function to call for each step (for tracking progress)
local function findBlocksAsync(minX, minY, minZ, maxX, maxY, maxZ, id, callback, stepX, stepY, stepZ, progress)
    if not stepX then stepX = 1 end
    if not stepY then stepY = 1 end
    if not stepZ then stepZ = 1 end

    local total = (
        (maxX - minX / stepX) *
        (maxY - minY / stepY) *
        (maxZ - minZ / stepZ)
    )
    local current = 0

    for x = minX, maxX, stepX do
        for z = minZ, maxZ, stepZ do
            for y = minY, maxY, stepY do
                current = current + 1
                if testForBlock(x, y, z, id) then
                    callback(x, y, z)
                end
                if progress then
                    progress(current, total)
                end
            end
        end
    end
end

---Find every block of the given ID in the given volume and return the result
---@param minX integer The minimum X value
---@param minY integer The minimum Y value
---@param minZ integer The minimum Z value
---@param maxX integer The maximum X value
---@param maxY integer The maximum Y value
---@param maxZ integer The maximum Z value
---@param id string The ID of the block to search for
---@param stepX integer The X step size (default: 1)
---@param stepY integer The Y step size (default: 1)
---@param stepZ integer The Z step size (default: 1)
---@param progress function Function to call for each step (for tracking progress)
---@return table blocks List of the blocks found
local function findBlocks(minX, minY, minZ, maxX, maxY, maxZ, id, stepX, stepY, stepZ, progress)
    local blocks = {}
    local function addBlock(x, y, z)
        table.insert(blocks, { x=x, y=y, z=z })
    end
    findBlocksAsync(minX, minY, minZ, maxX, maxY, maxZ, id, addBlock, stepX, stepY, stepZ, progress)
    return blocks
end

local commander = {
    testForBlock = testForBlock,
    findBlocks = findBlocks,
    findBlocksAsync = findBlocksAsync,
}

return commander
