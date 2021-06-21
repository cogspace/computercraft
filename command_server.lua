local cmd = require("commander")
local PROTOCOL = "cmd"
local HOSTNAME = "cmd_server"
local CREDIT_FILE = "credit.json"
local KEY_SIZE = 16

local CREDIT = {}

local err = {
    -- This error can be called as a handler
    invalidAction = function(id, msg)
        return { error = "Invalid action: '"..msg.action.."'. Try 'help'." }
    end,

    -- This error can be called as a handler
    nilAction = function(id, msg)
        return { error = "Action field is required. Try 'help'" }
    end,

    insufficientCredit = function(key)
        return {
            error = "Insufficient credit for requested transaction.",
            credit = CREDIT[key],
        }
    end,

    invalidKey = function(key)
        return { error = "Invalid key: '"..key.."'" }
    end,

    requiredField = function(fieldName)
        return { error = "Field '"..fieldName.."' is required."}
    end,
}

local function writeCreditFile()
    local creditFile = fs.open(CREDIT_FILE, "w")
    local json = textutils.serializeJSON(CREDIT)
    creditFile.write(json)
    creditFile.close()
end

local function readCreditFile()
    if not fs.exists(CREDIT_FILE) then
        writeCreditFile()
    end
    local creditFile = fs.open(CREDIT_FILE, "r")
    local json = creditFile.readAll()
    creditFile.close()
    CREDIT = textutils.unserializeJSON(json)
end


local function debit(key, creditAmount)
    if CREDIT[key] >= creditAmount then
        CREDIT[key] = CREDIT[key] - creditAmount
        return true
    end
    writeCreditFile()
    return false
end

---Credit a given API key with a given amount of credit.
---If the API key has no credit yet, it will be initialized to 0.
---
---@param key string The API key
---@param creditAmount integer The amount to credit
local function credit(key, creditAmount)
    if not CREDIT[key] then
        CREDIT[key] = 0
    end
    CREDIT[key] = CREDIT[key] + creditAmount
    writeCreditFile()
end


local CHARS = (
    "0123456789"..
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"..
    "abcdefghijklmnopqrstuvwxyz"..
    "_-"
)
local function randChar()
    local i = math.random(#CHARS)
    return string.sub(CHARS, i, i)
end

local function genKey()
    local key = ""
    for _ = 1, KEY_SIZE do
        key = key..randChar()
    end
    return key
end

local handlers = {
    help = function(id, msg)
        return {
            actions = {
                help = "You're looking at it.",
                ping = "Returns a pong, mostly useful for discovering the command server ID",
                genKey = "Generates a new API {key}. Keep it secret. Keep it safe.",
                credit = "Credits {key} by {amount}",
                testForBlock = "Checks if the block at {x, y, z} has block ID {id}",
            }
        }
    end,

    ping = function(id, msg)
        return { pong = true }
    end,

    genKey = function(id, msg)
        return {
            key = genKey(),
        }
    end,

    credit = function(id, msg)
        -- TODO: Make this cost something
        if not msg.key then
            return err.invalidKey(nil)
        end
        if not msg.amount then
            return err.requiredField('amount')
        end
        credit(msg.key, msg.amount)
        return { amount = msg.amount, success = true }
    end,

    testForBlock = function(id, msg)
        local cost = 1
        if not debit(msg.key, cost) then
            return err.insufficientCredit(msg.key)
        else
            local result = cmd.testForBlock(msg.x, msg.y, msg.z, msg.id)
            return {
                x = msg.x,
                y = msg.y,
                z = msg.z,
                id = msg.id,
                result = result
            }
        end
    end,
}

local function handleMessage(id, msg)
    local handler
    if not msg.action then
        handler = err.nilAction
    else
        handler = handlers[msg.action]
    end

    if not handler then
        handler = err.invalidAction
    end

    local res = handler(id, msg)
    if not res.action then
        res.action = "re:"..msg.action
    end
    rednet.send(id, res)
end

local function main()
    local modem = peripheral.find("modem")
    if not modem or not modem.isWireless() then
        error("No wireless modem attached!")
    end

    readCreditFile()

    rednet.open(modem)
    rednet.host(PROTOCOL, HOSTNAME)

    while true do
        local id, msg = rednet.receive(PROTOCOL)
        local ok, err = pcall(handleMessage, id, msg)
        if not ok then
            rednet.send(id, {
                error = "An unexpected error occurred. Check server logs for details."
            })
            local msgString = textutils.serialize(msg)
            warn("[!!] #"..id.." "..msgString.." >> "..err)
        end
    end
end

main()