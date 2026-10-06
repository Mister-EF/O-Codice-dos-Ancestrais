## Pure memory-board rules. This class has no Node/autoload dependencies.
class_name MemoryBoardLogic
extends RefCounted

enum BoardState { IDLE, ONE_FACE_UP, RESOLVING, COMPLETE }

var deck: Array[MemoryCardData] = []
var state: BoardState = BoardState.IDLE
var moves: int = 0
var hints_used: int = 0
var matched_pairs: Dictionary = {}
var face_up_indices: Array[int] = []
var effective_max_moves: int = 0
var effective_time_limit_seconds: float = 0.0
var hint_allowance: int = 1
var level: MemoryBoardLevel
var failed: bool = false


func setup(
	p_level: MemoryBoardLevel,
	seed: int = -1,
	faction_bonus: FactionData = null
) -> bool:
	if p_level == null:
		push_error("MemoryBoardLogic: level must not be null.")
		return false
	if p_level.grid_columns < 1 or p_level.grid_rows < 1 or p_level.concept_ids.is_empty():
		push_error("MemoryBoardLogic: level grid and concept list must be non-empty.")
		return false
	if p_level.grid_columns * p_level.grid_rows != p_level.concept_ids.size() * 2:
		push_error("MemoryBoardLogic: level grid must contain exactly two cards per concept.")
		return false
	if p_level.max_moves < 0 or p_level.time_limit_seconds < 0.0:
		push_error("MemoryBoardLogic: move and time limits cannot be negative.")
		return false
	if p_level.three_star_moves > 0 and p_level.two_star_moves > 0 and p_level.three_star_moves > p_level.two_star_moves:
		push_error("MemoryBoardLogic: three-star threshold must not exceed the two-star threshold.")
		return false
	if p_level.two_star_moves > 0 and p_level.one_star_moves > 0 and p_level.two_star_moves > p_level.one_star_moves:
		push_error("MemoryBoardLogic: two-star threshold must not exceed the one-star threshold.")
		return false
	var unique_concepts: Dictionary = {}
	for concept_id: StringName in p_level.concept_ids:
		if concept_id == &"" or unique_concepts.has(concept_id):
			push_error("MemoryBoardLogic: concept ids must be non-empty and unique.")
			return false
		unique_concepts[concept_id] = true

	level = p_level
	state = BoardState.IDLE
	moves = 0
	hints_used = 0
	matched_pairs.clear()
	face_up_indices.clear()
	failed = false
	effective_max_moves = p_level.max_moves
	effective_time_limit_seconds = p_level.time_limit_seconds
	if faction_bonus != null:
		if effective_max_moves > 0:
			effective_max_moves += maxi(0, faction_bonus.extra_flip_allowance)
		if effective_time_limit_seconds > 0.0:
			effective_time_limit_seconds += maxf(0.0, faction_bonus.time_bonus_seconds)
	hint_allowance = maxi(1, ceili(float(p_level.concept_ids.size()) / 4.0))

	deck.clear()
	for concept_id: StringName in p_level.concept_ids:
		var path: String = "res://data/concepts/%s.tres" % String(concept_id)
		var concept: ConceptData = load(path) as ConceptData
		if concept == null:
			push_error("MemoryBoardLogic: unable to load concept resource '%s'." % path)
			deck.clear()
			return false
		var pair_index: int = floori(float(deck.size()) / 2.0)
		var definition_type: MemoryCardData.CardType = _definition_type_for(p_level, pair_index)
		var name_card: MemoryCardData = MemoryCardData.new()
		name_card.pair_id = concept.id
		name_card.card_type = MemoryCardData.CardType.NAME
		name_card.concept = concept
		var partner_card: MemoryCardData = MemoryCardData.new()
		partner_card.pair_id = concept.id
		partner_card.card_type = definition_type
		partner_card.concept = concept
		deck.append(name_card)
		deck.append(partner_card)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	for index: int in range(deck.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var card: MemoryCardData = deck[index]
		deck[index] = deck[swap_index]
		deck[swap_index] = card
	return true


func flip(index: int) -> FlipResult:
	var result: FlipResult = FlipResult.new()
	result.card_index = index
	if state == BoardState.COMPLETE or state == BoardState.RESOLVING:
		result.state = state
		result.failed = failed
		return result
	if index < 0 or index >= deck.size() or face_up_indices.has(index):
		result.state = state
		return result
	if matched_pairs.has(deck[index].pair_id):
		result.state = state
		return result

	result.accepted = true
	face_up_indices.append(index)
	if face_up_indices.size() == 1:
		state = BoardState.ONE_FACE_UP
	else:
		moves += 1
		var first_index: int = face_up_indices[0]
		var first: MemoryCardData = deck[first_index]
		var second: MemoryCardData = deck[index]
		if first.pair_id == second.pair_id and first.card_type != second.card_type:
			matched_pairs[first.pair_id] = true
			result.matched = true
			result.pair_indices = [first_index, index]
			face_up_indices.clear()
			if matched_pairs.size() == level.concept_ids.size():
				state = BoardState.COMPLETE
			else:
				state = BoardState.IDLE
		else:
			result.mismatch = true
			result.pair_indices = [first_index, index]
			state = BoardState.RESOLVING
		if effective_max_moves > 0 and moves > effective_max_moves:
			failed = true
			state = BoardState.COMPLETE
	result.completed = state == BoardState.COMPLETE and not failed
	result.failed = failed
	result.state = state
	return result


func resolve_mismatch() -> void:
	if state != BoardState.RESOLVING:
		return
	face_up_indices.clear()
	state = BoardState.IDLE


func reveal_hint_pair() -> Array[int]:
	var indices: Array[int] = []
	if state == BoardState.COMPLETE or state == BoardState.RESOLVING or hints_used >= hint_allowance:
		return indices
	var examined_pairs: Dictionary = {}
	for card: MemoryCardData in deck:
		var pair_id: StringName = card.pair_id
		if examined_pairs.has(pair_id):
			continue
		examined_pairs[pair_id] = true
		if matched_pairs.has(pair_id):
			continue
		var pair: Array[int] = []
		for index: int in range(deck.size()):
			if deck[index].pair_id == pair_id:
				pair.append(index)
		if pair.size() == 2:
			indices = pair
			hints_used += 1
			return indices
	return indices


func calculate_stars() -> int:
	if state != BoardState.COMPLETE or failed:
		return 0
	if level.three_star_moves > 0 and moves <= level.three_star_moves:
		return 3
	if level.two_star_moves > 0 and moves <= level.two_star_moves:
		return 2
	if (
		level.one_star_moves == 0
		or moves <= level.one_star_moves
		or (effective_max_moves > level.max_moves and moves <= effective_max_moves)
	):
		return 1
	return 0


func is_pair_matched(pair_id: StringName) -> bool:
	return matched_pairs.has(pair_id)


func _definition_type_for(p_level: MemoryBoardLevel, pair_index: int) -> MemoryCardData.CardType:
	match p_level.pair_mode:
		MemoryBoardLevel.PairMode.NAME_TO_ICON:
			return MemoryCardData.CardType.ICON
		MemoryBoardLevel.PairMode.MIXED:
			return MemoryCardData.CardType.ICON if pair_index % 2 == 1 else MemoryCardData.CardType.DEFINITION
		_:
			return MemoryCardData.CardType.DEFINITION
