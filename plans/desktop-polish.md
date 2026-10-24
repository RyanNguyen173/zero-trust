# Feature Plan: BloxOS Desktop Visual Polish
Decision: Match Reference Mockup / Vector-Only (No ImageLabel Assets)

*Refines `DesktopUI.luau` visuals toward the user-supplied reference mockup. Follow-up to `plans/desktop-ui.md`, `plans/desktop-icons.md`.*

## 0. Constraint (read first)
External `rbxassetid://` image references (both the original plan's IDs and freshly-verified
Creator Store IDs) fail to load in this place with "Asset type does not match requested type" --
same error class as a pre-existing unrelated asset failure already in the game. Build everything
in this plan with plain Roblox UI primitives (`Frame`, `UICorner`, `UIGradient`, `UIStroke`,
`TextLabel`) -- no `ImageLabel`/`Decal`/`rbxassetid://` image references.

## 1. Goal & Testing
- **Goal:** Bring `DesktopUI.luau`'s visuals closer to the reference mockup:
  1. Wallpaper: add a tiled grid of large, low-opacity circular "studs" over the existing navy/cyan gradient.
  2. Desktop icons: refine the existing procedural trash/envelope/notepad/safe icons with more shading/detail (extra highlight layer, rounder proportions) to read more like the mockup's flat-design icons.
  3. RoMailWindow titlebar: replace the plain `_` / `\xE2\x96\xA1` / `X` glyphs with simple vector glyphs (a short dash bar, a small expand-corners bracket shape, an X made of two crossed bars) sized to match the button's accent colors already in place (yellow/gray/red).
  4. Reading pane avatar: extend `buildDummyFace` with a small rectangular "shirt collar" strip below the face, closer to a classic Roblox blocky avatar silhouette.
  5. Ticket list cards: wrap each card's amount label in a small orange rounded-pill background (`Color3.fromRGB(245, 160, 40)`-ish) instead of plain text.
  6. Taskbar: add two small decorative tray icons (speaker, wifi) left of the clock, built the same vector way as the desktop icons (simple shapes, no assets).
- **Testing:** Play Solo in Studio.
  - Desktop wallpaper shows visible circular stud pattern over the gradient.
  - Desktop icons show added shading detail, still render instantly (no loading delay/blank frames).
  - RoMailWindow titlebar buttons show vector glyphs, not text characters.
  - Reading pane avatar shows a collar strip under the face.
  - Ticket list amounts show on an orange pill background.
  - Taskbar shows two small tray icons left of the clock.
  - No console errors (this plan touches only client-side cosmetic code).

## 2. Files to Create / Change
### `src/client/Controllers/DesktopUI.luau` (Edit)
- `buildWallpaper()`: after the existing `UIGradient`, add a tiled grid of circular `Frame`s (`UICorner` radius = half size, `BackgroundTransparency` ~0.85, light color) spanning the wallpaper, generated with a nested loop (not one Frame per stud instance count explosion -- keep it to a reasonable grid, e.g. ~8x5).
- `buildTrashIcon` / `buildEnvelopeIcon` / `buildNotepadIcon` / `buildSafeIcon`: add one extra highlight/shadow child shape each (e.g. a lighter strip on the trash lid, a subtle shadow under the envelope) for more depth. Keep each icon's total child count small (hackathon scope, not a full icon library).
- `buildMailWindow()`: replace `closeButton`/`minimizeButton`/`maximizeButton` text glyphs with small vector shapes built inline (reuse `addCorner`/rotation patterns already used elsewhere in the file).
- `buildDummyFace()`: add a collar `Frame` (short wide rounded rect, blue) positioned just below the face circle.
- `renderMailList()`: wrap each card's amount `TextLabel` in a small `Frame` (`UICorner`, orange background) sized to the text.
- `buildTaskbar()`: add two small vector tray icons (speaker: a trapezoid + small arcs approximated with Frames; wifi: 3 stacked arcs approximated with rounded Frame slivers) positioned left of `clockLabel`. Keep these simple -- a recognizable silhouette is enough, not literal icon fidelity.

## 3. Remotes
- None. Purely client-side cosmetic changes.

## 4. Existing Code & Instances
- `src/client/Controllers/DesktopUI.luau`: `buildWallpaper`, `buildTrashIcon`, `buildEnvelopeIcon`, `buildNotepadIcon`, `buildSafeIcon`, `buildDummyFace`, `buildMailWindow`, `renderMailList`, `buildTaskbar` -- all already exist from `plans/desktop-ui.md` and `plans/desktop-icons.md`; this plan only adds detail to them.
- `addCorner` / `addStroke` helpers already defined at the top of the file -- reuse, don't duplicate.

## 5. Out of Scope
- **Live budget in the taskbar.** The mockup shows `$25,000` next to the clock, but `plans/tickets.md` / `plans/game-flow-prototype.md` deliberately hide the budget during a shift (no instant feedback on decisions). Taskbar keeps showing only the clock. If the user wants this changed, it needs an explicit decision first since it reverses an existing game-design rule, not just a visual tweak.
- Any `ImageLabel`/asset-based icon (blocked in this environment, see §0).
- Animated scrambled/garbled phishing body text (content/copy, not layout) -- out of scope for this visual-polish pass.
- Drag-and-drop icon rearrangement (already out of scope per `plans/desktop-icons.md`).
