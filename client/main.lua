MilitaryHeist.Client = MilitaryHeist.Client or {}

MilitaryHeist.Client.Active = false
MilitaryHeist.Client.StartPed = nil
MilitaryHeist.Client.SkipRoundTimer = false
MilitaryHeist.Client.TimerRunning = false
MilitaryHeist.Client.TimerCanSkip = false
MilitaryHeist.Client.CurrentRound = 0
MilitaryHeist.Client.TimerToken = 0

local function isSpawnOwner(owner)
    return owner and GetPlayerServerId(PlayerId()) == owner
end

local function hideTimer()
    MilitaryHeist.Client.TimerToken = MilitaryHeist.Client.TimerToken + 1
    MilitaryHeist.Client.TimerRunning = false
    MilitaryHeist.Client.TimerCanSkip = false
    lib.hideTextUI()
end

local function requestSkipRoundTimer()
    if not MilitaryHeist.Client.Active then
        MilitaryHeist.Notify(nil, 'No active heist timer to skip.', 'error')
        return
    end

    if not MilitaryHeist.Client.TimerRunning then
        MilitaryHeist.Notify(nil, 'There is no round countdown running right now.', 'error')
        return
    end

    if not MilitaryHeist.Client.TimerCanSkip then
        MilitaryHeist.Notify(nil, 'You can only skip the wait after a round is cleared.', 'error')
        return
    end

    if not Config.RoundTimer.allowSkip then
        MilitaryHeist.Notify(nil, 'Skipping round timers is disabled.', 'error')
        return
    end

    TriggerServerEvent('qbx_militaryheist:server:skipRoundTimer')
end

local function startRoundCountdown(seconds, label, canSkip)
    MilitaryHeist.Client.TimerToken = MilitaryHeist.Client.TimerToken + 1
    local timerToken = MilitaryHeist.Client.TimerToken
    MilitaryHeist.Client.TimerRunning = true
    MilitaryHeist.Client.TimerCanSkip = canSkip == true

    CreateThread(function()
        local endsAt = GetGameTimer() + (seconds * 1000)

        while MilitaryHeist.Client.Active and MilitaryHeist.Client.TimerToken == timerToken do
            local remaining = math.ceil((endsAt - GetGameTimer()) / 1000)
            if remaining <= 0 then break end

            local skipText = ''

            if MilitaryHeist.Client.TimerCanSkip and Config.RoundTimer.allowSkip then
                skipText = ' | /' .. Config.RoundTimer.command .. ' to skip'
            end

            lib.showTextUI(label .. ' starts in: ' .. MilitaryHeist.FormatTime(remaining) .. skipText, {
                position = Config.RoundTimer.textPosition or 'top-center',
                icon = 'clock'
            })

            Wait(250)
        end

        if MilitaryHeist.Client.TimerToken == timerToken then
            hideTimer()
        end
    end)
end

local function createStartPed()
    if not MilitaryHeist.LoadModel(Config.StartPed.model) then return end

    local coords = Config.StartPed.coords

    local ped = CreatePed(
        0,
        Config.StartPed.model,
        coords.x,
        coords.y,
        coords.z - 1.0,
        coords.w,
        false,
        true
    )

    MilitaryHeist.Client.StartPed = ped

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if Config.StartPed.scenario then
        TaskStartScenarioInPlace(ped, Config.StartPed.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            label = 'Start Military Base Heist',
            icon = 'fa-solid fa-skull',
            distance = 2.0,
            canInteract = function()
                return not MilitaryHeist.Client.Active
            end,
            onSelect = function()
                TriggerServerEvent('qbx_militaryheist:server:attemptStart')
            end
        },
        {
            label = 'Skip Next Round Timer',
            icon = 'fa-solid fa-forward',
            distance = 2.0,
            canInteract = function()
                return MilitaryHeist.Client.Active
                    and MilitaryHeist.Client.TimerRunning
                    and MilitaryHeist.Client.TimerCanSkip
                    and Config.RoundTimer.allowSkip
            end,
            onSelect = function()
                requestSkipRoundTimer()
            end
        }
    })
end

RegisterCommand(Config.RoundTimer.command, function()
    requestSkipRoundTimer()
end, false)

RegisterNetEvent('qbx_militaryheist:client:startHeist', function(owner)
    if MilitaryHeist.Client.Active then return end

    MilitaryHeist.Client.Active = true
    MilitaryHeist.Client.CurrentRound = 0
    MilitaryHeist.Client.SkipRoundTimer = false
    MilitaryHeist.Client.TimerRunning = false
    MilitaryHeist.Client.TimerCanSkip = false

    MilitaryHeist.Client.ResetLoot()

    MilitaryHeist.Notify(nil, 'The heist has started. Military security is responding!', 'success')

    if isSpawnOwner(owner) then
        MilitaryHeist.Client.SpawnInitialGuards(0)
    end
end)

RegisterNetEvent('qbx_militaryheist:client:startRoundTimer', function(seconds, label, canSkip)
    if not MilitaryHeist.Client.Active then return end
    if not seconds or seconds <= 0 then return end

    startRoundCountdown(seconds, label or 'Reinforcement Round', canSkip)
end)

RegisterNetEvent('qbx_militaryheist:client:stopRoundTimer', function()
    hideTimer()
end)

RegisterNetEvent('qbx_militaryheist:client:skipRoundTimer', function()
    if not MilitaryHeist.Client.Active then return end
    if not MilitaryHeist.Client.TimerRunning then return end

    hideTimer()
    MilitaryHeist.Notify(nil, 'Round timer skipped.', 'success')
end)

RegisterNetEvent('qbx_militaryheist:client:spawnReinforcementWave', function(wave, totalWaves, owner)
    if not MilitaryHeist.Client.Active then return end

    MilitaryHeist.Client.CurrentRound = wave or 0

    MilitaryHeist.Notify(nil, 'Military reinforcements are arriving! Round ' .. wave .. '/' .. totalWaves, 'warning')

    if isSpawnOwner(owner) then
        MilitaryHeist.Client.SpawnReinforcementWave(wave)
    end
end)

RegisterNetEvent('qbx_militaryheist:client:endHeist', function()
    MilitaryHeist.Client.Active = false
    MilitaryHeist.Client.SkipRoundTimer = false
    MilitaryHeist.Client.TimerRunning = false
    MilitaryHeist.Client.TimerCanSkip = false
    MilitaryHeist.Client.CurrentRound = 0

    MilitaryHeist.Client.ResetLoot()
    MilitaryHeist.Client.ClearGuards()

    hideTimer()

    MilitaryHeist.Notify(nil, 'Military heist ended.', 'inform')
end)

RegisterNetEvent('qbx_militaryheist:client:policeAlert', function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 1.4)
    SetBlipColour(blip, 1)
    PulseBlip(blip)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Military Base Heist')
    EndTextCommandSetBlipName(blip)

    MilitaryHeist.Notify(nil, 'Military base alarm triggered!', 'warning')

    Wait(90000)

    if DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end)

CreateThread(function()
    createStartPed()
    MilitaryHeist.Client.CreateLootZones()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    hideTimer()
    MilitaryHeist.Client.ClearGuards()

    if MilitaryHeist.Client.StartPed and DoesEntityExist(MilitaryHeist.Client.StartPed) then
        DeleteEntity(MilitaryHeist.Client.StartPed)
    end
end)
