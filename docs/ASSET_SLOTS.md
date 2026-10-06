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

---

## Audio Buses

| Bus Name | Purpose |
|----------|---------|
| `Master` | Root bus (Godot default) |
| `Music` | Background music tracks |
| `SFX` | Sound effects |
| `UI` | UI interaction sounds |

---

*Updated: Step 2 — Memory Board*
