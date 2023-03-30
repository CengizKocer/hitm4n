local hitmanPed = nil
local missionActive = false
local missionTimer = nil
local targetBlip = nil

-- display gang selection menu
function DisplayGangSelectionMenu()
    local gangIndex = exports['mythic_notify']:DoCustomHudText('inform', 'Select a gang for the hitman:', 7500)
    for i, gang in ipairs(Config.GangList) do
        exports['mythic_notify']:DoCustomHudText('inform', i .. '. ' .. gang, 7500)
    end
    return tonumber(exports['qb-menu']:GetInput())
end

-- create hitman ped with selected gang affiliation
function CreateHitmanPed(selectedGang)
    local playerPed = GetPlayerPed(-1)
    local playerPos = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    hitmanPed = CreatePed(4, "mp_m_freemode_01", playerPos.x + 1, playerPos.y + 1, playerPos.z, playerHeading, true, false)
    local gangHash = GetHashKey(Config.GangList[selectedGang])
    SetPedRelationshipGroupHash(hitmanPed, gangHash)
    SetPedCombatAbility(hitmanPed, 100)
    SetPedCombatAttributes(hitmanPed, 0, true)
    GiveWeaponToPed(hitmanPed, GetHashKey("WEAPON_PISTOL"), 100, false, true)
end

-- handle mission activation when gang members approach hitman ped
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if hitmanPed ~= nil and not missionActive then
            local hitmanPos = GetEntityCoords(hitmanPed)
            local playerPed = GetPlayerPed(-1)
            local playerPos = GetEntityCoords(playerPed)
            local distance = #(hitmanPos - playerPos)
            if distance < Config.StartMissionDistance and IsPedInAnyVehicle(playerPed, false) == false then
                DrawText3D(hitmanPos.x, hitmanPos.y, hitmanPos.z + 1.0, "Press ~g~E~w~ to start hitman mission")
                if IsControlJustPressed(0, 38) then -- E key
                    StartHitmanMission()
                end
            end
        end
    end
end)

-- start hitman mission
function StartHitmanMission()
missionActive = true
exports['mythic_notify']:DoCustomHudText('inform', 'A hitman mission has started. Check your GPS for the location of the target.', 7500)
-- spawn target ped and important papers
local targetPed = CreatePed(4, "s_m_m_gaffer_01", -105.85, -983.62, 29.01, 270.0, true, false)
local papersObject = CreateObject(GetHashKey("prop_cs_documents_01"), -106.38, -983.14, 29.01, true, true, true)
local papersBlip = AddBlipForCoord(-106.38, -983.14, 29.01)
SetBlipSprite(papersBlip, 354)
SetBlipColour(papersBlip, 5)
SetBlipAsShortRange(papersBlip, true)

-- set target ped relationship group and health
local targetGroup = GetHashKey("CIVMALE")
SetPedRelationshipGroupHash(targetPed, targetGroup)
SetEntityHealth(targetPed, 200)

-- set target blip and make it visible to the hitman's gang members only
targetBlip = AddBlipForEntity(targetPed)
SetBlipSprite(targetBlip, 1)
SetBlipColour(targetBlip, 1)
for i, gang in ipairs(Config.GangList) do
    SetBlipHiddenOnLegend(targetBlip, true)
    if IsPlayerInGang(gang) then
        SetBlipHiddenOnLegend(targetBlip, false)
        SetBlipDisplay(targetBlip, 4)
        SetBlipAsShortRange(targetBlip, false)
    end
end

-- set hitman ped as the target's attacker
SetPedCombatAttributes(targetPed, 46, true)
SetPedCombatAttributes(targetPed, 2, false)
SetPedCombatAttributes(targetPed, 52, true)
SetPedCombatAttributes(targetPed, 1, false)
SetPedRelationshipGroupDefaultHash(targetPed, GetHashKey("PLAYER"))
SetPedRelationshipGroupHash(targetPed, GetHashKey("HITMAN"))
SetPedCanSwitchWeapon(targetPed, true)

-- start mission timer
missionTimer = SetTimeout(Config.MissionDuration * 1000, function()
    exports['mythic_notify']:DoCustomHudText('inform', 'The hitman mission has expired.', 7500)
    CleanUpMission()
end)
end
-- clean up mission objects and variables
function CleanUpMission()
if hitmanPed ~= nil then
DeletePed(hitmanPed)
hitmanPed = nil
end
if targetBlip ~= nil then
RemoveBlip(targetBlip)
targetBlip = nil
end
if missionTimer ~= nil then
ClearTimeout(missionTimer)
missionTimer = nil
end
missionActive = false
end

-- handle hitman ped and target ped deaths
Citizen.CreateThread(function()
while true do
Citizen.Wait(0)
if missionActive then
if hitmanPed ~= nil and IsEntityDead(hitmanPed) then
exports['mythic_notify']:DoCustomHudText('inform', 'The hitman has been killed.', 7500)
CleanUpMission()
end
if targetPed ~= nil and IsEntityDead(targetPed) then
exports['mythic_notify']:DoCustomHudText('inform', 'The target has been killed. Retrieve the important papers.', 7500)
SetBlipColour(targetBlip, 2)
missionTimer = SetTimeout(Config.PapersTime, function()
exports['mythic_notify']:DoCustomHudText('inform', 'The important papers have disappeared. Mission failed.', 7500)
CleanUpMission()
end)
end
end
end
end)

-- handle retrieving the papers and completing the mission
Citizen.CreateThread(function()
while true do
Citizen.Wait(0)
if missionActive then
local hitmanPos = GetEntityCoords(hitmanPed)
local playerPed = GetPlayerPed(-1)
local playerPos = GetEntityCoords(playerPed)
local distance = #(hitmanPos - playerPos)
if distance < Config.RetrievePapersDistance then
DrawText3D(hitmanPos.x, hitmanPos.y, hitmanPos.z + 1.0, "Press gEw to retrieve important papers")
if IsControlJustPressed(0, 38) then -- E key
exports['mythic_notify']:DoCustomHudText('inform', 'The hitman mission is complete. Return the papers to the drop-off location.', 7500)
SetBlipColour(targetBlip, 3)
SetEntityAsMissionEntity(papersObject, true, true)
local dropoffBlip = AddBlipForCoord(Config.DropOffLocation.x, Config.DropOffLocation.y, Config.DropOffLocation.z)
SetBlipSprite(dropoffBlip, 85)
SetBlipColour(dropoffBlip, 5)
SetBlipAsShortRange(dropoffBlip, true)
while true do
Citizen.Wait(0)
local dropoffPos = vector3(Config.DropOffLocation.x, Config.DropOffLocation.y, Config.DropOffLocation.z)
local dropoffDistance = #(playerPos - dropoffPos)
if dropoffDistance < Config.DropOffDistance then
DrawText3D(dropoffPos.x, dropoffPos.y, dropoffPos.z + 1.0, "Press gEw to drop off the important papers")
if IsControlJustPressed(0, 38) then -- E key
exports['mythic_notify']:DoCustomHudText('inform', 'The hitman mission is complete. You have been paid for your services.', 7500)
CleanUpMission()
break
end
end
end
end
end
end
end
