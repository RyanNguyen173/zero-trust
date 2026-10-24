# Feature Plan: Desktop Shortcut Icons Refinement
Decision: Desktop Icon Styling / Transparent Frames / Asset IDs

*Implements authentic desktop shortcut appearance matching reference mockup.*

## 1. Goal & Testing
- **Goal:**
  1. Remove the heavy dark square button frames from desktop icons (set `BackgroundTransparency = 1`). In real desktops and the reference mockup, icons float directly on the wallpaper with transparent backgrounds (only subtle highlight on hover).
  2. Improve icon graphics: Replace basic blocky rectangles with clean `ImageLabel` assets (Roblox standard icon IDs or Lucide icons) or higher-fidelity compound vector graphics.
  3. Text labels: Centered below the icon with `TextStrokeTransparency = 0.4` for contrast against wallpaper.
- **Testing:** Play Solo in Studio. Desktop icons on the left look like genuine desktop shortcuts floating over the wallpaper without dark solid square backplates. Clicking RoMail toggles the mail window.

## 2. Files to Create / Change
### `src/client/Controllers/DesktopUI.luau` (Edit)
- In `buildDesktopIcons()`:
  - `iconButton.BackgroundTransparency = 1` (hover tween to `0.8` on `MouseEnter` / `MouseLeave`).
  - `addStroke(iconButton, ...)` removed from base shortcut button.
  - Caption: `TextStrokeTransparency = 0.5`, `TextStrokeColor3 = Color3.fromRGB(0, 0, 0)`, positioned directly below icon.
  - Use verified Roblox icon asset IDs (or clean SVGs/decals):
    - RoMail: `rbxassetid://10723415766` (or Lucide Mail `rbxassetid://3926305904` / `rbxassetid://6034287594`)
    - Blox Bin: `rbxassetid://10747373176` (or Lucide Trash)
    - RoNotes: `rbxassetid://10723407389` (or Lucide FileText)
    - BloxBank: `rbxassetid://10734950309` (or Lucide Landmark / Vault)

## 3. Remotes
- None. Purely client-side UI visual update.

## 4. Existing Code & Instances
- `src/client/Controllers/DesktopUI.luau` lines 594-635 (`buildDesktopIcons`).

## 5. Out of Scope
- Drag-and-drop icon rearrangement on the desktop grid.
