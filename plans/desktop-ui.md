# Feature Plan: "BloxOS" Parody Desktop UI
Decision: Robloxified Windows Parody ("BloxOS") / RoMail / RoNotes

*Implements `docs/zero-trust.md` §3 & Roblox UI styling from `docs/reference.md`.*

## 1. Goal & Testing
- **Goal:** Parody Windows 11 as a playful, Roblox-themed corporate OS ("BloxOS"):
  1. *BloxOS Shell:* Deep navy/cyan cyber-stud wallpaper, left desktop icons with blocky badges (Blox Bin, RoMail, RoNotes, BloxBank), bottom BloxOS Taskbar with a 4-stud Blox Start button, active app bar, and shift clock tray (`09:00 AM`).
  2. *RoMail Client:* Parody Outlook window with chunky `UICorner` (8-10px), dark `UIStroke`, titlebar with blocky `_` `□` `✕` buttons. 3-column layout (Folders, Ticket List, Reading Pane with Roblox dummy avatar) + chunky action buttons (`[Approve]`, `[Escalate]`, `[Reject]`).
  3. *RoNotes (Sticky Note):* Yellow pinned memo with taped header displaying shift red flags.
  4. *Safety:* 100% original parody names/branding (zero trademarked Windows logos/assets).
- **Testing:** Play Solo in Studio.
  - Desktop renders with BloxOS parody wallpaper, desktop icons, and taskbar.
  - Clicking RoMail opens the mail client.
  - Clicking tickets updates the reading pane with Roblox avatars and email text.
  - Chunky action buttons have 0.1s bounce tweens on click.
  - RoNotes displays the active security guidelines.

## 2. Files to Create / Change
### `src/client/Controllers/DesktopUI.luau` (Create - replaces `TicketDebugUI.luau`)
- Module with `init()` and `start()`. Listens to `GameStateSync`.
- **Styling (`docs/reference.md`):**
  - Font: `Enum.Font.BuilderSansBold` or `Enum.Font.GothamBold`.
  - Buttons: `UICorner` (8px), `UIStroke` (1.5px, Color3 `#000000` with 0.5 transparency).
- **Components:**
  - `BloxWallpaper`: Stylized dark blue gradient with subtle studio stud watermark.
  - `DesktopIcons`: Left vertical column (Blox Bin, RoMail, RoNotes, BloxBank).
  - `Taskbar`: 44px bottom bar (`Color3.fromRGB(24, 28, 36)`). Blox Start button (slanted Roblox-style block logo), app icons, System Tray clock.
  - `RoMailWindow`: Centered frame (`Size: 0.85, 0.85`).
    - *Titlebar:* "RoMail - Local Business Inc.", blocky window buttons.
    - *Folder Pane (15%):* "Inbox", "Spam", "Archive".
    - *List Pane (35%):* Email preview cards with unread dot, sender, amount.
    - *Reading Pane (50%):* Dummy avatar, sender, subject, amount banner, body, and 3 chunky action buttons: Green `#2E7D32` Approve, Orange `#F57C00` Escalate, Red `#C62828` Reject.
  - `RoNotesWidget`: Yellow sticky note (`Color3.fromRGB(255, 247, 160)`) on top-right listing `guidelines`.

### `src/client/Controllers/TicketDebugUI.luau` (Delete or Disable)
- Retired in favor of `DesktopUI.luau`.

## 3. Remotes
- Reuses `GameStateSync`, `SubmitDecision`, `StartShift`, `NextDay`.

## 4. Existing Code & Instances
- `src/server/Systems/TicketSystem.luau`: provides `GameState` and handles decision remotes.
- `src/shared/Types.luau` & `src/shared/Config.luau`: shared types.

## 5. Out of Scope
- Animated desktop pet or minigames.
