MilitaryHeist.Server = MilitaryHeist.Server or {}

MilitaryHeist.Server.Active = false
MilitaryHeist.Server.LootedCrates = {}
MilitaryHeist.Server.HeistId = 0
MilitaryHeist.Server.Owner = nil
MilitaryHeist.Server.CurrentWave = 0
MilitaryHeist.Server.RoundTimerActive = false
MilitaryHeist.Server.RoundTimerSkippable = false
MilitaryHeist.Server.TimerSkipUsed = false
MilitaryHeist.Server.WaitingForWaveClear = false
MilitaryHeist.Server.ClearedWaves = {}

local alertJobLookup = {}
local validCrates = {}

for _, jobName in pairs(Config.AlertJobs) do
    alertJobLookup[jobName] = true
end

for _, crate in pairs(Config.LootZones) do
    validCrates[crate.name] = true
end

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function getPlayers()
    return exports.qbx_core:GetQBPlayers()
end

local function hasItem(src, item)
    local count = exports.ox_inventory:Search(src, 'count', item)
    return count and count > 0
end

local function removeItem(src, item, amount)
    return exports.ox_inventory:RemoveItem(src, item, amount or 1)
end

local function isAlertJob(player)
    if not player or not player.PlayerData or not player.PlayerData.job then
        return false
    end

    local job = player.PlayerData.job

    return alertJobLookup[job.name] == true
end

local function getPoliceCount()
    local count = 0
    local players = getPlayers()

    for _, player in pairs(players) do
        local job = player.PlayerData.job

        if job and job.onduty and alertJobLookup[job.name] then
            count = count + 1
        end
    end

    return count
end

local function alertPolice()
    local players = getPlayers()
    local coords = Config.StartPed.coords

    for src, player in pairs(players) do
        if isAlertJob(player) then
            TriggerClientEvent('qbx_militaryheist:client:policeAlert', src, coords)
        end
    end
end

local function isValidCrate(crateName)
    return validCrates[crateName] == true
end

local function resetHeistState()
    MilitaryHeist.Server.Active = false
    MilitaryHeist.Server.LootedCrates = {}
    MilitaryHeist.Server.Owner = nil
    MilitaryHeist.Server.CurrentWave = 0
    MilitaryHeist.Server.RoundTimerActive = false
    MilitaryHeist.Server.RoundTimerSkippable = false
    MilitaryHeist.Server.TimerSkipUsed = false
    MilitaryHeist.Server.WaitingForWaveClear = false
    MilitaryHeist.Server.ClearedWaves = {}
end

local function endHeist(heistId)
    if heistId and heistId ~= MilitaryHeist.Server.HeistId then return end
    if not MilitaryHeist.Server.Active then return end

    resetHeistState()
    TriggerClientEvent('qbx_militaryheist:client:endHeist', -1)
end

local function startRoundTimer(seconds, label, canSkip)
    MilitaryHeist.Server.RoundTimerActive = seconds > 0
    MilitaryHeist.Server.RoundTimerSkippable = canSkip == true
    MilitaryHeist.Server.TimerSkipUsed = false

    if MilitaryHeist.Server.RoundTimerActive then
        TriggerClientEvent('qbx_militaryheist:client:startRoundTimer', -1, seconds, label, MilitaryHeist.Server.RoundTimerSkippable)
    else
        TriggerClientEvent('qbx_militaryheist:client:stopRoundTimer', -1)
    end
end

local function waitForRoundTimer(seconds, heistId, label, canSkip)
    if seconds <= 0 then return true end

    if Config.RoundTimer.enabled then
        startRoundTimer(seconds, label, canSkip)

        local endsAt = os.time() + seconds

        while MilitaryHeist.Server.Active
            and MilitaryHeist.Server.HeistId == heistId
            and MilitaryHeist.Server.RoundTimerActive
            and os.time() < endsAt do
            Wait(250)
        end

        if not MilitaryHeist.Server.Active or MilitaryHeist.Server.HeistId ~= heistId then
            return false
        end

        MilitaryHeist.Server.RoundTimerActive = false
        MilitaryHeist.Server.RoundTimerSkippable = false
        TriggerClientEvent('qbx_militaryheist:client:stopRoundTimer', -1)
        return true
    end

    Wait(seconds * 1000)
    return MilitaryHeist.Server.Active and MilitaryHeist.Server.HeistId == heistId
