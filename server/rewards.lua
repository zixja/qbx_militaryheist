MilitaryHeist.Server = MilitaryHeist.Server or {}

function MilitaryHeist.Server.GiveRewards(src)
    local given = 0
    local rewardAmount = math.random(Config.Rewards.minRewards, Config.Rewards.maxRewards)
    local safety = 0

    while given < rewardAmount and safety < 100 do
        safety = safety + 1

        local reward = Config.Rewards.items[math.random(1, #Config.Rewards.items)]
        local roll = math.random(1, 100)

        if roll <= reward.chance then
            local amount = math.random(reward.min, reward.max)
            exports.ox_inventory:AddItem(src, reward.item, amount)
            given = given + 1
        end
    end
end
