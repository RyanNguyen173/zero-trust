# Plan: Fix Loading Screen Freeze & Script Conflicts

## 1. Goal + Studio Test
Unfreeze the game on start. Currently, the screen is permanently stuck on `ZERO TRUST - Preparing the city...` with player controls disabled due to legacy Studio scripts crashing.
**Test**: Start Playtest. Player spawns smoothly inside BakeryLevel with free movement and controls enabled; no stuck loading cover; BloxOS desktop opens when interacting with IT workstation.

## 2. Issues Diagnosed
1. **`ReplicatedFirst.LoadingMenu`**: Fullscreen LocalScript that sets `controls:Disable()` and waits for `ReplicatedStorage.SessionRemotes`.
2. **`Workspace.SessionSystem.SessionServer`**: Crashes on `SessionService:222` attempting to require missing `ServerScriptService.Server.Systems.AdminSystem`. Because it crashes, `SessionRemotes` is never created.
3. **`Workspace.PhoneLinkSystem.PhoneLinkServer`**: Crashes on `DecisionRewards:26` attempting to index `TicketSystem.Decision:Connect(...)` which doesn't exist on `TicketSystem`.
4. **`ReplicatedStorage.PhoneLinkRemotes`**: Client yields infinitely waiting for this missing remote folder.

## 3. Required Fixes (Build Steps)
1. **Disable or Remove Broken Legacy Wrappers in Studio**:
   - Delete or disable `ReplicatedFirst.LoadingMenu` (or guard it so it only runs if `SessionRemotes` exists).
   - Disable `Workspace.SessionSystem` and `Workspace.PhoneLinkSystem` (these are legacy scripts relying on deprecated backup systems in `ServerStorage`).
2. **Ensure Clean Rojo Spawn**:
   - Verify `workspace:SetAttribute("HelpDeskActiveStage", "BakeryLevel")`.
   - Ensure player spawns at `Workspace.BakeryLevel.Arrival.Spawn` with full movement and camera controls enabled.
3. **Connect Decision Signal in `TicketSystem.luau`**:
   - Add `TicketSystem.Decision = Instance.new("BindableEvent").Event` to prevent external script crashes.

## 4. Remotes
- Keep existing Rojo remotes in `ReplicatedStorage.Remotes` (`GameStateSync`, `SubmitDecision`, `StartShift`, `NextDay`).

## 5. Out of Scope
- Rewriting the legacy city car transit system.
