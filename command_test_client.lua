local PROTOCOL = "cmd"

local function main()
    print("Connecting modem...")
    local modem = peripheral.find("modem")
    if not modem or not modem.isWireless() then
        error("No wireless modem attached!")
    end
    local modemName = peripheral.getName(modem)

    print("Opening modem...")
    rednet.open(modemName)

    print("Looking up cmd server ID...")
    local serverId = rednet.lookup('cmd')
    print(("Found command server ID = %d"):format(serverId))
    print("Sending help request...")
    rednet.send(serverId, { action = "help" }, PROTOCOL)
    print("Awaiting reply...")
    local id, msg = rednet.receive(PROTOCOL)
    print(("Received response from #%d: %s"):format(id, textutils.serialize(msg)))
end

main()