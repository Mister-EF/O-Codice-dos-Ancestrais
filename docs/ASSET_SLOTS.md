# Asset Slots — Placeholder Registry

> Every visual and audio asset in the game is exposed as a nullable `@export` property.
> Code draws procedural fallbacks when a slot is `null`. Artists replace assets by
> editing the corresponding `.tres` resource or scene export.

---

## AssetCatalog (`core/asset_catalog.gd` → `data/asset_catalog.tres`)

| Slot Name | Type | Expected Format | Purpose |
|-----------|------|----------------|---------|
| `button_texture` | `Texture2D` | 9-patch PNG, ~320×88 | Generic button background |
| `panel_texture` | `Texture2D` | 9-patch PNG, ~600×400 | Generic panel/card background |
| `menu_background` | `Texture2D` | PNG, 720×1280 | Main menu background |
| `sfx_ui_click` | `AudioStream` | OGG/WAV, <1s | Button tap SFX |
| `music_menu` | `AudioStream` | OGG, loopable | Main menu music |
| `music_world_map` | `AudioStream` | OGG, loopable | World map music |
| `music_puzzle` | `AudioStream` | OGG, loopable | Generic puzzle music |
| `faction_icon_fallback` | `Texture2D` | PNG, 128×128 | Default faction icon |
| `faction_banner_fallback` | `Texture2D` | PNG, 512×256 | Default faction banner |

## FactionData (`core/faction_data.gd` → `data/factions/*.tres`)

| Slot Name | Type | Expected Format | Purpose | Files |
|-----------|------|----------------|---------|-------|
| `placeholder_icon` | `Texture2D` | PNG, 128×128 | Faction-specific icon | `pirates.tres`, `scholars.tres`, `mercenaries.tres` |
| `placeholder_banner` | `Texture2D` | PNG, 512×256 | Faction-specific banner | `pirates.tres`, `scholars.tres`, `mercenaries.tres` |

---

## Circuit Puzzle (`features/circuit_puzzle/circuit_puzzle.gd`, `circuit_tile.gd`)

| Slot Name | Type | Expected Format | Purpose | Files |
|-----------|------|----------------|---------|-------|
| `placeholder_tile_texture` | `Texture2D` | PNG, 128×128 | Connector line/tile texture fallback | `circuit_puzzle.gd`, `circuit_tile.gd` |
| `placeholder_source_texture` | `Texture2D` | PNG, 128×128 | Source / generator node texture | `circuit_puzzle.gd`, `circuit_tile.gd` |
| `placeholder_target_texture` | `Texture2D` | PNG, 128×128 | Target receiver node texture | `circuit_puzzle.gd`, `circuit_tile.gd` |
| `placeholder_blocker_texture` | `Texture2D` | PNG, 128×128 | Blocker / corrupted sector obstacle | `circuit_puzzle.gd`, `circuit_tile.gd` |
| `sfx_rotate` | `AudioStream` | OGG/WAV, <0.2s | Tile 90-degree rotate sound effect | `circuit_puzzle.gd` |
| `sfx_powered` | `AudioStream` | OGG/WAV, <0.4s | Target node powered energy hum | `circuit_puzzle.gd` |
| `sfx_solved` | `AudioStream` | OGG/WAV, <1.5s | Level completed / circuit restored jingle | `circuit_puzzle.gd` |

---

## Audio Buses

| Bus Name | Purpose |
|----------|---------|
| `Master` | Root bus (Godot default) |
| `Music` | Background music tracks |
| `SFX` | Sound effects |
| `UI` | UI interaction sounds |

---

*Updated: Step 3 — Circuit Logic Puzzle*
