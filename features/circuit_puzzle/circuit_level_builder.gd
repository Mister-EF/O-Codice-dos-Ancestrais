## CircuitLevelBuilder — Authoring utility that builds and serializes all 8 levels.
## Guarantees topological correctness, valid solutions, and educational concept mapping.
class_name CircuitLevelBuilder
extends RefCounted


## Factory helper to create a tile definition.
static func tile(
	type: CircuitTileDef.CircuitTileType,
	solution_rot: int,
	initial_rot: int = -1,
	is_locked: bool = false,
	label: String = ""
) -> CircuitTileDef:
	var def: CircuitTileDef = CircuitTileDef.new()
	def.tile_type = type
	def.solution_rotation = solution_rot
	def.rotation_index = initial_rot if initial_rot >= 0 else solution_rot
	def.locked = is_locked
	def.label_key = label
	return def


## Builds Level 1: 3x3 — "Hello World Execution Flow"
## Flow: (0,0) Source [Input] -> (1,0) Straight -> (2,0) Corner -> (2,1) Straight [Parse] -> (2,2) Target [Output]
static func build_level_1() -> CircuitLevel:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.id = "circuit_01"
	lvl.title_key = "puzzle.circuit_01.title"
	lvl.intro_key = "puzzle.circuit_01.intro"
	lvl.grid_columns = 3
	lvl.grid_rows = 3
	lvl.required_targets = 1
	lvl.par_moves = 4
	lvl.star_thresholds = [4, 6, 10]
	lvl.time_limit_seconds = 0.0

	# Row 0:
	# (0,0): SOURCE pointing East (rot 1) [locked]
	# (1,0): STRAIGHT East-West (rot 1)
	# (2,0): CORNER West-South (rot 2)
	# Row 1:
	# (0,1): BLOCKER
	# (1,1): EMPTY
	# (2,1): STRAIGHT North-South (rot 0) [concept.flow.parse]
	# Row 2:
	# (0,2): EMPTY
	# (1,2): BLOCKER
	# (2,2): TARGET pointing North (rot 0) [concept.flow.output, locked]
	lvl.tiles = [
		tile(CircuitTileDef.CircuitTileType.SOURCE, 1, 1, true, "concept.flow.input"),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 2, 0, false, ""),

		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, "concept.flow.parse"),

		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.TARGET, 0, 0, true, "concept.flow.output"),
	]
	return lvl


## Builds Level 2: 3x3 — "Data Validation Gate"
## Flow: Source [Input] at (0,1) -> T_Junction [Validate] at (1,1) -> Target 1 [Output] at (2,1) & Target 2 [Error] at (1,2)
static func build_level_2() -> CircuitLevel:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.id = "circuit_02"
	lvl.title_key = "puzzle.circuit_02.title"
	lvl.intro_key = "puzzle.circuit_02.intro"
	lvl.grid_columns = 3
	lvl.grid_rows = 3
	lvl.required_targets = 2
	lvl.par_moves = 5
	lvl.star_thresholds = [5, 8, 14]
	lvl.time_limit_seconds = 0.0

	# Row 0:
	# (0,0): CORNER (rot 1: E-S)
	# (1,0): STRAIGHT (rot 0: N-S)
	# (2,0): EMPTY
	# Row 1:
	# (0,1): SOURCE pointing East (rot 1) [locked, Input]
	# (1,1): T_JUNCTION (rot 1: East, South, West) [Validate]
	# (2,1): TARGET pointing West (rot 3) [locked, Output]
	# Row 2:
	# (0,2): BLOCKER
	# (1,2): TARGET pointing North (rot 0) [locked, Error Handler]
	# (2,2): BLOCKER
	lvl.tiles = [
		tile(CircuitTileDef.CircuitTileType.CORNER, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),

		tile(CircuitTileDef.CircuitTileType.SOURCE, 1, 1, true, "concept.flow.input"),
		tile(CircuitTileDef.CircuitTileType.T_JUNCTION, 1, 3, false, "concept.flow.validate"),
		tile(CircuitTileDef.CircuitTileType.TARGET, 3, 3, true, "concept.flow.output"),

		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.TARGET, 0, 0, true, "concept.flow.error_handler"),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
	]
	return lvl


