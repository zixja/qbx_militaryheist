MilitaryHeist.Client = MilitaryHeist.Client or {}

MilitaryHeist.Client.Guards = {}
MilitaryHeist.Client.GuardVehicles = {}

local function hasVehicleSpawns()
    return Config.GuardVehicles
        and Config.GuardVehicles.enabled
        and Config.GuardVehicles.spawns
        and #Config.GuardVehicles.spawns > 0
end

local function setupGuard(ped, targetPed, attackNow)
    SetPedArmour(ped, Config.Guards.armor)
    SetEntityHealth(ped, Config.Guards.health)
    GiveWeaponToPed(ped, Config.Guards.weapon, 250, false, true)
    SetPedAccuracy(ped, Config.Guards.accuracy)

    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAbility(ped, 2)
    SetPedCombatRange(ped, 2)
    SetPedCombatMovement(ped, 2)
    SetPedSeeingRange(ped, 100.0)
    SetPedHearingRange(ped, 100.0)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if attackNow then
        TaskCombatPed(ped, targetPed or PlayerPedId(), 0, 16)
    end
end

function MilitaryHeist.Client.SpawnGuard(coords, targetPed, attackNow)
    local ped = CreatePed(
        30,
        Config.Guards.model,
        coords.x,
        coords.y,
        coords.z,
        coords.w,
        true,
        true
    )

    if not DoesEntityExist(ped) then return end

    setupGuard(ped, targetPed, attackNow ~= false)

    MilitaryHeist.Client.Guards[#MilitaryHeist.Client.Guards + 1] = ped
    return ped
end

local function monitorWaveClear(wave, guards)
    CreateThread(function()
        Wait(3000)

        while MilitaryHeist.Client.Active and MilitaryHeist.Client.CurrentRound == wave do
            local alive = 0

            for _, ped in pairs(guards) do
                if DoesEntityExist(ped) and not IsEntityDead(ped) then
                    alive = alive + 1
                end
            end

            if alive <= 0 then
                TriggerServerEvent('qbx_militaryheist:server:waveCleared', wave)
                return
            end

            Wait(1500)
        end
    end)
end

local function getRandomSpawn(spawns)
    return spawns[math.random(1, #spawns)]
end

local function spawnVehicleReinforcements(targetPed, guardCount)
    if not hasVehicleSpawns() then return nil end
    if not MilitaryHeist.LoadModel(Config.GuardVehicles.model) then return nil end

    local spawnedGuards = {}
    local remaining = guardCount or Config.Reinforcements.guardsPerWave

    while remaining > 0 do
        local vehicleSpawn = getRandomSpawn(Config.GuardVehicles.spawns)
        local destination = getRandomSpawn(Config.GuardSpawns)
        local vehicle = CreateVehicle(
            Config.GuardVehicles.model,
            vehicleSpawn.x,
            vehicleSpawn.y,
            vehicleSpawn.z,
            vehicleSpawn.w,
            true,
            true
        )

        if DoesEntityExist(vehicle) then
            SetVehicleOnGroundProperly(vehicle)
            SetVehicleEngineOn(vehicle, true, true, false)
            SetVehicleDoorsLocked(vehicle, 1)
            MilitaryHeist.Client.GuardVehicles[#MilitaryHeist.Client.GuardVehicles + 1] = vehicle
        end

        local vehicleGuards = {}
        local seats = Config.GuardVehicles.guardsPerVehicle or 4
        local groupSize = math.min(remaining, seats)

        for i = 1, groupSize do
            local ped = MilitaryHeist.Client.SpawnGuard(vehicleSpawn, targetPed, false)

            if ped then
                local seat = i == 1 and -1 or i - 2

                if DoesEntityExist(vehicle) then
                    SetPedIntoVehicle(ped, vehicle, seat)
                end

                vehicleGuards[#vehicleGuards + 1] = ped
                spawnedGuards[#spawnedGuards + 1] = ped
            end
        end

        if DoesEntityExist(vehicle) and vehicleGuards[1] then
            SetDriverAbility(vehicleGuards[1], 1.0)
            SetDriverAggressiveness(vehicleGuards[1], 0.6)
            SetPedKeepTask(vehicleGuards[1], true)

            TaskVehicleDriveToCoordLongrange(
                vehicleGuards[1],
                vehicle,
                destination.x,
                destination.y,
                destination.z,
                Config.GuardVehicles.driveSpeed or 22.0,
                Config.GuardVehicles.drivingStyle or 786603,
                Config.GuardVehicles.arrivalDistance or 18.0
            )

            CreateThread(function()
                local startedAt = GetGameTimer()
                local timeout = Config.GuardVehicles.forceDismountAfter or 18000
                local lastCoords = GetEntityCoords(vehicle)
                local lastMovedAt = startedAt

                while MilitaryHeist.Client.Active and DoesEntityExist(vehicle) do
                    local vehicleCoords = GetEntityCoords(vehicle)
                    local distance = #(vehicleCoords - vec3(destination.x, destination.y, destination.z))

                    if distance <= (Config.GuardVehicles.arrivalDistance or 18.0)
                        or GetGameTimer() - startedAt > timeout then
                        break
                    end

                    if #(vehicleCoords - lastCoords) > 3.0 then
                        lastCoords = vehicleCoords
                        lastMovedAt = GetGameTimer()
                    elseif GetGameTimer() - lastMovedAt > 6000 then
                        break
                    end

                    Wait(500)
                end

                if DoesEntityExist(vehicle) then
                    BringVehicleToHalt(vehicle, 4.0, 1000, false)
                end

                for _, ped in pairs(vehicleGuards) do
                    if DoesEntityExist(ped) and not IsEntityDead(ped) then
                        TaskLeaveVehicle(ped, vehicle, 256)
                    end
                end

                Wait(Config.GuardVehicles.dismountDelay or 1200)

                for _, ped in pairs(vehicleGuards) do
                    if DoesEntityExist(ped) and not IsEntityDead(ped) then
                        TaskCombatPed(ped, targetPed, 0, 16)
                    end
                end

                SetTimeout(Config.GuardVehicles.cleanupAfter or 120000, function()
                    if DoesEntityExist(vehicle) then
                        DeleteEntity(vehicle)
                    end
                end)
            end)
        else
            for _, ped in pairs(vehicleGuards) do
                if DoesEntityExist(ped) and not IsEntityDead(ped) then
                    TaskCombatPed(ped, targetPed, 0, 16)
                end
            end
        end

        remaining = remaining - groupSize
    end

    return spawnedGuards
end

function MilitaryHeist.Client.SpawnInitialGuards(wave)
    if not MilitaryHeist.LoadModel(Config.Guards.model) then return end

    local targetPed = PlayerPedId()
    local spawnedGuards = {}

    if hasVehicleSpawns() then
        spawnedGuards = spawnVehicleReinforcements(targetPed, #Config.GuardSpawns)
        if spawnedGuards and wave ~= nil then
            monitorWaveClear(wave, spawnedGuards)
        end
        if spawnedGuards then return end
    end

    for _, coords in pairs(Config.GuardSpawns) do
        spawnedGuards[#spawnedGuards + 1] = MilitaryHeist.Client.SpawnGuard(coords, targetPed)
    end

    if wave ~= nil then
        monitorWaveClear(wave, spawnedGuards)
    end
end

function MilitaryHeist.Client.SpawnReinforcementWave(wave)
    if not MilitaryHeist.LoadModel(Config.Guards.model) then return end

    local targetPed = PlayerPedId()
    local spawnedGuards = {}

    if hasVehicleSpawns() then
        spawnedGuards = spawnVehicleReinforcements(targetPed, Config.Reinforcements.guardsPerWave)
    end

    if not spawnedGuards then
        spawnedGuards = {}

        for i = 1, Config.Reinforcements.guardsPerWave do
            local coords = Config.GuardSpawns[math.random(1, #Config.GuardSpawns)]
            spawnedGuards[#spawnedGuards + 1] = MilitaryHeist.Client.SpawnGuard(coords, targetPed)
        end
    end

    if wave then
        monitorWaveClear(wave, spawnedGuards)
    end
end

function MilitaryHeist.Client.ClearGuards()
    for _, vehicle in pairs(MilitaryHeist.Client.GuardVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end

    for _, ped in pairs(MilitaryHeist.Client.Guards) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end

    MilitaryHeist.Client.Guards = {}
    MilitaryHeist.Client.GuardVehicles = {}
end
