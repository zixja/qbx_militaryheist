MilitaryHeist = MilitaryHeist or {}

function MilitaryHeist.DebugPrint(...)
    if not Config.Debug then return end
    print('^3[qbx_militaryheist]^7', ...)
end

function MilitaryHeist.Notify(src, msg, notifyType)
    if IsDuplicityVersion() then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Military Heist',
            description = msg,
            type = notifyType or 'inform'
        })
    else
        lib.notify({
            title = 'Military Heist',
            description = msg,
            type = notifyType or 'inform'
        })
    end
end

function MilitaryHeist.LoadModel(model)
    if not IsModelInCdimage(model) then
        MilitaryHeist.DebugPrint('Invalid model requested:', model)
        return false
    end

    RequestModel(model)

    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(model) do
        if GetGameTimer() > timeout then
            MilitaryHeist.DebugPrint('Timed out loading model:', model)
            return false
        end

        Wait(10)
    end

    return true
end

function MilitaryHeist.FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format('%02d:%02d', minutes, secs)
end
