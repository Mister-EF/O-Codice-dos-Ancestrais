## Outcome of one attempted card flip.
class_name FlipResult
extends RefCounted

var accepted: bool = false
var card_index: int = -1
var pair_indices: Array[int] = []
var matched: bool = false
var mismatch: bool = false
var completed: bool = false
var failed: bool = false
var state: int = 0
