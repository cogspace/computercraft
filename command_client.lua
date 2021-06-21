local PROTOCOL = "cmd"

local function call(serverId, action, args)
    if not args then
        args = {}
    end
    args.action = action
    rednet.send(serverId, args, PROTOCOL)
    return rednet.receive(PROTOCOL)
end

local function connect()
    local modem = peripheral.find("modem")
    if not modem or not modem.isWireless() then
        error("No wireless modem attached!")
    end
    local modemName = peripheral.getName(modem)
    rednet.open(modemName)
    local serverId = rednet.lookup('cmd')

    return {
        call = function(action, args)
            return call(serverId, action, args)
        end,

        genKey = function()
            return call(serverId, "genKey")
        end,

        credit = function(key, amount)
            return call(serverId, "credit", { key=key, amount=amount })
        end,

        testForBlock = function(key, x, y, z, id)
            return call(serverId, "testForBlock", { key=key, x=x, y=y, z=z, id=id })
        end,
    }
end


return {
    connect = connect
}