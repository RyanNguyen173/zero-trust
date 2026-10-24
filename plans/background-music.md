# Plan: Phase-Based Soundtrack & Taskbar Audio Control

## 1. Goal + Studio Test
Implement the 3-phase dynamic soundtrack:
- **Lobby / Menu:** West Coast Bounce (`rbxassetid://115638035040625`)
- **Shift (Before & On the Clock):** Lowrider Bounce (`rbxassetid://81027425424909`)
- **Clock Off (5:00 PM Summary):** Late Night Smooth Jazz Synth (`rbxassetid://111281628096922`)
Includes audio ducking during phone calls and 1-click taskbar mute/unmute.
**Test**: Start game in Lobby (Track 2 plays). Teleport to Bakery workstation (crossfades to Track 3). Clock hits 5:00 PM (crossfades to smooth jazz synth). Taskbar speaker icon toggles mute.

## 2. Files to Create / Change
- `src/shared/Config.luau`:
  - `MUSIC_TRACKS = { Lobby = "rbxassetid://115638035040625", InShift = "rbxassetid://81027425424909", Summary = "rbxassetid://111281628096922" }`
  - `DEFAULT_MUSIC_VOLUME = 0.35`, `DUCKED_MUSIC_VOLUME = 0.10`.
- `src/client/Controllers/MusicController.luau` (new):
  - `transitionTo(phase: "Lobby" | "InShift" | "Summary")`: Fades out current track (1.0s), switches SoundId, fades in target track.
  - `duckAudio(isDucked: boolean)`: Smoothly tweens volume to 0.1 during active phone calls / dialogues.
  - `toggleMute()`: Inverts mute state, toggles taskbar icon between 🔊 and 🔇.
- `src/client/Controllers/DesktopUI.luau`:
  - Wire taskbar right-tray speaker button to `MusicController.toggleMute()`.
- `src/client/init.client.luau`:
  - Listens to `GameStateSync` and calls `MusicController.transitionTo(state.phase)`.

## 3. Remotes
- None required (client reacts to existing `GameStateSync.phase`).

## 4. Existing Code to Know
- `src/client/Controllers/DesktopUI.luau`: Lines 1340-1370 where taskbar speaker label is created.
- `src/server/Systems/TicketSystem.luau`: `broadcastState()` sends `phase: "Lobby" | "InShift" | "Summary" | "GameOver"`.

## 5. Out of Scope
- Custom in-game radio UI or playlist shuffle.
