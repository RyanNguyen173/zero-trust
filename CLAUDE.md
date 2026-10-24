# hackathon-game — Claude Code rules

8-hour Roblox hackathon. Rojo syncs `src/` -> Studio. Studio MCP (Roblox_Studio) is connected.

## Workflow (two agents)
- Antigravity (`agy`) is the PLANNER/LOOKER: explores Studio, writes `plans/<x>.md`, does visual checks.
- You are the BUILDER: implement plans, build in Workspace, playtest for errors.
- Given a plan: implement it and touch only what it names. Don't re-explore what the plan already tells you.
- No plan and the task needs broad exploration (more than a few searches)? Stop and suggest: "Ask agy to plan this" with a one-line prompt for it.
- End each task with one line: what changed + `Next:` (e.g. "ask agy to check plans/house.md visually", or "commit").

## Style reference
- `docs/reference.md` = how top Roblox games look and feel (HUD layout, UI sizing, rarity colours, feedback layers, lighting).
- Read only the section you need, and only for UI, game-feel, or map/lighting work. Don't load it for pure logic.

## Code
- ALL code goes in `src/`. Never edit scripts in Studio via MCP (`multi_edit`, `execute_luau`) — Rojo overwrites them.
- Server: `src/server/Systems/*.luau`; client: `src/client/Controllers/*.luau`; shared: `src/shared/`. Modules return a table with optional `init()` / `start()` (auto-loaded).
- `--!strict` everywhere. Server-authoritative; validate remote input. Modules <150 lines, one job each.
- After code changes: `stylua src` then `selene src`.

## Map / Workspace builds
- Rojo does not manage Workspace. Building/editing parts there via `execute_luau` is allowed — one snippet per build, grouped in a named Model.
- Remind me to save the place (Ctrl+S) after builds.

## Token rules (MCP)
- Read `src/` with file tools (grep first, read only needed lines) — not `script_read`.
- `search_game_tree`: one service, shallow, filtered by class/name. Skip Parts/Meshes unless the task is about the map.
- Many instances? One read-only `execute_luau` returning only needed fields — no repeated `inspect_instance`.
- Playtests: report only errors and warnings.
- No `screen_capture` — visual checks are agy's job unless I ask you.
