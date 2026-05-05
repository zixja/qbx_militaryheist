# qbx_militaryheist WIP

QBox military base heist resource with staged guard waves, military vehicle reinforcements, loot crates, police alerts, cooldowns, and skippable next-round timers after waves are cleared.

## Dependencies

- qbx_core
- ox_lib
- ox_target
- ox_inventory

## Features

- Configurable start ped and heist requirements
- Required item and optional cash start cost
- Police alert blip for configured jobs
- Initial military response and reinforcement waves
- Guards can arrive in military vehicles
- Round timer can only be skipped after the active wave is cleared
- Server-authoritative heist state, cooldown, loot tracking, and wave progression
- Model load timeout and wave-clear timeout safeguards

## Installation

1. Place this folder in your server resources.
2. Add this to your server config:

```cfg
ensure qbx_militaryheist
```

3. Make sure the dependencies are started before this resource.
4. Configure rewards, guards, vehicles, police jobs, and loot zones in `config.lua`.

## Configuration

Important options live in `config.lua`:

- `Config.RequiredPolice`: minimum alert-job players required.
- `Config.CooldownMinutes`: cooldown between heist starts.
- `Config.HeistDurationMinutes`: maximum active heist time.
- `Config.RequiredItem`: item needed to start the heist.
- `Config.StartCost`: optional cash or account cost.
- `Config.AlertJobs`: jobs that receive police alerts and count toward required police.
- `Config.GuardVehicles`: vehicle reinforcement settings.
- `Config.Reinforcements`: wave count, delay, and round-clear timeout.
- `Config.RoundTimer`: skip command and timer UI settings.
- `Config.Rewards`: loot reward table.

## Gameplay Flow

1. Player starts the heist at the configured start ped.
2. Initial guards respond.
3. After the initial guard group is cleared, the next-round timer starts.
4. The timer can be skipped with `/skipmilround` or the target option while it is skippable.
5. Reinforcement waves arrive, then the process repeats until all waves are complete or the heist expires.

## Notes

- The player who starts the heist owns guard and vehicle spawning to avoid duplicate networked peds.
- If vehicle spawning fails, guards fall back to on-foot spawning.
- If a wave clear event is missed, the server advances after `Config.Reinforcements.roundClearTimeoutMinutes`.
