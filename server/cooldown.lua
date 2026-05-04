MilitaryHeist.Server = MilitaryHeist.Server or {}

MilitaryHeist.Server.LastHeist = 0

function MilitaryHeist.Server.IsOnCooldown()
    if MilitaryHeist.Server.LastHeist <= 0 then
        return false, 0
    end

    local cooldown = Config.CooldownMinutes * 60
    local elapsed = os.time() - MilitaryHeist.Server.LastHeist

    if elapsed >= cooldown then
        return false, 0
    end

    local remaining = math.ceil((cooldown - elapsed) / 60)

    return true, remaining
end

function MilitaryHeist.Server.SetCooldown()
    MilitaryHeist.Server.LastHeist = os.time()
end