end

local function waitForWaveClear(heistId, wave)
    MilitaryHeist.Server.WaitingForWaveClear = true
    local timeoutSeconds = (Config.Reinforcements.roundClearTimeoutMinutes or 10) * 60
    local timeoutAt = os.time() + timeoutSeconds

    while MilitaryHeist.Server.Active
        and MilitaryHeist.Server.HeistId == heistId
        and MilitaryHeist.Server.WaitingForWaveClear
        and not MilitaryHeist.Server.ClearedWaves[wave]
        and os.time() < timeoutAt do
        Wait(500)
    end

    if not MilitaryHeist.Server.ClearedWaves[wave]
        and MilitaryHeist.Server.Active
        and MilitaryHeist.Server.HeistId == heistId then
        MilitaryHeist.Server.ClearedWaves[wave] = true
    end

    MilitaryHeist.Server.WaitingForWaveClear = false

    return MilitaryHeist.Server.Active and MilitaryHeist.Server.HeistId == heistId
end

local function runReinforcementSchedule(heistId)
    if not Config.Reinforcements.enabled then return end

    local firstDelay = Config.Reinforcements.delayMinutes * 60

    if not waitForWaveClear(heistId, 0) then
        return
    end

    if not waitForRoundTimer(firstDelay, heistId, 'Reinforcement Round 1', true) then
        return
    end

    for wave = 1, Config.Reinforcements.waves do
        if not MilitaryHeist.Server.Active or MilitaryHeist.Server.HeistId ~= heistId then
            return
        end

        MilitaryHeist.Server.CurrentWave = wave
        TriggerClientEvent('qbx_militaryheist:client:spawnReinforcementWave', -1, wave, Config.Reinforcements.waves, MilitaryHeist.Server.Owner)

        if wave < Config.Reinforcements.waves then
            if not waitForWaveClear(heistId, wave) then
                return
            end

            local nextRound = wave + 1
            local waitSeconds = math.floor(Config.Reinforcements.timeBetweenWaves / 1000)

            if not waitForRoundTimer(waitSeconds, heistId, 'Reinforcement Round ' .. nextRound, true) then
                return
            end
        end
    end

    MilitaryHeist.Server.RoundTimerActive = false
    MilitaryHeist.Server.RoundTimerSkippable = false
    TriggerClientEvent('qbx_militaryheist:client:stopRoundTimer', -1)
end

