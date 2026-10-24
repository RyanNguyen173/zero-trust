# hackathon-game — Claude Code rules

8-hour Roblox hackathon. Rojo syncs `src/` -> Studio. Studio MCP (Roblox_Studio) is connected.

## Code
- ALL code changes go in `src/` files. Never edit scripts in Studio via MCP (`multi_edit`, `execute_luau`) — Rojo overwrites them.
- Server systems: `src/server/Systems/*.luau`; client controllers: `src/client/Controllers/*.luau`; shared: `src/shared/`. Each module returns a table with optional `init()` / `start()` (auto-loaded).
- Every file starts with `--!strict`. Server is authoritative; validate all remote input.
- Keep modules small (<150 lines), one job each.
- After changes: `stylua src` then `selene src`.

## Plans
- When given `plans/<x>.md`, implement it and touch only the files it names. Don't explore beyond them unless blocked.

## Token rules (MCP)
- Read code from `src/` with file tools (grep first, then read only needed lines) — not `script_read`.
- `search_game_tree`: target one service, shallow depth, filter by class/name. Ignore Parts/Meshes/Attachments unless the task is about the map.
- Properties of many instances? One `execute_luau` snippet (read-only) returning only needed fields — no repeated `inspect_instance`.
- Playtests (`start_stop_play` + `get_console_output`): report only errors and warnings.
- No `screen_capture` unless I ask.
- Broad Studio exploration: use `subagent` and ask for a summary under 200 words.