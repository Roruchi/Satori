# Red Fox Sprite Style Guide

## Camera

- Camera: high top-down 2D creature sprite
- Directions: down, left, right, up
- In-game display size: 64x64 source frame, scalable to the current spirit marker size
- Frame size: 64x64 px
- Anchor rule: body center stays centered; lower body/ground contact sits slightly below center

## Shape Language

- Silhouette: compact fox with oversized fluffy tail, triangular ears, small paws
- Proportions: cute spirit animal, readable at small hex-tile scale
- Line weight: refined hand-painted pixel-art-inspired edges
- Detail density: moderate fur detail, no noisy micro-texture
- Animation energy: subtle idle, gentle walk, slow curled sleep breathing

## Color And Light

- Palette: red-orange fur, cream muzzle/chest/tail tip, dark brown paws and ear tips
- Highlight color: warm orange fur highlights
- Magic/VFX accents: faint amber spirit wisps and sparkles
- Forbidden colors: chroma-key green inside the final sprite, UI blue, pure white outlines

## Sheet Rules

- Default animations: idle, walk, sleep
- Frame counts: idle 4, walk 6, sleep 4
- FPS: idle 6, walk 10, sleep 5
- Background/alpha: transparent PNG frames generated from imagegen chroma-key sources
- Export format: sliced PNG frames plus Godot SpriteFrames .tres
- Engine target: Godot 4.x AnimatedSprite2D

## QA Checklist

- Reads at actual in-game scale
- Same identity in every direction
- No frame crops
- No scale jumps
- Feet/anchor stable
- Loops cleanly
- Alpha/background clean
