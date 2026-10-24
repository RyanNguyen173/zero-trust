# Feature Plan: Custom Desktop Wallpaper Support
Decision: Configurable Wallpaper Asset ID / Fallback Gradient

*Allows user to provide a custom wallpaper decal/image ID via Config.luau.*

## 1. Goal & Testing
- **Goal:** Support custom background images for the BloxOS desktop. If `Config.WALLPAPER_ASSET_ID` is set to an asset ID (e.g. `"rbxassetid://1234567890"`), display it via an `ImageLabel` (`ScaleType = Crop`). If empty `""`, fallback to the procedural navy gradient & studs.
- **Testing:** Play Solo in Studio.
  - Setting `Config.WALLPAPER_ASSET_ID = "rbxassetid://<id>"` renders the custom background image across the desktop.
  - Leaving it empty `""` cleanly displays the default procedural BloxOS wallpaper.

## 2. Files to Create / Change
### `src/shared/Config.luau` (Edit)
- Add `WALLPAPER_ASSET_ID = ""` (or string asset ID).

### `src/client/Controllers/DesktopUI.luau` (Edit)
- In `buildWallpaper()`:
  - If `Config.WALLPAPER_ASSET_ID ~= ""` then:
    - Create an `ImageLabel` child on `BloxWallpaper` (`Size = UDim2.new(1, 0, 1, 0)`, `Image = Config.WALLPAPER_ASSET_ID`, `ScaleType = Enum.ScaleType.Crop`, `ZIndex = 1`).
  - Else:
    - Render the gradient and vector stud grid.

## 3. Remotes
- None.

## 4. Existing Code & Instances
- `src/shared/Config.luau` line 62.
- `src/client/Controllers/DesktopUI.luau` `buildWallpaper()`.

## 5. Out of Scope
- Runtime in-game wallpaper picker menu.
