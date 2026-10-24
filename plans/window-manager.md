# Feature Plan: Windows-Style Window Manager & Dragging
Decision: Draggable Windows / Focus Layering / Fix Auto-Open / Taskbar Apps

*Implements authentic Windows OS window management for DesktopUI.luau.*

## 1. Goal & Testing
- **Goal:**
  1. **Fix Auto-Open:** Stop RoMail from forcibly re-opening every second or on new tickets. Only auto-open once when shift starts; respect user minimizing/closing it.
  2. **Draggable Windows:** Players can click & drag the titlebar of `RoMailWindow` and `DirectoryWindow` to move them freely around the screen.
  3. **Window Focus / Bring to Front:** Clicking on a window brings it in front of other open windows (dynamic Z-Index).
  4. **Taskbar App Buttons:** Pinned taskbar buttons for RoMail and Directory with active indicator lines; clicking toggles minimize / restore.
- **Testing:** Play Solo in Studio.
  - Close RoMail: it stays closed even when clock ticks or new tickets arrive.
  - Click & drag RoMail's titlebar: moves smoothly across desktop.
  - Open Directory: drag it beside RoMail. Click RoMail to bring it in front; click Directory to bring it in front.
  - Click taskbar buttons: cleanly minimizes or restores the respective window.

## 2. Files to Create / Change
### `src/client/Controllers/DesktopUI.luau` (Edit)
- **Fix Auto-Open:**
  - Add `hasAutoOpenedThisShift: boolean = false`. Reset to `false` when phase is `Lobby`.
  - In `render(state)`: only set `mailOpen = true` if `state.phase == "InShift" and not hasAutoOpenedThisShift`. Set `hasAutoOpenedThisShift = true`.
- **Add `makeDraggable(window: Frame, titlebar: Frame)`:**
  - Connects `titlebar.InputBegan` (MouseButton1/Touch) and `UserInputService.InputChanged` to track delta and update `window.Position`.
  - Applied to both `RoMailWindow` and `DirectoryWindow`.
- **Add Window Focus (`bringToFront(window: Frame)`):**
  - Track `topZIndex = 10`. When `window.InputBegan` fires, increment `topZIndex` and set `window.ZIndex = topZIndex`.
- **Add Taskbar App Launchers (`buildTaskbar`):**
  - Add taskbar app buttons for RoMail and Directory between Start button and Tray.
  - Include subtle blue accent underline when that app's window is open. Clicking toggles `window.Visible` and updates focus.

## 3. Remotes
- None. Purely client-side window management.

## 4. Existing Code & Instances
- `src/client/Controllers/DesktopUI.luau`:
  - Lines 1239-1242: buggy auto-reopen logic in `render(state)`.
  - Lines 630-660: `RoMailWindow` titlebar.
  - Lines 810-850: `DirectoryWindow` titlebar.
  - Lines 994-1026: `buildTaskbar`.

## 5. Out of Scope
- Window border edge resizing (keep fixed/maximized sizes for simplicity).
- Multi-monitor support or snapping animations.
