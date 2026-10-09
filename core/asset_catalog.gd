## AssetCatalog — Central registry of all placeholder asset slots.
## Artists swap assets here in one place; code falls back gracefully when null.
class_name AssetCatalog
extends Resource


# ── UI Textures ──────────────────────────────────────────────────────────────

## Generic button background texture (9-patch or AtlasTexture expected).
@export var button_texture: Texture2D

## Generic panel/card background texture.
@export var panel_texture: Texture2D

## Main menu background texture.
@export var menu_background: Texture2D


# ── Audio ────────────────────────────────────────────────────────────────────

## Click / tap SFX for buttons.
@export var sfx_ui_click: AudioStream

## Main menu music track.
@export var music_menu: AudioStream

## World map music track.
@export var music_world_map: AudioStream

## Generic puzzle music track (individual puzzles may override).
@export var music_puzzle: AudioStream

## Ambient track used on the world map.
@export var music_map_ambience: AudioStream

## Optional transition overlay artwork.
@export var placeholder_transition_texture: Texture2D

## Optional main-menu title/logo artwork.
@export var placeholder_game_logo: Texture2D

## Optional main-menu backdrop.
@export var placeholder_menu_background: Texture2D

## Optional world-map backdrop.
@export var placeholder_map_background: Texture2D

## Optional territory marker art.
@export var placeholder_territory_icon: Texture2D

## Optional locked-territory marker art.
@export var placeholder_territory_locked_icon: Texture2D

## Optional visual burst shown when a territory unlocks.
@export var placeholder_unlock_vfx: Texture2D


# ── Faction Shared ───────────────────────────────────────────────────────────

## Fallback faction icon if the per-faction one is null.
@export var faction_icon_fallback: Texture2D

## Fallback faction banner if the per-faction one is null.
@export var faction_banner_fallback: Texture2D