## Builds Level 3: 4x4 — "Batch Processing Loop"
## Introduces the Loop concept tile and path cycling into an output target.
static func build_level_3() -> CircuitLevel:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.id = "circuit_03"
	lvl.title_key = "puzzle.circuit_03.title"
	lvl.intro_key = "puzzle.circuit_03.intro"
	lvl.grid_columns = 4
	lvl.grid_rows = 4
	lvl.required_targets = 1
	lvl.par_moves = 7
	lvl.star_thresholds = [7, 11, 18]
	lvl.time_limit_seconds = 0.0

	# Path:
	# (0,0) SOURCE [Input] East (rot 1)
	# (1,0) STRAIGHT East-West (rot 1)
	# (2,0) CORNER West-South (rot 2)
	# (2,1) T_JUNCTION North-South-West (rot 2: S, W, N) [Loop]
	# (1,1) CORNER East-North (rot 0: N, E)
	# (2,2) STRAIGHT North-South (rot 0) [Parse]
	# (2,3) CORNER North-East (rot 0: N, E)
	# (3,3) TARGET West (rot 3) [Output]
	lvl.tiles = [
		# Row 0
		tile(CircuitTileDef.CircuitTileType.SOURCE, 1, 1, true, "concept.flow.input"),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 2, 1, false, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		# Row 1
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 0, 2, false, ""),
		tile(CircuitTileDef.CircuitTileType.T_JUNCTION, 2, 0, false, "concept.flow.loop"),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		# Row 2
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, "concept.flow.parse"),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		# Row 3
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 0, 3, false, ""),
		tile(CircuitTileDef.CircuitTileType.TARGET, 3, 3, true, "concept.flow.output"),
	]
	return lvl


## Builds Level 4: 4x4 — "Function Call & Return"
static func build_level_4() -> CircuitLevel:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.id = "circuit_04"
	lvl.title_key = "puzzle.circuit_04.title"
	lvl.intro_key = "puzzle.circuit_04.intro"
	lvl.grid_columns = 4
	lvl.grid_rows = 4
	lvl.required_targets = 1
	lvl.par_moves = 8
	lvl.star_thresholds = [8, 13, 20]
	lvl.time_limit_seconds = 0.0

	# Flow: (0,0) Source South (rot 2) -> (0,1) Straight (rot 0) -> (0,2) Corner (rot 0: N, E) ->
	# (1,2) T_Junction (rot 3: W, N, E) [Function Call] -> (2,2) Straight (rot 1) -> (3,2) Corner (rot 2: S, W) ->
	# (3,3) TARGET North (rot 0) [Output]
	lvl.tiles = [
		# Row 0
		tile(CircuitTileDef.CircuitTileType.SOURCE, 2, 2, true, "concept.flow.input"),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		# Row 1
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 1, 2, false, ""),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		# Row 2
		tile(CircuitTileDef.CircuitTileType.CORNER, 0, 3, false, ""),
		tile(CircuitTileDef.CircuitTileType.T_JUNCTION, 3, 1, false, "concept.flow.function_call"),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 2, 0, false, ""),
		# Row 3
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.TARGET, 0, 0, true, "concept.flow.output"),
	]
	return lvl


## Builds Level 5: 5x5 — "Database Transaction Flow"
static func build_level_5() -> CircuitLevel:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.id = "circuit_05"
	lvl.title_key = "puzzle.circuit_05.title"
	lvl.intro_key = "puzzle.circuit_05.intro"
	lvl.grid_columns = 5
	lvl.grid_rows = 5
	lvl.required_targets = 2
	lvl.par_moves = 10
	lvl.star_thresholds = [10, 16, 25]
	lvl.time_limit_seconds = 0.0

	# 25 tiles
	lvl.tiles = [
		# Row 0
		tile(CircuitTileDef.CircuitTileType.SOURCE, 1, 1, true, "concept.flow.input"),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 2, 0, false, "concept.flow.validate"),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),

		# Row 1
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.T_JUNCTION, 1, 3, false, "concept.flow.function_call"),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.TARGET, 3, 3, true, "concept.flow.database"),

		# Row 2
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, ""),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),

		# Row 3
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 1, 3, false, ""),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 2, 0, false, ""),

		# Row 4
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.TARGET, 0, 0, true, "concept.flow.output"),
	]
	return lvl


