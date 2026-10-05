## PuzzleResult — Stores the outcome of a single puzzle attempt.
## Pure data class; no node dependencies.
class_name PuzzleResult
extends Resource


## Unique identifier for the puzzle.
@export var puzzle_id: String = ""

## Whether the puzzle was completed successfully.
@export var completed: bool = false

## Star rating from 0 (not rated / failed) to 3 (perfect).
@export var stars: int = 0

## Number of moves the player made during this attempt.
@export var moves: int = 0

## Time in seconds the player spent on this attempt.
@export var time_seconds: float = 0.0

## Number of hints the player used during this attempt.
@export var hints_used: int = 0
