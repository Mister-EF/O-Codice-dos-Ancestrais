## AssetCatalog — Central registry of all placeholder and integrated asset slots.
## Artists swap assets here in one place; code falls back gracefully when null.
class_name AssetCatalog
extends Resource


# ── UI & Screen Textures ─────────────────────────────────────────────────────

## Generic button background texture (botao.png).
@export var button_texture: Texture2D

## Generic panel/card background texture.
@export var panel_texture: Texture2D

## Default background wallpaper for menus, screens, and maps (fundo-jogo.png).
@export var menu_background: Texture2D

## Optional main-menu backdrop alias.
@export var placeholder_menu_background: Texture2D

## Main cover art / title image for the main menu (capa - jogo.png).
@export var cover_art: Texture2D

## Optional main-menu title/logo artwork alias.
@export var placeholder_game_logo: Texture2D

## Door / passage / level gate element texture (portas-exemplo.png).
@export var door_texture: Texture2D


# ── Memory Card Puzzle Textures ──────────────────────────────────────────────

## Memory card frame texture (moldura-carta.png).
@export var card_frame: Texture2D

## Memory card back texture (verso-carta.png).
@export var card_back: Texture2D


# ── Tech Concept Icons ───────────────────────────────────────────────────────

## Icon for Docker tech concept (simbolo-docker.png).
@export var docker_icon: Texture2D

## Icon for Git tech concept (simbolo-git.png).
@export var git_icon: Texture2D


# ── Audio Buses & Streams ────────────────────────────────────────────────────

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


# ── Faction Shared Placeholders ──────────────────────────────────────────────

## Fallback faction icon if the per-faction one is null.
@export var faction_icon_fallback: Texture2D

## Fallback faction banner if the per-faction one is null.
@export var faction_banner_fallback: Texture2D


# ── Gameplay Visual Placeholders ─────────────────────────────────────────────

@export var placeholder_transition_texture: Texture2D
@export var placeholder_map_background: Texture2D
@export var placeholder_territory_icon: Texture2D
@export var placeholder_territory_locked_icon: Texture2D
@export var placeholder_unlock_vfx: Texture2D
@export var circuit_node_placeholder: Texture2D
@export var rune_stone_placeholder: Texture2D
@export var map_territory_placeholder: Texture2D
