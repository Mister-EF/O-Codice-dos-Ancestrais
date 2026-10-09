## FactionData — Data resource describing one of the three player factions.
## Stores localization keys (not raw text), visual placeholder slots, and
## numeric bonus values that puzzle logic can query.
class_name FactionData
extends Resource


## Unique faction identifier (e.g. &"pirates", &"scholars", &"mercenaries").
@export var id: StringName = &""

## Translation key for the faction's display name.
@export var name_key: String = ""

## Translation key for the faction's description.
@export var description_key: String = ""

## Translation key for the faction's gameplay bonus text.
@export var bonus_key: String = ""

## Placeholder icon texture for the faction (null until art team provides).
@export var placeholder_icon: Texture2D

## Placeholder banner texture for the faction (null until art team provides).
@export var placeholder_banner: Texture2D

## Placeholder theme music track for this faction / route (null until audio provided).
@export var placeholder_music: AudioStream

## Alias for placeholder_music for convenience.
var theme_music: AudioStream:
	get: return placeholder_music
	set(val): placeholder_music = val

## Primary color used for UI accents when this faction is selected.
@export var theme_color: Color = Color.WHITE

## Percentage discount on hint cost (0 = no discount).
@export var hint_discount: int = 0

## Extra seconds added to puzzle time limits.
@export var time_bonus_seconds: float = 0.0

## Extra card flip attempts allowed in memory-style puzzles.
@export var extra_flip_allowance: int = 0