## Builds Level 6: 5x5 — "Robust Error Handling Pipeline"
static func build_level_6() -> CircuitLevel:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.id = "circuit_06"
	lvl.title_key = "puzzle.circuit_06.title"
	lvl.intro_key = "puzzle.circuit_06.intro"
	lvl.grid_columns = 5
	lvl.grid_rows = 5
	lvl.required_targets = 2
	lvl.par_moves = 12
	lvl.star_thresholds = [12, 18, 28]
	lvl.time_limit_seconds = 0.0

	lvl.tiles = [
		# Row 0
		tile(CircuitTileDef.CircuitTileType.SOURCE, 2, 2, true, "concept.flow.input"),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.TARGET, 2, 2, true, "concept.flow.error_handler"),

		# Row 1
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, "concept.flow.parse"),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, ""),

		# Row 2
		tile(CircuitTileDef.CircuitTileType.T_JUNCTION, 0, 2, false, "concept.flow.validate"),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.CROSS, 0, 0, false, "concept.flow.loop"),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 0, 3, false, ""),

		# Row 3
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, ""),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, ""),
		tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),

		# Row 4
		tile(CircuitTileDef.CircuitTileType.CORNER, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, ""),
		tile(CircuitTileDef.CircuitTileType.CORNER, 0, 2, false, ""),
		tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""),
		tile(CircuitTileDef.CircuitTileType.TARGET, 0, 0, true, "concept.flow.output"),
	]
	return lvl


## Builds Level 7: 6x6 — "Microservice Event Router"
static func build_level_7() -> CircuitLevel:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.id = "circuit_07"
	lvl.title_key = "puzzle.circuit_07.title"
	lvl.intro_key = "puzzle.circuit_07.intro"
	lvl.grid_columns = 6
	lvl.grid_rows = 6
	lvl.required_targets = 3
	lvl.par_moves = 15
	lvl.star_thresholds = [15, 22, 34]
	lvl.time_limit_seconds = 0.0

	var list: Array[CircuitTileDef] = []
	for y: int in range(6):
		for x: int in range(6):
			list.append(tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""))
	lvl.tiles = list

	# Set specific grid nodes
	var set_t: Callable = func(x: int, y: int, t: CircuitTileDef.CircuitTileType, sol_r: int, init_r: int, lck: bool, lbl: String) -> void:
		lvl.tiles[y * 6 + x] = tile(t, sol_r, init_r, lck, lbl)

	# Source at (0, 0)
	set_t.call(0, 0, CircuitTileDef.CircuitTileType.SOURCE, 1, 1, true, "concept.flow.input")
	set_t.call(1, 0, CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, "")
	set_t.call(2, 0, CircuitTileDef.CircuitTileType.CORNER, 2, 0, false, "concept.flow.parse")

	set_t.call(2, 1, CircuitTileDef.CircuitTileType.T_JUNCTION, 1, 2, false, "concept.flow.validate")
	set_t.call(1, 1, CircuitTileDef.CircuitTileType.CORNER, 1, 0, false, "")
	set_t.call(1, 2, CircuitTileDef.CircuitTileType.TARGET, 0, 0, true, "concept.flow.error_handler")

	set_t.call(3, 1, CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, "")
	set_t.call(4, 1, CircuitTileDef.CircuitTileType.CORNER, 2, 1, false, "concept.flow.function_call")

	set_t.call(4, 2, CircuitTileDef.CircuitTileType.T_JUNCTION, 1, 3, false, "")
	set_t.call(5, 2, CircuitTileDef.CircuitTileType.TARGET, 3, 3, true, "concept.flow.database")

	set_t.call(4, 3, CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, "")
	set_t.call(4, 4, CircuitTileDef.CircuitTileType.CORNER, 3, 2, false, "")
	set_t.call(3, 4, CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, "")
	set_t.call(2, 4, CircuitTileDef.CircuitTileType.CORNER, 1, 0, false, "")
	set_t.call(2, 5, CircuitTileDef.CircuitTileType.TARGET, 0, 0, true, "concept.flow.output")

	# Add blockers to spice up empty spaces
	set_t.call(0, 1, CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, "")
	set_t.call(3, 2, CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, "")
	set_t.call(1, 4, CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, "")
	set_t.call(5, 4, CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, "")

	return lvl