RegisterNetEvent('qbx_militaryheist:server:attemptStart', function()
    local src = source
    local player = getPlayer(src)

    if not player then return end

    if MilitaryHeist.Server.Active then
        MilitaryHeist.Notify(src, 'A military heist is already active.', 'error')
        return
    end

    local onCooldown, remaining = MilitaryHeist.Server.IsOnCooldown()

    if onCooldown then
        MilitaryHeist.Notify(src, 'Military security is still on high alert. Try again in ' .. remaining .. ' minutes.', 'error')
        return
    end

    if getPoliceCount() < Config.RequiredPolice then
        MilitaryHeist.Notify(src, 'Not enough law enforcement online.', 'error')
        return
    end

    if Config.RequiredItem and not hasItem(src, Config.RequiredItem) then
        MilitaryHeist.Notify(src, 'You need ' .. Config.RequiredItem .. ' to start this heist.', 'error')
        return
    end

    if Config.StartCost.enabled then
        local money = player.PlayerData.money[Config.StartCost.account] or 0

        if money < Config.StartCost.amount then
            MilitaryHeist.Notify(src, 'You need $' .. Config.StartCost.amount .. ' ' .. Config.StartCost.account .. '.', 'error')
            return
        end

        if not player.Functions.RemoveMoney(Config.StartCost.account, Config.StartCost.amount, 'military-heist-start') then
            MilitaryHeist.Notify(src, 'Unable to collect the start payment.', 'error')
            return
        end
    end

    if Config.RequiredItem and Config.RemoveRequiredItem then
        if not removeItem(src, Config.RequiredItem, 1) then
            MilitaryHeist.Notify(src, 'Unable to use the required item.', 'error')
            return
        end
    end

    MilitaryHeist.Server.HeistId = MilitaryHeist.Server.HeistId + 1
    local heistId = MilitaryHeist.Server.HeistId

    MilitaryHeist.Server.Active = true
    MilitaryHeist.Server.LootedCrates = {}
    MilitaryHeist.Server.Owner = src
    MilitaryHeist.Server.CurrentWave = 0
    MilitaryHeist.Server.RoundTimerActive = false
    MilitaryHeist.Server.RoundTimerSkippable = false
    MilitaryHeist.Server.TimerSkipUsed = false
    MilitaryHeist.Server.WaitingForWaveClear = false
    MilitaryHeist.Server.ClearedWaves = {}
    MilitaryHeist.Server.SetCooldown()

    alertPolice()

    TriggerClientEvent('qbx_militaryheist:client:startHeist', -1, src)

    CreateThread(function()
        runReinforcementSchedule(heistId)
    end)

    SetTimeout(Config.HeistDurationMinutes * 60000, function()
        endHeist(heistId)
    end)
end)

RegisterNetEvent('qbx_militaryheist:server:skipRoundTimer', function()
    local src = source

    if not MilitaryHeist.Server.Active then
        MilitaryHeist.Notify(src, 'No active heist timer to skip.', 'error')
        return
    end

    if not Config.RoundTimer.allowSkip then
        MilitaryHeist.Notify(src, 'Skipping round timers is disabled.', 'error')
        return
    end

    if not MilitaryHeist.Server.RoundTimerActive then
        MilitaryHeist.Notify(src, 'There is no round countdown running right now.', 'error')
        return
    end

    if not MilitaryHeist.Server.RoundTimerSkippable then
        MilitaryHeist.Notify(src, 'You can only skip the wait after a round is cleared.', 'error')
        return
    end

    if MilitaryHeist.Server.TimerSkipUsed then
        MilitaryHeist.Notify(src, 'This wait has already been skipped.', 'error')
        return
    end

    MilitaryHeist.Server.TimerSkipUsed = true
    MilitaryHeist.Server.RoundTimerActive = false
    MilitaryHeist.Server.RoundTimerSkippable = false

    TriggerClientEvent('qbx_militaryheist:client:skipRoundTimer', -1)
end)

RegisterNetEvent('qbx_militaryheist:server:waveCleared', function(wave)
    local src = source

    if not MilitaryHeist.Server.Active then return end
    if src ~= MilitaryHeist.Server.Owner then return end
    if wave ~= MilitaryHeist.Server.CurrentWave then return end

    MilitaryHeist.Server.ClearedWaves[wave] = true
    MilitaryHeist.Server.WaitingForWaveClear = false
end)

AddEventHandler('playerDropped', function()
    local src = source

    if MilitaryHeist.Server.Active and MilitaryHeist.Server.Owner == src then
        endHeist(MilitaryHeist.Server.HeistId)
    end
end)

RegisterNetEvent('qbx_militaryheist:server:lootCrate', function(crateName)
    local src = source

    if not MilitaryHeist.Server.Active then
        MilitaryHeist.Notify(src, 'The heist is not active.', 'error')
        return
    end

    if not crateName or not isValidCrate(crateName) then
        DropPlayer(src, 'Invalid military heist crate.')
        return
    end

    if MilitaryHeist.Server.LootedCrates[crateName] then
        MilitaryHeist.Notify(src, 'This crate has already been searched.', 'error')
        return
    end

    MilitaryHeist.Server.LootedCrates[crateName] = true

    MilitaryHeist.Server.GiveRewards(src)

    MilitaryHeist.Notify(src, 'You found military supplies.', 'success')
end)
