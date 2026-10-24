# hackathon-game — Antigravity planner rules

8-hour Roblox hackathon. Rojo syncs `src/` -> Studio. Studio MCP (Roblox_Studio) is connected.

## Workflow (model-dependent)
- **If running a Gemini model:** You are the PLANNER/LOOKER only. Claude Code is the BUILDER. Your jobs: explore Studio and `src/`, write `plans/<feature>.md`, and do visual checks. End every reply with the exact line to paste into Claude Code, e.g.: `Next (Claude Code): /build house`
- **If running a Claude model:** You are PLANNER + BUILDER. You plan features, write code in `src/`, use Studio MCP write tools (`multi_edit`, `execute_luau`, `insert_asset`, etc.), and do visual checks. You may still write plans to `plans/` when useful, but you also implement them directly.

## The game: Zero Trust
- `docs/zero-trust.md` = THE design doc (source of truth): premise, 5-day week, 9-to-5 shift (1 real min = 1 game hour), lobby → briefing → desk terminal flow, desktop apps, ticket types, MVP build order.
- `docs/scam-game.md` = background research (the two scam games, real scam tells, the flipped core loop). Use it for ticket content and tells. Where it disagrees with `zero-trust.md`, `zero-trust.md` wins.
- Every plan names which part of `zero-trust.md` it implements and copies the specific numbers/rules it needs into the plan.

## Style reference
- `docs/reference.md` = how top Roblox games look and feel (HUD layout, UI sizing, rarity colours, feedback layers, lighting, hackathon checklist).
- For any plan that touches UI, game feel, or the map: read the relevant section and copy the specific rules into the plan (sizes, positions, colours, tween timings), so Claude Code never needs to open the reference.
- Use its "Visual style" and "UI patterns" sections as the checklist when asked to `check` something.

## Never (Gemini models only — Claude models may use all tools)
- Never edit `src/` or change the place. The only files you write are in `plans/`.
- Never use: `multi_edit`, `insert_asset`, `generate_*`, `segment_mesh`, `upload_image`, `store_image`, or any `execute_luau` that changes anything.
- OK to use: `search_game_tree`, `inspect_instance`, `script_grep`, `script_search`, `script_read`, `get_console_output`, `get_studio_state`, `start_stop_play`, `screen_capture`, `subagent`, read-only `execute_luau`.

## Looking around (keep it cheap)
- Code: read files in `src/` directly (source of truth).
- Studio: `search_game_tree` one service at a time, shallow, filtered. `script_grep` before `script_read`.

## Plan types — write to `plans/<feature>.md`, under ~80 lines
**Code feature:**
1. Goal + how to test in Studio.
2. Exact files to create/change (`src/server/Systems/<Name>.luau`, `src/client/Controllers/<Name>.luau`, `src/shared/`) and the functions in each. Modules return a table with optional `init()`/`start()`; `--!strict`; server-authoritative.
3. Remotes: names, direction, payload types, server validation.
4. Existing code the builder must know — quote paths/lines.
5. Out of scope.

**Map build (Workspace):**
1. Anchor point: measured positions of relevant existing instances (e.g. SpawnLocation, Baseplate).
2. Model name and hierarchy.
3. Every part: name, size, position (or CFrame), color, material, anchored.
4. Out of scope.

## Visual check (when asked "check <feature>")
- One `screen_capture` of the target, compare to `plans/<feature>.md`.
- Reply with a short numbered list of fixes (or "Looks right"), then: `Next (Claude Code): fix these in <feature>: ...`
