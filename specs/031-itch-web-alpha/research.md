# Research: itch.io Web Alpha

## Decision: Build on existing Web preset

**Rationale**: `export_presets.cfg` already contains a Web preset targeting `build/web/index.html`.

## Decision: Validate assets explicitly

**Rationale**: Runtime CSV and generated assets are critical for rituals/materials. Web export issues often come from missing include filters.

## Decision: Keep itch.io as a packaging step, not a deploy automation requirement

**Rationale**: Closed alpha can begin with a reproducible upload package before automating uploads.

## Decision: Disable PWA for first alpha

**Rationale**: The first itch.io alpha should reduce platform variables. PWA can be enabled later if browser-save testing proves it is needed.

## Decision: Use a restricted manual itch.io alpha package

**Rationale**: Channel naming is a release-management detail. The repository requirement is a reproducible restricted upload package with versioned notes, not automated public publishing.

## Decision: No placeholders on the primary alpha path

**Rationale**: The obvious alpha path should feel polished. Web packaging must exclude placeholder art, audio, icon, and UI assets from the primary path and release shell. Non-primary placeholder assets are acceptable when the related content is hidden, gated, or clearly outside the intended tester route.
