# Feature Plan: Fix Button Bounce & Window Control Shrinking
Decision: Fix Permanent Button Shrink Bug / Stable Original Size Tween

*Fixes permanent button shrinking bug in DesktopUI.luau.*

## 1. Goal & Testing
- **Goal:** Fix the `bounce()` animation in `DesktopUI.luau`. Currently, the restore tween evaluates `{ Size = button.Size }` *after* the button has already shrunk, causing buttons (especially 30x30 titlebar close/minimize/maximize buttons) to permanently lose 6px on every single click until they vanish.
- **Testing:** Play Solo in Studio.
  - Open RoMail or Directory.
  - Click the Maximize (`□`), Minimize (`_`), and Close (`✕`) buttons repeatedly (10+ times).
  - Verify buttons bounce crisply on click/down and **always return 100% to their exact original size** without shrinking.
  - Verify action buttons (`[Approve]`, `[Reject]`, `[Log Off]`) maintain their full size after repeated clicks.

## 2. Files to Create / Change
### `src/client/Controllers/DesktopUI.luau` (Edit)
- In `function bounce(button: GuiButton): ()` (lines 293–307):
  - Cache `local originalSize = button.Size` at creation time.
  - On `MouseButton1Down`: tween to `originalSize - UDim2.new(0, 4, 0, 4)` (0.08s Quad).
  - On `MouseButton1Up` and `MouseLeave`: tween strictly back to `{ Size = originalSize }` (0.12s Back/Quad).
  - Cancel any conflicting tween before starting a new one so fast-clicking cannot desync size.
  - For titlebar buttons (close, minimize, maximize): adjust shrink delta to subtle 2px (`originalSize - UDim2.new(0, 2, 0, 2)`) so small 30x30 buttons don't clip their vector glyphs.

## 3. Remotes
- None. Purely client-side UI animation fix.

## 4. Existing Code & Instances
- `src/client/Controllers/DesktopUI.luau` lines 293–307:
  ```luau
  -- CURRENT BUG:
  local shrink = TweenService:Create(button, ..., { Size = button.Size - UDim2.new(0, 6, 0, 6) })
  shrink.Completed:Connect(function()
      TweenService:Create(button, ..., { Size = button.Size }):Play() -- button.Size is already shrunken!
  end)
  ```

## 5. Out of Scope
- Redesigning button visual shapes.
