# Implementation Plan — 011 Ambient Soundscape (Generative & Spirit-Driven)

## Overview

Adds a `SoundscapeEngine` autoload that blends looping biome ambient beds based on real-time camera viewport composition, contributes per-spirit rhythmic layers when spirits are in view, queues discovery stingers, and exposes master volume / mute controls.

## Tech Stack

- **Language**: GDScript 4.x
- **Engine APIs**: `AudioStreamPlayer`, `AudioStreamOggVorbis`, `Camera2D`, `Viewport`
- **New files**: `src/audio/soundscape_engine.gd`, `src/audio/spirit_rhythm_catalog.gd`
- **Modified files**: `project.godot` (autoload), `src/spirits/spirit_service.gd` (signal wire)
- **Audio assets**: `.ogg` placeholders at `res://assets/audio/biomes/` and `res://assets/audio/spirits/` — not committed; engine loads gracefully when absent

## Architecture

```
SoundscapeEngine (autoload Node)
├── BiomeBeds: 14 × AudioStreamPlayer — one per BiomeType.Value (0–13)
│     volumes lerped toward viewport biome composition weights
├── NeutralWind: AudioStreamPlayer — volume = 1 − Σ biome_weights
├── SpiritRhythms: Dict[spirit_id → AudioStreamPlayer]
│     • activated when spirit spawn coord is within camera viewport
│     • capped at MAX_SPIRIT_LAYERS (5) — oldest spirits muted when exceeded
│     • volume normalised via SpiritRhythmCatalog.stacked_volume_db()
└── StingerPlayer: single AudioStreamPlayer — plays stingers sequentially from queue (max 5)
```

### SpiritRhythmCatalog

Static data class mapping `spirit_id → {audio_key, path, volume_db, layer}`.  
`layer` ∈ {`hihat`, `drum`, `melodic`, `texture`}.

Key rhythmic identities:

| Spirit | Role | Layer |
|---|---|---|
| spirit_mist_stag | hi-hat pace | hihat |
| spirit_boreal_wolf | deep drums | drum |
| spirit_sky_whale | resonant drone | texture |
| spirit_frost_owl | soft chimes | melodic |
| spirit_stone_golem | deep thud | drum |
| spirit_mountain_goat | rock knock | drum |
| spirit_kagutsuchi | fire crackle | texture |
| spirit_fujin | wind pulse | texture |
| spirit_oyamatsumi | earth pulse | drum |
| spirit_suijin | rain drop | melodic |

### Volume normalisation formula

```
stacked_db = base_db − 3.0 × log₂(active_count)
```

At 4 spirits: each layer is −6 dB relative to solo, ensuring the mix stays calming.

## Viewport Sampling

Each `SAMPLE_INTERVAL` (0.1 s):
1. Read `Camera2D.get_screen_center_position()` + `zoom` + viewport size → world `Rect2`
2. Iterate `GameState.grid.tiles` → count tiles per biome inside rect
3. `biome_weight[b] = count[b] / total_tiles`
4. `neutral_weight = max(0, 1 − Σ weights)`
5. All `AudioStreamPlayer.volume_db` lerped toward targets at `BIOME_LERP_RATE = 3.0`

## Spirit Visibility

Each sample tick:
1. For each active spirit, convert `spawn_coord` → world pixel
2. Expand viewport rect by spirit's wander radius
3. Spirits whose position falls inside the expanded rect → `in_view`
4. Keep only the most recent `MAX_SPIRIT_LAYERS` in-view spirits as active rhythm layers
5. Apply `stacked_volume_db()` to each active spirit's volume target

## File Map

```
src/audio/
  soundscape_engine.gd       # autoload — main engine
  spirit_rhythm_catalog.gd   # static data — spirit audio map + stacking formula

src/spirits/
  spirit_service.gd          # +_connect_soundscape() deferred call in _ready()

project.godot                # +SoundscapeEngine autoload

tests/unit/
  test_soundscape_engine.gd  # unit tests for catalog + engine API
```
