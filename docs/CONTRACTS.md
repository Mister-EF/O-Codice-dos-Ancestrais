# Contracts — Public API Reference

> This file documents every autoload, signal, public method, resource class, and the
> localization key convention established in the project. **Do NOT break or rename
> existing public APIs; extend them.** If a change is unavoidable, state it explicitly
> in the Handoff Report.

---

## Autoloads (registered in this order)

### 1. EventBus (`autoload/event_bus.gd`)

Signal-only hub — no logic.

| Signal | Parameters | Emitted when |
|--------|-----------|-------------|
| `language_changed` | `locale: String` | UI language changes |
| `faction_selected` | `faction_id: StringName` | Player selects/changes faction |
| `progress_changed` | *(none)* | Any progress data changes |
| `puzzle_completed` | `puzzle_id: String, result: PuzzleResult` | A puzzle is completed |
| `territory_unlocked` | `territory_id: StringName` | A territory is unlocked |
| `save_completed` | `success: bool` | Save operation finishes |
| `settings_changed` | *(none)* | Any game setting changes |

### 2. Localization (`autoload/localization.gd`)

Manages runtime language switching with JSON translation sources.

| Method | Signature | Description |
|--------|-----------|-------------|
| `set_language` | `(locale: String) -> void` | Validate, apply, persist, emit `language_changed` |
| `get_language` | `() -> String` | Currently active locale |
| `get_supported_languages` | `() -> Array[String]` | List of supported locale codes |
| `get_language_display_name` | `(locale: String) -> String` | Locale name in its own language |
| `translate` | `(key: String, params: Dictionary = {}) -> String` | Resolve key with fallback + placeholder substitution |
| `has_key` | `(key: String) -> bool` | Whether key exists in current locale |

**Constants:** `SUPPORTED_LOCALES: Array[String] = ["en", "pt_BR"]`, `DEFAULT_LOCALE: String = "en"`

### 3. SaveSystem (`autoload/save_system.gd`)

Local JSON persistence with atomic writes, corruption recovery, and debounced auto-save.

| Method | Signature | Description |
|--------|-----------|-------------|
| `save` | `(data: Dictionary) -> bool` | Write full data to disk atomically |
| `load_data` | `() -> Dictionary` | Load and return saved data (defaults on failure) |
| `delete_save` | `() -> void` | Delete save file |
| `exists` | `() -> bool` | Whether save file exists |
| `request_save` | `() -> void` | Schedule a debounced save |
| `set_value` | `(key: String, value: Variant) -> void` | Update a single cached key + schedule save |
| `get_value` | `(key: String, default: Variant = null) -> Variant` | Read from cached data |
| `get_cached_data` | `() -> Dictionary` | Return cached save data |

**Save schema** (`user://codex_save.json`):
```json
{
  "version": 1,
  "locale": "en",
  "faction": "pirates",
  "puzzles": { "<id>": { "stars": 3, "best_moves": 12, "best_time": 45.2 } },
  "unlocked_territories": ["territory_01"],
  "settings": { "music_volume": 1.0, "sfx_volume": 1.0, "haptics_enabled": true }
}
```

### 4. GameManager (`autoload/game_manager.gd`)

Central game state controller.

**Enum:** `Faction { NONE, PIRATES, SCHOLARS, MERCENARIES }`

#### Faction API

| Method | Signature | Description |
|--------|-----------|-------------|
| `select_faction` | `(faction: Faction) -> void` | Select faction, persist, emit `faction_selected` |
| `get_faction` | `() -> Faction` | Current faction enum |
| `get_faction_data` | `() -> FactionData` | FactionData resource for current faction (null if NONE) |
| `get_faction_data_for` | `(faction: Faction) -> FactionData` | FactionData for a specific faction |
| `has_chosen_faction` | `() -> bool` | True if faction is not NONE |

#### Puzzle Progress API

| Method | Signature | Description |
|--------|-----------|-------------|
| `register_puzzle_result` | `(result: PuzzleResult) -> void` | Record attempt, keep best stars |
| `get_best_stars` | `(puzzle_id: String) -> int` | Best stars for a puzzle (0 if never attempted) |
| `is_puzzle_completed` | `(puzzle_id: String) -> bool` | True if completed at least once |
| `get_total_stars` | `() -> int` | Sum of best stars across all puzzles |

