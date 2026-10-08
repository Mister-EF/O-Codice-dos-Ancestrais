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

### MemoryBoard (`features/memory_board/memory_board.gd`)

| API | Signature | Description |
|-----|-----------|-------------|
| `start_level` | `(level: MemoryBoardLevel) -> void` | Starts or resets the selected memory puzzle |
| `level_finished` | `(result: PuzzleResult)` | Emitted once when a level is won or failed |
| `exit_requested` | `()` | Emitted when the player requests return to the host/map |

`MemoryBoard` does not register puzzle progress. The scene host must connect
`level_finished` and call `GameManager.register_puzzle_result(result)`. The temporary
debug launcher demonstrates this contract; the map/scene manager will own it in Step 5.
Run the standalone picker with
`godot --path . res://features/memory_board/memory_board_debug.tscn`.

### ConceptData (`core/concept_data.gd`, `class_name ConceptData extends Resource`)

Stores a concept id, localized name/definition/hint keys, an optional icon, and a
category. Concept resources live in `data/concepts/`.

### MemoryBoardLevel (`features/memory_board/memory_board_level.gd`)

Stores the `memory_01`…`memory_06` puzzle id, localized title/intro keys, grid size,
concept ids, pair mode, move/time limits, and move thresholds for one to three stars.
Level resources live in `data/puzzles/memory/`. A zero move/time limit is unlimited.

### MemoryBoardLogic (`features/memory_board/memory_board_logic.gd`)

Pure `RefCounted` puzzle rules. `setup(level, seed, faction_bonus)` creates a
seedable shuffled deck and applies optional `FactionData` move/time bonuses;
`flip(index)` returns a `FlipResult`, `resolve_mismatch()` closes a mismatch, and
`calculate_stars()` evaluates a completed attempt. It does not access autoloads or
emit signals. Run its headless tests with
`godot --headless -s res://tests/test_memory_board_logic.gd`.

### CircuitPuzzle (`features/circuit_puzzle/circuit_puzzle.gd`)

| API | Signature | Description |
|-----|-----------|-------------|
| `start_level` | `(level: CircuitLevel) -> void` | Starts or resets the selected circuit puzzle |
| `level_finished` | `(result: PuzzleResult)` | Emitted once when a level is won or the timer expires |
| `exit_requested` | `()` | Emitted when the player requests return to the host/map |

The scene host registers `level_finished` results through
`GameManager.register_puzzle_result(result)`; the standalone level picker demonstrates
this integration. Run it with
`godot --path . res://features/circuit_puzzle/circuit_puzzle_debug.tscn`.

### CircuitTileDef (`features/circuit_puzzle/circuit_tile_def.gd`)

Stores a cell coordinate, tile type, initial rotation, lock flag, and optional
localized concept key. `solution_rotation` is an authored solution witness used by
hint generation and the level validator; it does not change the player's starting
orientation.

### CircuitLevel (`features/circuit_puzzle/circuit_level.gd`)

Stores `circuit_01`…`circuit_08`, localized title/intro keys, grid dimensions, tile
definitions, required target coordinates, par and star thresholds, and an optional
time limit. Level resources live in `data/puzzles/circuit/`.

### CircuitLogic (`features/circuit_puzzle/circuit_logic.gd`)

Pure `RefCounted` rules with reciprocal-edge BFS, move and hint tracking, star
calculation, seeded `shuffle_from_solution(seed)`, and `get_hint()`. Optional injected
`FactionData.hint_discount` proportionally reduces the star-scoring penalty for hints;
the displayed move counter remains the number of tile rotations. It does not access
autoloads or emit signals.

### CircuitLevelSolver (`features/circuit_puzzle/circuit_level_solver.gd`)

Test/tool backtracking solver that tries distinct tile orientations (using the authored
solution as its preferred first candidate) and confirms every required target is
reachable. Run its headless coverage with
`godot --headless -s res://tests/test_circuit_logic.gd`.

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

## Localization Key Convention

| Prefix | Usage | Example |
|--------|-------|---------|
| `ui.*` | Generic UI chrome | `ui.play`, `ui.back`, `ui.settings` |
| `boot.*` | Boot/test scene | `boot.title`, `boot.language_label` |
| `faction.<id>.name|desc|bonus` | Faction strings | `faction.pirates.name` |
| `concept.<id>.name|definition|hint` | Tech concept strings | `concept.docker.name` |
| `puzzle.<id>.title|intro` | Puzzle strings | `puzzle.memory_01.title` |
| `ui.memory.*` | Memory puzzle UI | `ui.memory.moves`, `ui.memory.hint` |
| `rune.*` | Rune logic puzzle strings | `rune.and_gate` |
| `territory.<id>.name|desc` | World map territory | `territory.01.name` |
| `tooltip.*` | Tooltip/clue text | `tooltip.tap_to_interact` |
| `settings.*` | Settings labels | `settings.music_volume` |
| `error.*` | Error messages | `error.save_failed` |

**Rules:**
- Every key must exist in both `en.json` and `pt_BR.json`.
- `{placeholder}` names must be identical across locales.
- No user-visible string may be hardcoded in `.gd` or `.tscn` files.