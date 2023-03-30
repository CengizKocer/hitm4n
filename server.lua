- Register the /hitman command
RegisterCommand('hitman', function(source, args, rawCommand)
    -- Check if the player has permission to use the command
    if not IsPlayerAceAllowed(source, 'command.hitman') then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Error', 'You do not have permission to use this command.' } })
        return
    end

    -- Make sure the player has specified a target
    if not args[1] then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Error', 'You must specify a target.' } })
        return
    end

    -- Get the player's target
    local target = tonumber(args[1])

    -- Make sure the target is valid
    if not target then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Error', 'Invalid target.' } })
        return
    end

    -- Make sure the target is a valid player
    local targetPed = GetPlayerPed(target)
    if not DoesEntityExist(targetPed) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Error', 'Invalid target.' } })
        return
    end

    -- Get the player's location
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)

    -- Spawn the hitman near the player
    local hitmanModel = GetHashKey('s_m_m_fibsec_01')
    RequestModel(hitmanModel)
    while not HasModelLoaded(hitmanModel) do
        Citizen.Wait(0)
    end
    local hitmanPed = CreatePed(4, hitmanModel, playerCoords.x, playerCoords.y, playerCoords.z, GetEntityHeading(playerPed) + 180.0, false, true)
    SetPedCombatAttributes(hitmanPed, 46, true) -- Make the hitman ignore explosions
    SetPedFleeAttributes(hitmanPed, 0, 0) -- Make the hitman not run away
    SetPedRelationshipGroupHash(hitmanPed, GetHashKey('HITMAN')) -- Set the hitman's relationship group

    -- Make the hitman attack the target
    TaskCombatPed(hitmanPed, targetPed, 0, 16)

    -- Tell the player that the hitman is on the way
    TriggerClientEvent('chat:addMessage', source, { args = { '^2Success', 'Hitman on the way.' } })
end)

-- Add the HITMAN relationship group to the game
Citizen.CreateThread(function()
    AddRelationshipGroup('HITMAN')
end)