#### Territory API

| Method | Signature | Description |
|--------|-----------|-------------|
| `unlock_territory` | `(id: StringName) -> void` | Unlock territory, emit events |
| `is_territory_unlocked` | `(id: StringName) -> bool` | Check if territory is unlocked |

#### Save/Load API

| Method | Signature | Description |
|--------|-----------|-------------|
| `new_game` | `() -> void` | Reset all progress |
| `continue_game` | `() -> void` | Load from saved state |
| `has_save` | `() -> bool` | Whether save file exists |
| `save` | `() -> void` | Persist current state |
| `load_game` | `() -> void` | Load state from disk |

#### Settings API

| Method | Signature | Description |
|--------|-----------|-------------|
| `get_music_volume` / `set_music_volume` | `() -> float` / `(volume: float) -> void` | Music volume (0.0–1.0) |
| `get_sfx_volume` / `set_sfx_volume` | `() -> float` / `(volume: float) -> void` | SFX volume (0.0–1.0) |
| `is_haptics_enabled` / `set_haptics_enabled` | `() -> bool` / `(enabled: bool) -> void` | Haptic feedback toggle |

---

## Resource Classes

### FactionData (`core/faction_data.gd`, `class_name FactionData extends Resource`)

| Property | Type | Description |
|----------|------|-------------|
| `id` | `StringName` | Unique faction id (e.g. `&"pirates"`) |
| `name_key` | `String` | Translation key for display name |
| `description_key` | `String` | Translation key for description |
| `bonus_key` | `String` | Translation key for bonus text |
| `placeholder_icon` | `Texture2D` | Faction icon (nullable) |
| `placeholder_banner` | `Texture2D` | Faction banner (nullable) |
| `theme_color` | `Color` | UI accent color |
| `hint_discount` | `int` | % discount on hint cost |
| `time_bonus_seconds` | `float` | Extra seconds on timed puzzles |
| `extra_flip_allowance` | `int` | Extra flips in memory puzzles |

### PuzzleResult (`core/puzzle_result.gd`, `class_name PuzzleResult extends Resource`)

| Property | Type | Description |
|----------|------|-------------|
| `puzzle_id` | `String` | Unique puzzle identifier |
| `completed` | `bool` | Whether puzzle was completed |
| `stars` | `int` | Star rating 0–3 |
| `moves` | `int` | Number of moves |
| `time_seconds` | `float` | Time spent |
| `hints_used` | `int` | Hints consumed |

### AssetCatalog (`core/asset_catalog.gd`, `class_name AssetCatalog extends Resource`)

Central registry of all placeholder asset slots. See `docs/ASSET_SLOTS.md` for the full table.

---

## Reusable UI Components

| Class | File | Description |
|-------|------|-------------|
| `LocalizedLabel` | `core/localized_label.gd` | Label that auto-refreshes from translation key |
| `LocalizedButton` | `core/localized_button.gd` | Button that auto-refreshes from translation key |
| `SafeAreaContainer` | `core/safe_area_container.gd` | MarginContainer applying device safe area insets |
| `Haptics` | `core/haptics.gd` | Static helper for guarded haptic feedback |

Both `LocalizedLabel` and `LocalizedButton` expose:
- `@export var translation_key: String`
- `@export var params: Dictionary`
- `func set_localized(key: String, p: Dictionary = {}) -> void`

---

## Circuit Puzzle (`features/circuit_puzzle/`)

### 1. CircuitTileDef (`features/circuit_puzzle/circuit_tile_def.gd`)

Pure data resource representing an individual circuit tile.

| Property / Method | Type | Description |
|-------------------|------|-------------|
| `tile_type` | `CircuitTileType` | Enum: `EMPTY`, `STRAIGHT`, `CORNER`, `T_JUNCTION`, `CROSS`, `SOURCE`, `TARGET`, `BLOCKER` |
| `rotation_index` | `int` | Rotation steps 0..3 (0, 90, 180, 270 degrees clockwise) |
| `locked` | `bool` | Whether tile is locked against player rotation |
| `label_key` | `String` | Optional localization key for concept node (e.g. `concept.flow.parse`) |
| `solution_rotation` | `int` | Rotation index for the solved state |
| `get_base_mask` | `(type: CircuitTileType) -> int` | Static 4-bit mask (N:1, E:2, S:4, W:8) at rotation 0 |
| `rotate_mask` | `(mask: int, steps: int) -> int` | Static circular 4-bit shift clockwise |

