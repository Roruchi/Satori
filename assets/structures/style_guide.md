# Structure Sprite Style Guide

## Camera

- Camera: high top-down 2D structure sprite
- Directions: down
- In-game display size: 128x128 source frame, scalable to current hex structure marker size
- Frame size: 128x128 px
- Anchor rule: structure footprint stays centered; visual mass sits slightly above center to leave room for tile overlap

## Shape Language

- Silhouette: compact readable landmark/building shapes for hex-grid play
- Proportions: squat garden structures with strong top-down footprint readability
- Line weight: refined hand-painted pixel-art-inspired edges
- Detail density: moderate large-form detail, no noisy micro-texture
- Animation energy: static completed structures; future variants may add subtle idle glow or construction states

## Color And Light

- Palette: muted stone, aged cedar, moss, warm clay, pale water-blue, soft gold accents
- Shadow color: cool transparent slate where needed inside the sprite only
- Highlight color: warm cream and gold accents
- Magic/VFX accents: minimal shrine glow or lantern warmth, readable without UI overlays
- Forbidden colors: chroma-key green inside final sprites, UI blue, pure white outlines

## Materials

- Stone/wood: weathered, hand-painted, soft edge highlights
- Water/glow: restrained, symbolic, no large transparent smoke effects
- Cloth/paper: warm cream, low-noise texture

## Sheet Rules

- Default animations: idle
- Frame counts: idle 1
- FPS: idle 1
- Background/alpha: transparent PNG frames generated from imagegen chroma-key sources
- Export format: source atlas, sliced PNG frame, QA contact sheet, Godot SpriteFrames .tres
- Engine target: Godot 4.x AnimatedSprite2D or texture-driven structure renderer

## QA Checklist

- Reads at actual in-game scale
- Same identity as structure metadata
- No frame crops
- No scale jumps
- Footprint/anchor stable
- Alpha/background clean