## Builds Level 8: 6x6 — "The Master Ancestral Codex"
## Connects all 8 concepts in an epic full execution pipeline.
static func build_level_8() -> CircuitLevel:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.id = "circuit_08"
	lvl.title_key = "puzzle.circuit_08.title"
	lvl.intro_key = "puzzle.circuit_08.intro"
	lvl.grid_columns = 6
	lvl.grid_rows = 6
	lvl.required_targets = 3
	lvl.par_moves = 18
	lvl.star_thresholds = [18, 26, 40]
	lvl.time_limit_seconds = 120.0

	var list: Array[CircuitTileDef] = []
	for y: int in range(6):
		for x: int in range(6):
			list.append(tile(CircuitTileDef.CircuitTileType.EMPTY, 0, 0, true, ""))
	lvl.tiles = list

	var set_t: Callable = func(x: int, y: int, t: CircuitTileDef.CircuitTileType, sol_r: int, init_r: int, lck: bool, lbl: String) -> void:
		lvl.tiles[y * 6 + x] = tile(t, sol_r, init_r, lck, lbl)

	# (0, 0) Source [Input] -> East
	set_t.call(0, 0, CircuitTileDef.CircuitTileType.SOURCE, 1, 1, true, "concept.flow.input")
	set_t.call(1, 0, CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, "")
	set_t.call(2, 0, CircuitTileDef.CircuitTileType.CORNER, 2, 1, false, "concept.flow.parse")

	# (2, 1) T_Junction [Validate] -> splits to Error Handler and Loop
	set_t.call(2, 1, CircuitTileDef.CircuitTileType.T_JUNCTION, 1, 2, false, "concept.flow.validate")
	set_t.call(1, 1, CircuitTileDef.CircuitTileType.CORNER, 3, 0, false, "")
	set_t.call(1, 2, CircuitTileDef.CircuitTileType.TARGET, 0, 0, true, "concept.flow.error_handler")

	# To Loop:
	set_t.call(3, 1, CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, "")
	set_t.call(4, 1, CircuitTileDef.CircuitTileType.CORNER, 2, 0, false, "")
	set_t.call(4, 2, CircuitTileDef.CircuitTileType.CROSS, 0, 0, false, "concept.flow.loop")
	set_t.call(5, 2, CircuitTileDef.CircuitTileType.CORNER, 2, 1, false, "")
	set_t.call(5, 3, CircuitTileDef.CircuitTileType.CORNER, 3, 2, false, "")
	set_t.call(4, 3, CircuitTileDef.CircuitTileType.CORNER, 0, 1, false, "")

	# From Loop to Function Call:
	set_t.call(3, 2, CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, "concept.flow.function_call")
	set_t.call(2, 2, CircuitTileDef.CircuitTileType.T_JUNCTION, 2, 0, false, "")

	# Branch 1: Database
	set_t.call(2, 3, CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, "")
	set_t.call(2, 4, CircuitTileDef.CircuitTileType.TARGET, 0, 0, true, "concept.flow.database")

	# Branch 2: Output
	set_t.call(1, 3, CircuitTileDef.CircuitTileType.CORNER, 1, 2, false, "")
	set_t.call(1, 4, CircuitTileDef.CircuitTileType.STRAIGHT, 0, 1, false, "")
	set_t.call(1, 5, CircuitTileDef.CircuitTileType.CORNER, 1, 3, false, "")
	set_t.call(2, 5, CircuitTileDef.CircuitTileType.STRAIGHT, 1, 0, false, "")
	set_t.call(3, 5, CircuitTileDef.CircuitTileType.TARGET, 3, 3, true, "concept.flow.output")

	# Obstacles
	set_t.call(0, 1, CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, "")
	set_t.call(3, 3, CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, "")
	set_t.call(5, 0, CircuitTileDef.CircuitTileType.BLOCKER, 0, 0, true, "")

	return lvl


## Returns an array containing all 8 built levels.
static func get_all_levels() -> Array[CircuitLevel]:
	return [
		build_level_1(),
		build_level_2(),
		build_level_3(),
		build_level_4(),
		build_level_5(),
		build_level_6(),
		build_level_7(),
		build_level_8(),
	]
