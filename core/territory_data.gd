## Territory data resource defining an unlockable region in the World Map.
class_name TerritoryData
extends Resource

enum RecommendedMechanic { MEMORY, CIRCUIT, RUNES, MIXED }

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
@export var map_position: Vector2 = Vector2.ZERO # Normalized (0..1)
@export var placeholder_icon: Texture2D = null
@export var placeholder_locked_icon: Texture2D = null
@export var puzzle_ids: Array[String] = [] # Ordered list of puzzle ids (e.g. ["memory_01", "circuit_01"])
@export var required_stars: int = 0 # Star threshold to unlock
@export var required_territory_id: StringName = &"" # Previous territory required
@export var faction_affinity: GameManager.Faction = GameManager.Faction.NONE
@export var recommended_mechanic: RecommendedMechanic = RecommendedMechanic.MIXED
