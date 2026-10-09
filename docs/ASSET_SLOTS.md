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
| `music_map_ambience` | `AudioStream` | OGG, loopable stereo ambience | Preferred Eldoria ambience; falls back to `music_world_map` |
| `placeholder_transition_texture` | `Texture2D` | PNG, 720×1280 | Optional artwork over the flat-color fade transition |
| `placeholder_game_logo` | `Texture2D` | PNG/SVG, ~512×256 | Main-menu logo; hidden when null |
| `placeholder_menu_background` | `Texture2D` | PNG, 720×1280 | Main-menu backdrop; falls back to `menu_background`/flat color |
| `placeholder_map_background` | `Texture2D` | PNG, 900×1600 | Scrollable map image; null uses a procedural gradient |
| `placeholder_territory_icon` | `Texture2D` | PNG/SVG, 128×128 | Shared unlocked territory marker |
| `placeholder_territory_locked_icon` | `Texture2D` | PNG/SVG, 128×128 | Shared locked territory marker |
| `placeholder_unlock_vfx` | `Texture2D` | PNG/SVG sprite, 256×256 | Optional accent in the territory-unlock toast |
| `faction_icon_fallback` | `Texture2D` | PNG, 128×128 | Default faction icon |
| `faction_banner_fallback` | `Texture2D` | PNG, 512×256 | Default faction banner |

`AudioManager` crossfades on the `Music` bus and falls back to `Master` if the bus is
missing. Catalog texture and audio slots are all nullable.

## Shared UI (`ui/common/`)

| Slot Name | Type | Expected Format | Purpose |
|-----------|------|----------------|---------|
| `GameTheme.placeholder_font` | `Font` | Godot-supported font resource | Optional shared typeface; Godot default if null |
| `SceneManager.placeholder_transition_texture` | `Texture2D` | PNG, 720×1280 | Optional scene-transition overlay artwork |
| `AudioManager.placeholder_map_ambience` | `AudioStream` | OGG, loopable stereo | Optional autoload override; null uses the `AssetCatalog` map ambience slot |

Controls use flat procedural StyleBoxes and do not require custom art. `GameButton`
adds press feedback and settings-aware haptics.

## Main Menu and Faction Select (`ui/main_menu/`, `ui/faction_select/`)

| Slot Name | Type | Expected Format | Purpose |
|-----------|------|----------------|---------|
| `AssetCatalog.placeholder_game_logo` | `Texture2D` | PNG/SVG, ~512×256 | Main-menu logo |
| `AssetCatalog.placeholder_menu_background` | `Texture2D` | PNG, 720×1280 | Main-menu background |
| `FactionData.placeholder_icon` | `Texture2D` | PNG/SVG, 256×256 | Faction-card portrait; catalog icon is fallback |
| `FactionData.placeholder_banner` | `Texture2D` | PNG, 512×256 | Optional faction banner |
| `music_menu` | `AudioStream` | OGG, loopable | Main-menu music |

If faction images are absent, the card displays a localized portrait label and its
faction theme color.

## Eldoria Map (`ui/world_map/`, `data/territories/`)

| Slot Name | Type | Expected Format | Purpose |
|-----------|------|----------------|---------|
| `AssetCatalog.placeholder_map_background` | `Texture2D` | PNG, 900×1600 | Pannable map background; procedural gradient fallback |
| `TerritoryData.placeholder_icon` | `Texture2D` | PNG/SVG, 128×128 | Territory-specific unlocked marker |
| `TerritoryData.placeholder_locked_icon` | `Texture2D` | PNG/SVG, 128×128 | Territory-specific locked marker |
| `AssetCatalog.placeholder_territory_icon` | `Texture2D` | PNG/SVG, 128×128 | Shared unlocked-marker fallback |
| `AssetCatalog.placeholder_territory_locked_icon` | `Texture2D` | PNG/SVG, 128×128 | Shared locked-marker fallback |
| `AssetCatalog.placeholder_unlock_vfx` | `Texture2D` | PNG/SVG, 256×256 | Toast visual accent; null uses text and animation only |
| `AssetCatalog.music_map_ambience` | `AudioStream` | OGG, loopable stereo | Map ambience; falls back to `music_world_map` |

## FactionData (`core/faction_data.gd` → `data/factions/*.tres`)

