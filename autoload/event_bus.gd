## EventBus — Global signal hub for cross-feature communication.
## No logic; only typed signal declarations. Registered as autoload.
extends Node


## Emitted when the UI language changes.
signal language_changed(locale: String)

## Emitted when the player selects or changes faction.
signal faction_selected(faction_id: StringName)

## Emitted when any progress data changes (puzzle result, territory unlock, etc.).
signal progress_changed()

## Emitted when a puzzle is completed.
signal puzzle_completed(puzzle_id: String, result: PuzzleResult)

## Emitted when a new territory is unlocked.
signal territory_unlocked(territory_id: StringName)

## Emitted when a save operation finishes.
signal save_completed(success: bool)

## Emitted when any game setting changes (volume, haptics, etc.).
signal settings_changed()
