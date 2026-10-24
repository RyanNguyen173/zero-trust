# Map Build Plan: 20x20 House Near Spawn

## 1. Anchor Point (Measured Existing Instances)
- `Workspace.SpawnLocation`: Position `(0, 0.5, 0)`, Size `(12, 1, 12)`, Top surface `Y = 1.0`
- `Workspace.Baseplate`: Position `(0, -8, 0)`, Size `(2048, 16, 2048)`, Top surface `Y = 0.0`
- House placement: Centered at `X = 0, Z = 25` (10 studs north of spawn edge). Footprint spans `X: [-10, 10]`, `Z: [15, 35]`.

## 2. Model Name & Hierarchy
- Target: `Workspace.House` (Model)
  - `Floor` (Part)
  - `WallBack` (Part)
  - `WallLeft` (Part)
  - `WallRight` (Part)
  - `WallFrontLeft` (Part)
  - `WallFrontRight` (Part)
  - `DoorHeader` (Part)
  - `Roof` (Part)
  - `CeilingLight` (Part with PointLight)

## 3. Parts Specification
All parts: `Anchored = true`, `CanCollide = true`, `TopSurface = Smooth`, `BottomSurface = Smooth`.

| Part Name | Size (X, Y, Z) | Position (X, Y, Z) | Color (RGB) | Material | Notes |
|---|---|---|---|---|---|
| Floor | `20, 1, 20` | `0, 0.5, 25` | `140, 95, 55` | `Enum.Material.WoodPlanks` | Base surface at Y=1.0 |
| WallBack | `20, 10, 1` | `0, 6, 34.5` | `215, 195, 160` | `Enum.Material.WoodPlanks` | Back wall |
| WallLeft | `1, 10, 18` | `-9.5, 6, 25` | `215, 195, 160` | `Enum.Material.WoodPlanks` | Left side wall |
| WallRight | `1, 10, 18` | `9.5, 6, 25` | `215, 195, 160` | `Enum.Material.WoodPlanks` | Right side wall |
| WallFrontLeft | `8, 10, 1` | `-6, 6, 15.5` | `215, 195, 160` | `Enum.Material.WoodPlanks` | Front wall left of door |
| WallFrontRight | `8, 10, 1` | `6, 6, 15.5` | `215, 195, 160` | `Enum.Material.WoodPlanks` | Front wall right of door |
| DoorHeader | `4, 3, 1` | `0, 9.5, 15.5` | `215, 195, 160` | `Enum.Material.WoodPlanks` | Wall above 4x7 doorway |
| Roof | `22, 1, 22` | `0, 11.5, 25` | `105, 50, 40` | `Enum.Material.Slate` | 1-stud overhang |
| CeilingLight | `2, 0.5, 2` | `0, 10.75, 25` | `255, 245, 200` | `Enum.Material.Neon` | PointLight inside (Range=24, Brightness=2) |

Doorway opening: centered at `X = 0`, width 4 studs (`X: [-2, 2]`), height 7 studs (`Y: [1, 8]`).

## 4. Out of Scope
- Interactive door hinge / ProximityPrompt / door model.
- Windows and furniture (beds, tables, chairs).
- Exterior landscaping or pathways.
