MilitaryHeist.Client = MilitaryHeist.Client or {}

MilitaryHeist.Client.LootedZones = {}

function MilitaryHeist.Client.ResetLoot()
    MilitaryHeist.Client.LootedZones = {}
end

function MilitaryHeist.Client.CreateLootZones()
    for _, zone in pairs(Config.LootZones) do
        exports.ox_target:addBoxZone({
            coords = zone.coords,
            size = zone.size,
            rotation = zone.rotation,
            debug = Config.Debug,
            options = {
                {
                    label = zone.label,
                    icon = 'fa-solid fa-box-open',
                    distance = 2.0,
                    canInteract = function()
                        return MilitaryHeist.Client.Active and not MilitaryHeist.Client.LootedZones[zone.name]
                    end,
                    onSelect = function()
                        if MilitaryHeist.Client.LootedZones[zone.name] then return end

                        local success = lib.progressCircle({
                            duration = 8000,
                            label = 'Searching military supplies...',
                            position = 'bottom',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                move = true,
                                car = true,
                                combat = true
                            },
                            anim = {
                                dict = 'amb@prop_human_bum_bin@base',
                                clip = 'base'
                            }
                        })

                        if not success then
                            MilitaryHeist.Notify(nil, 'Search cancelled.', 'error')
                            return
                        end

                        MilitaryHeist.Client.LootedZones[zone.name] = true
                        TriggerServerEvent('qbx_militaryheist:server:lootCrate', zone.name)
                    end
                }
            }
        })
    end
end