### 2. CircuitLevel (`features/circuit_puzzle/circuit_level.gd`)

Puzzle level definition resource.

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Puzzle identifier (`circuit_01` .. `circuit_08`) |
| `title_key` | `String` | Translation key for level title |
| `intro_key` | `String` | Translation key for educational narrative intro |
| `grid_columns` / `grid_rows` | `int` | Dimensions of the puzzle grid |
| `tiles` | `Array[CircuitTileDef]` | Flat array of tile definitions |
| `required_targets` | `int` | Number of targets required to solve (0 = all targets) |
| `par_moves` | `int` | Target move count |
| `star_thresholds` | `Array[int]` | Move thresholds for [3 stars, 2 stars, 1 star] |
| `time_limit_seconds` | `float` | Optional countdown limit (0.0 = untimed) |

### 3. CircuitLogic (`features/circuit_puzzle/circuit_logic.gd`)

Pure algorithmic state engine (extends `RefCounted`).

| Method | Signature | Description |
|--------|-----------|-------------|
| `load_level` | `(level: CircuitLevel) -> void` | Reset state and initialize grid from level |
| `rotate_tile` | `(cell: Vector2i) -> bool` | Rotate tile 90° clockwise, increments `moves` if unlocked |
| `compute_powered` | `() -> Dictionary` | BFS flood-fill returning `{Vector2i: bool}` honoring edge symmetry |
| `is_solved` | `() -> bool` | True if powered targets >= `required_targets` |
| `calculate_stars` | `() -> int` | Compute 0..3 stars based on moves vs thresholds |
| `get_hint` | `() -> Vector2i` | Returns wrongly oriented cell vs solution (-1,-1 if none) |

### 4. CircuitSolver (`features/circuit_puzzle/circuit_solver.gd`)

Validator and level shuffler utility.

| Method | Signature | Description |
|--------|-----------|-------------|
| `shuffle_from_solution` | `(level: CircuitLevel, seed: int) -> void` | Scramble level from solution guaranteeing initial unsolved state |
| `validate_authored_solution` | `(level: CircuitLevel) -> bool` | Verify that authored `solution_rotation` solves the level |
| `find_solution` | `(level: CircuitLevel, max_nodes: int) -> bool` | Backtracking solver checking solvability |

### 5. CircuitPuzzle (`features/circuit_puzzle/circuit_puzzle.gd`)

Main UI controller view (extends `Control`).

| Method / Signal | Signature | Description |
|-----------------|-----------|-------------|
| `start_level` | `(level: CircuitLevel) -> void` | Begin playing specified level |
| `signal level_finished` | `(result: PuzzleResult)` | Emitted when all required targets are powered |
| `signal exit_requested` | `()` | Emitted when back button is pressed |

---

## Localization Key Convention

| Prefix | Usage | Example |
|--------|-------|---------|
| `ui.*` | Generic UI chrome | `ui.play`, `ui.back`, `ui.settings` |
| `ui.circuit.*` | Circuit puzzle chrome | `ui.circuit.moves`, `ui.circuit.hint` |
| `boot.*` | Boot/test scene | `boot.title`, `boot.language_label` |
| `faction.<id>.name\|desc\|bonus` | Faction strings | `faction.pirates.name` |
| `concept.<id>.name\|definition\|hint` | Tech concept strings | `concept.docker.name` |
| `concept.flow.<id>.name\|definition\|hint` | Program flow concepts | `concept.flow.parse.name` |
| `puzzle.<id>.title\|intro` | Puzzle strings | `puzzle.circuit_01.title` |
| `rune.*` | Rune logic puzzle strings | `rune.and_gate` |
| `territory.<id>.name\|desc` | World map territory | `territory.01.name` |
| `tooltip.*` | Tooltip/clue text | `tooltip.tap_to_interact` |
| `settings.*` | Settings labels | `settings.music_volume` |
| `error.*` | Error messages | `error.save_failed` |

**Rules:**
- Every key must exist in both `en.json` and `pt_BR.json`.
- `{placeholder}` names must be identical across locales.
- No user-visible string may be hardcoded in `.gd` or `.tscn` files.

