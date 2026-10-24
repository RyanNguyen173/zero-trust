# Feature Plan: Player Join Hello

## 1. Goal & Testing
- **Goal:** Print `Hello, <player name>` to the server output whenever a player joins the game.
- **Testing:** Start a Play Solo playtest in Studio. Verify in the Output window that `Hello, <PlayerName>` is printed once the player joins.

## 2. Files to Create / Change

### Create: `src/server/Systems/Hello.luau`
- Return table: `local Hello = {}`
- `--!strict` header.
- Local functions:
  - `local function onPlayerAdded(player: Player): ()`
    - Prints `string.format("Hello, %s", player.Name)` or `print("Hello, " .. player.Name)`.
- Module functions:
  - `function Hello.start(): ()`
    - Connects `Players.PlayerAdded:Connect(onPlayerAdded)`.
    - Handles existing players on start: `for _, player in Players:GetPlayers() do onPlayerAdded(player) end`.
  - Returns `Hello`.

## 3. Remotes
- **None.** This is a server-side only system with no client communication.

## 4. Existing Code & Instances
- `src/server/init.server.luau` (lines 5-26):
  Automatically discovers all `ModuleScript` children of `src/server/Systems/`, requires them, and calls `system.start()` via `task.spawn`.
- `game:GetService("Players")` Roblox service.

## 5. Out of Scope
- Client controllers or GUI display.
- Chat service messages or overhead billboard greetings.
- RemoteEvents or remote communication.
- Player leave / removing logic.
