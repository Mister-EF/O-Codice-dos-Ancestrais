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
| `ambience_world_map` | `AudioStream` | OGG, loopable | World map ambient wind/atmosphere |
| `sfx_territory_unlocked` | `AudioStream` | OGG/WAV, <1.5s | Territory unlock celebration jingle |
| `music_puzzle` | `AudioStream` | OGG, loopable | Generic puzzle music |
| `faction_icon_fallback` | `Texture2D` | PNG, 128×128 | Default faction icon |
| `faction_banner_fallback` | `Texture2D` | PNG, 512×256 | Default faction banner |

## FactionData (`core/faction_data.gd` → `data/factions/*.tres`)

| Slot Name | Type | Expected Format | Purpose | Files |
|-----------|------|----------------|---------|-------|
| `placeholder_icon` | `Texture2D` | PNG, 128×128 | Faction-specific icon | `pirates.tres`, `scholars.tres`, `mercenaries.tres` |
| `placeholder_banner` | `Texture2D` | PNG, 512×256 | Faction-specific banner | `pirates.tres`, `scholars.tres`, `mercenaries.tres` |
| `placeholder_music` | `AudioStream` | MP3/OGG, loopable | Faction / route theme music | `pirates.tres`, `scholars.tres`, `mercenaries.tres` |

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

## Memory Board Puzzle (`features/memory_board/memory_card.gd`, `memory_board.gd`)

| Slot Name | Type | Expected Format | Purpose | Files |
|-----------|------|----------------|---------|-------|
| `placeholder_card_back` | `Texture2D` | PNG, 128×128 | Hidden card back texture | `memory_card.gd`, `memory_board.gd` |
| `placeholder_card_front` | `Texture2D` | PNG, 128×128 | Front card face background texture | `memory_card.gd`, `memory_board.gd` |
| `placeholder_icon` | `Texture2D` | PNG, 128×128 | Concept icon texture | `concept_data.gd`, `memory_card.gd` |
| `sfx_flip` | `AudioStream` | OGG/WAV, <0.2s | Card flip sound effect | `memory_board.gd` |
| `sfx_match` | `AudioStream` | OGG/WAV, <0.5s | Pair match sound effect | `memory_board.gd` |
| `sfx_mismatch` | `AudioStream` | OGG/WAV, <0.5s | Pair mismatch sound effect | `memory_board.gd` |
| `sfx_win` | `AudioStream` | OGG/WAV, <1.5s | Memory level completion sound effect | `memory_board.gd` |

---

## Rune Logic Puzzle (`features/rune_logic/`)

| Slot Name | Type | Expected Format | Purpose | Files |
|-----------|------|----------------|---------|-------|
| `placeholder_rune_and` | `Texture2D` | PNG, 128×128 | AND gate rune icon | `rune_puzzle.gd`, `rune_node.gd` |
| `placeholder_rune_or` | `Texture2D` | PNG, 128×128 | OR gate rune icon | `rune_puzzle.gd`, `rune_node.gd` |
| `placeholder_rune_not` | `Texture2D` | PNG, 128×128 | NOT gate rune icon | `rune_puzzle.gd`, `rune_node.gd` |
| `placeholder_rune_input_on` | `Texture2D` | PNG, 128×128 | Input rune active (TRUE) state | `rune_puzzle.gd`, `rune_node.gd` |
| `placeholder_rune_input_off` | `Texture2D` | PNG, 128×128 | Input rune inactive (FALSE) state | `rune_puzzle.gd`, `rune_node.gd` |
| `placeholder_rune_output` | `Texture2D` | PNG, 128×128 | Output receiver node texture | `rune_puzzle.gd`, `rune_node.gd` |
| `sfx_toggle` | `AudioStream` | OGG/WAV, <0.2s | Input rune toggle sound effect | `rune_puzzle.gd` |
| `sfx_place` | `AudioStream` | OGG/WAV, <0.2s | Gate placement sound effect | `rune_puzzle.gd` |
| `sfx_solved` | `AudioStream` | OGG/WAV, <1.5s | Rune door unsealed sound effect | `rune_puzzle.gd` |
| `sfx_error` | `AudioStream` | OGG/WAV, <0.4s | Invalid placement / cycle sound effect | `rune_puzzle.gd` |

---

## Step 5 — World Map, Transitions, and UI Chrome

| Slot Name | Type | Expected Format | Purpose | Files |
|-----------|------|----------------|---------|-------|
| `placeholder_transition_texture` | `Texture2D` | PNG, 720×1280 or mask pattern | SceneManager fade/wipe transition texture | `autoload/scene_manager.gd` |
| `placeholder_map_background` | `Texture2D` | PNG, 1440×2560 (high-res map art) | Eldoria world map terrain texture | `ui/world_map/world_map.gd` |
| `placeholder_icon` | `Texture2D` | PNG, 128×128 | Territory marker icon when unlocked | `core/territory_data.gd` |
| `placeholder_locked_icon` | `Texture2D` | PNG, 128×128 | Territory marker icon when locked | `core/territory_data.gd` |

---

## Audio Buses

| Bus Name | Purpose |
|----------|---------|
| `Master` | Root bus (Godot default) |
| `Music` | Background music tracks |
| `SFX` | Sound effects |
| `UI` | UI interaction sounds |

---

*Updated: Step 5 — Full Game Flow & UI Navigation*


