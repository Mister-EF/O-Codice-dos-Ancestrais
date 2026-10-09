## Pure state logic engine for the Memory Board puzzle.
class_name MemoryBoardLogic
extends RefCounted

enum State { IDLE, ONE_FACE_UP, RESOLVING, COMPLETE }

class CardItem extends RefCounted:
	var index: int = 0
	var pair_id: StringName = &""
	var concept_id: StringName = &""
	var card_type: String = "name" # "name", "definition", "icon"
	var is_face_up: bool = false
	var is_matched: bool = false

var cards: Array[CardItem] = []
var state: State = State.IDLE
var moves: int = 0
var matched_pairs: int = 0
var total_pairs: int = 0
var first_selected_index: int = -1
var second_selected_index: int = -1
var level_ref: MemoryBoardLevel = null
var extra_flips_bonus: int = 0

## Initialize game board from level definition and optional seed.
func load_level(level: MemoryBoardLevel, rng_seed: int = -1, extra_flips: int = 0) -> void:
	level_ref = level
	extra_flips_bonus = extra_flips
	cards.clear()
	moves = 0
	matched_pairs = 0
	state = State.IDLE
	first_selected_index = -1
	second_selected_index = -1
	
	var pair_count: int = (level.grid_columns * level.grid_rows) / 2
	total_pairs = pair_count
	
	var raw_cards: Array[CardItem] = []
	for i: int in range(pair_count):
		var concept_id: StringName = level.concept_ids[i % level.concept_ids.size()]
		var pair_id: StringName = StringName(str(concept_id) + "_" + str(i))
		
		# Card A (Name)
		var card_a: CardItem = CardItem.new()
		card_a.pair_id = pair_id
		card_a.concept_id = concept_id
		card_a.card_type = "name"
		raw_cards.append(card_a)
		
		# Card B (Definition or Icon)
		var card_b: CardItem = CardItem.new()
		card_b.pair_id = pair_id
		card_b.concept_id = concept_id
		card_b.card_type = "definition" if level.pair_mode == MemoryBoardLevel.PairMode.NAME_TO_DEFINITION else "icon"
		raw_cards.append(card_b)
		
	# Shuffle raw_cards
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
		
	# Fisher-Yates shuffle
	for i: int in range(raw_cards.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: CardItem = raw_cards[i]
		raw_cards[i] = raw_cards[j]
		raw_cards[j] = temp
		
	for idx: int in range(raw_cards.size()):
		raw_cards[idx].index = idx
		cards.append(raw_cards[idx])

## Flip card at index. Returns result dictionary.
func flip(index: int) -> Dictionary:
	if index < 0 or index >= cards.size():
		return {"success": false, "reason": "out_of_bounds"}
	if state == State.RESOLVING or state == State.COMPLETE:
		return {"success": false, "reason": "busy"}
		
	var card: CardItem = cards[index]
	if card.is_matched or card.is_face_up:
		return {"success": false, "reason": "already_open"}
		
	card.is_face_up = true
	
	if state == State.IDLE:
		first_selected_index = index
		state = State.ONE_FACE_UP
		return {
			"success": true,
			"matched": false,
			"state": state,
			"card_index": index
		}
	elif state == State.ONE_FACE_UP:
		second_selected_index = index
		moves += 1
		var first_card: CardItem = cards[first_selected_index]
		
		if first_card.pair_id == card.pair_id:
			first_card.is_matched = true
			card.is_matched = true
			matched_pairs += 1
			var pair_idx: Array[int] = [first_selected_index, second_selected_index]
			first_selected_index = -1
			second_selected_index = -1
			
			if matched_pairs >= total_pairs:
				state = State.COMPLETE
			else:
				state = State.IDLE
				
			return {
				"success": true,
				"matched": true,
				"pair_indices": pair_idx,
				"state": state,
				"complete": (state == State.COMPLETE)
			}
		else:
			state = State.RESOLVING
			return {
				"success": true,
				"matched": false,
				"pair_indices": [first_selected_index, second_selected_index],
				"state": state
			}
			
	return {"success": false, "reason": "invalid_state"}

## Resolves a mismatch after delay in UI, changing state back to IDLE.
func resolve_mismatch() -> Array[int]:
	var indices: Array[int] = []
	if first_selected_index >= 0 and first_selected_index < cards.size():
		cards[first_selected_index].is_face_up = false
		indices.append(first_selected_index)
	if second_selected_index >= 0 and second_selected_index < cards.size():
		cards[second_selected_index].is_face_up = false
		indices.append(second_selected_index)
		
	first_selected_index = -1
	second_selected_index = -1
	if state == State.RESOLVING:
		state = State.IDLE
	return indices

## Calculate star rating (3, 2, 1, or 0) based on moves and level thresholds.
func calculate_stars() -> int:
	if level_ref == null or level_ref.star_thresholds.size() < 3:
		return 3
	var effective_moves: int = max(0, moves - extra_flips_bonus)
	var t3: int = level_ref.star_thresholds[0]
	var t2: int = level_ref.star_thresholds[1]
	var t1: int = level_ref.star_thresholds[2]
	
	if effective_moves <= t3:
		return 3
	elif effective_moves <= t2:
		return 2
	elif effective_moves <= t1:
		return 1
	return 1 # Solved always grants at least 1 star if completed

## Returns array of 2 indices representing an unmatched matching pair.
func get_hint_pair() -> Array[int]:
	var unmatched_by_pair: Dictionary = {}
	for card: CardItem in cards:
		if not card.is_matched:
			if not unmatched_by_pair.has(card.pair_id):
				unmatched_by_pair[card.pair_id] = []
			(unmatched_by_pair[card.pair_id] as Array).append(card.index)
			
	for pair_id: StringName in unmatched_by_pair.keys():
		var idx_list: Array = unmatched_by_pair[pair_id]
		if idx_list.size() == 2:
			return [int(idx_list[0]), int(idx_list[1])]
	return []
