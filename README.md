# hackathon-game

Roblox game built with [Rojo](https://rojo.space).

## Development

1. Install the toolchain: `rokit install`
2. Install packages (only once you add some to `wally.toml`): `wally install`
3. Start syncing: `rojo serve`
4. In Roblox Studio, connect with the Rojo plugin.

## Structure

- `src/shared` → ReplicatedStorage/Shared — types, config, pure utilities
- `src/server` → ServerScriptService/Server — authoritative game systems (`Systems/`)
- `src/client` → StarterPlayerScripts/Client — rendering, input, UI (`Controllers/`)

Each system/controller is a ModuleScript returning a table with optional
`init()` and `start()` functions; the entry scripts load them automatically.

## Checks

- Format: `stylua src`
- Lint: `selene src`