| Slot Name | Type | Expected Format | Purpose | Files |
|-----------|------|----------------|---------|-------|
| `placeholder_icon` | `Texture2D` | PNG, 128×128 | Faction-specific icon | `pirates.tres`, `scholars.tres`, `mercenaries.tres` |
| `placeholder_banner` | `Texture2D` | PNG, 512×256 | Faction-specific banner | `pirates.tres`, `scholars.tres`, `mercenaries.tres` |

## Memory Board (`features/memory_board/`)

| Slot Name | Type | Expected Format | Purpose |
|-----------|------|----------------|---------|
| `placeholder_card_back` | `Texture2D` | PNG, square/tall card art | Shared card-back art; null uses a flat color and localized text |
| `placeholder_card_front` | `Texture2D` | PNG, square/tall card art | Shared card-front art; null uses a flat color and localized text |
| `ConceptData.placeholder_icon` | `Texture2D` | PNG/SVG, square | Optional concept icon used by icon-mode pairs |
| `sfx_flip` | `AudioStream` | OGG/WAV, short | Card reveal sound |
| `sfx_match` | `AudioStream` | OGG/WAV, short | Correct pair sound |
| `sfx_mismatch` | `AudioStream` | OGG/WAV, short | Incorrect pair sound |
| `sfx_win` | `AudioStream` | OGG/WAV, short | Completed-level sound |

Card textures and sound streams are nullable scene exports on `MemoryBoard`; per-card
front/back exports on `MemoryCard` can override the textures. All slots have procedural
or silent null fallbacks.

## Circuit Puzzle (`features/circuit_puzzle/`)

| Slot Name | Type | Expected Format | Purpose |
|-----------|------|----------------|---------|
| `placeholder_tile_texture` | `Texture2D` | PNG/SVG, square | Generic connector tile; null draws paths procedurally |
| `placeholder_source_texture` | `Texture2D` | PNG/SVG, square | Source tile art; null draws a source node |
| `placeholder_target_texture` | `Texture2D` | PNG/SVG, square | Target tile art; null draws a target node |
| `placeholder_blocker_texture` | `Texture2D` | PNG/SVG, square | Blocker art; null draws a crossed obstacle |
| `sfx_rotate` | `AudioStream` | OGG/WAV, short | Connector rotation |
| `sfx_powered` | `AudioStream` | OGG/WAV, short | Circuit energy propagation |
| `sfx_solved` | `AudioStream` | OGG/WAV, short | All required targets powered |

All circuit exports are nullable on `CircuitPuzzle` and `CircuitTile`; procedural
visuals and silent playback keep missing assets safe.

## Rune Logic (`features/rune_logic/`)

| Slot Name | Type | Expected Format | Purpose |
|-----------|------|----------------|---------|
| `placeholder_rune_and` | `Texture2D` | PNG/SVG, square | AND gate rune |
| `placeholder_rune_or` | `Texture2D` | PNG/SVG, square | OR gate rune |
| `placeholder_rune_not` | `Texture2D` | PNG/SVG, square | NOT gate rune |
| `placeholder_rune_input_on` | `Texture2D` | PNG/SVG, square | TRUE input rune |
| `placeholder_rune_input_off` | `Texture2D` | PNG/SVG, square | FALSE input rune |
| `placeholder_rune_output` | `Texture2D` | PNG/SVG, square | Output rune |
| `sfx_toggle` | `AudioStream` | OGG/WAV, short | Input changed |
| `sfx_place` | `AudioStream` | OGG/WAV, short | Gate placed or removed |
| `sfx_solved` | `AudioStream` | OGG/WAV, short | Rune puzzle solved |
| `sfx_error` | `AudioStream` | OGG/WAV, short | Invalid gate placement |

Rune textures and audio streams are nullable exports on `RunePuzzle` and `RuneNode`.
Localized geometric rune glyphs and labels are drawn/shown when textures are null.

---

## Audio Buses

| Bus Name | Purpose |
|----------|---------|
| `Master` | Root bus (Godot default) |
| `Music` | Background music tracks |
| `SFX` | Sound effects |
| `UI` | UI interaction sounds |

---

*Updated: Steps 2–5 — puzzles, shared UI, menus, settings, and Eldoria map*
