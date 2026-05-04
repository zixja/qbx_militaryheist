Config = {}

Config.Debug = false

Config.RequiredPolice = 0
Config.CooldownMinutes = 90
Config.HeistDurationMinutes = 25

Config.RequiredItem = 'thermite'
Config.RemoveRequiredItem = true

Config.StartCost = {
    enabled = true,
    account = 'cash',
    amount = 5000
}

Config.AlertJobs = {
    'police',
    'sheriff',
    'state'
}

Config.StartPed = {
    model = `s_m_m_highsec_01`,
    coords = vec4(-2347.43, 3268.83, 32.81, 236.63),
    scenario = 'WORLD_HUMAN_GUARD_STAND'
}

Config.Guards = {
    model = `s_m_y_marine_01`,
    weapon = `WEAPON_CARBINERIFLE`,
    armor = 100,
    health = 250,
    accuracy = 55
}

Config.GuardSpawns = {
    vec4(-2352.91, 3264.33, 32.81, 236.0),
    vec4(-2364.42, 3288.27, 32.81, 145.0),
    vec4(-2341.18, 3306.74, 32.81, 55.0),
    vec4(-2319.19, 3281.36, 32.81, 320.0),
    vec4(-2302.42, 3385.52, 31.20, 143.0),
    vec4(-2283.81, 3372.12, 31.21, 51.0),
    vec4(-2247.54, 3267.17, 32.81, 60.0),
    vec4(-2222.18, 3213.84, 32.81, 328.0)
}

Config.GuardVehicles = {
    enabled = true,
    model = `crusader`,
    guardsPerVehicle = 4,
    driveSpeed = 22.0,
    drivingStyle = 786603,
    arrivalDistance = 18.0,
    forceDismountAfter = 18000,
    dismountDelay = 1200,
    cleanupAfter = 120000,
    spawns = {
        vec4(-2268.42, 3195.84, 32.81, 328.0),
        vec4(-2402.15, 3296.78, 32.81, 145.0),
        vec4(-2293.37, 3408.41, 31.20, 143.0)
    }
}

Config.Reinforcements = {
    enabled = true,
    delayMinutes = 5,
    waves = 2,
    guardsPerWave = 4,
    timeBetweenWaves = 180000,
    roundClearTimeoutMinutes = 10
}

Config.RoundTimer = {
    enabled = true,
    allowSkip = true,
    command = 'skipmilround',
    textPosition = 'top-center'
}

Config.LootZones = {
    {
        name = 'military_crate_1',
        label = 'Search Military Crate',
        coords = vec3(-2357.62, 3254.65, 32.81),
        size = vec3(1.4, 1.4, 1.2),
        rotation = 0.0
    },
    {
        name = 'military_crate_2',
        label = 'Search Weapon Locker',
        coords = vec3(-2361.35, 3246.24, 32.81),
        size = vec3(1.4, 1.4, 1.2),
        rotation = 0.0
    },
    {
        name = 'military_crate_3',
        label = 'Search Armory Supplies',
        coords = vec3(-2327.78, 3268.72, 32.81),
        size = vec3(1.4, 1.4, 1.2),
        rotation = 0.0
    }
}

Config.Rewards = {
    minRewards = 2,
    maxRewards = 4,
    items = {
        { item = 'ammo-rifle', min = 2, max = 5, chance = 80 },
        { item = 'armor', min = 1, max = 2, chance = 65 },
        { item = 'weaponparts', min = 2, max = 6, chance = 70 },
        { item = 'radio', min = 1, max = 1, chance = 35 },
        { item = 'markedbills', min = 1, max = 3, chance = 45 }
    }
}
