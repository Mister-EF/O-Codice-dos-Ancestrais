## One card in a shuffled deck; partners share pair_id but have different types.
class_name MemoryCardData
extends RefCounted

enum CardType { NAME, DEFINITION, ICON }

var pair_id: StringName = &""
var card_type: CardType = CardType.NAME
var concept: ConceptData
