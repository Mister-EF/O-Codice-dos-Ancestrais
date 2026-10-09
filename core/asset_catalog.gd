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

## World map ambient background audio.
@export var ambience_world_map: AudioStream

## Sound effect played on territory unlock celebration.
@export var sfx_territory_unlocked: AudioStream

## Generic puzzle music track (individual puzzles may override).
@export var music_puzzle: AudioStream


# ── Faction Shared ───────────────────────────────────────────────────────────

## Fallback faction icon if the per-faction one is null.
@export var faction_icon_fallback: Texture2D

## Fallback faction banner if the per-faction one is null.
@export var faction_banner_fallback: Texture2D
