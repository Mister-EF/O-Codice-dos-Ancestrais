## Authored map territory, unlock conditions, and ordered puzzle entries.
class_name TerritoryData
extends Resource

enum RecommendedMechanic { MEMORY, CIRCUIT, RUNES, MIXED }
enum FactionAffinity { NONE, PIRATES, SCHOLARS, MERCENARIES }

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
@export var map_position: Vector2 = Vector2(0.5, 0.5)
@export var placeholder_icon: Texture2D
@export var placeholder_locked_icon: Texture2D
@export var puzzle_ids: Array[TerritoryPuzzleEntry] = []
@export var previous_territory_ids: Array[StringName] = []
@export var minimum_total_stars: int = 0
@export var faction_affinity: FactionAffinity = FactionAffinity.NONE
@export var recommended_mechanic: RecommendedMechanic = RecommendedMechanic.MIXED
