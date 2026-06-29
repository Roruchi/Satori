# Alpha Content Audit

Run date: 2026-06-29

## Included Primary Content

| Item | Type | Purpose | Current wiring |
|------|------|---------|----------------|
| Meadow Seed (`recipe_fu`) | Seed | First placement and Living Wood source | Runtime CSV, seed ritual catalog, save/load through seed pouch and placed tiles |
| Living Wood (`living_wood`) | Material | First harvest and structure input | Runtime material CSV, material inventory, save/load |
| Red Fox (`spirit_red_fox`) | Spirit | First visitor, care loop, Fox Den ritual input | Spirit catalog, Codex, sprite assets, housing and save/load tests |
| Warm Hollow (`form_warm_hollow`) | Structure form | First shelter ritual | Runtime CSV, Codex, structure catalog, Meadow placement |
| Meadow Dwelling (`building_meadow_dwelling`) | Building | First Red Fox housing | Structure catalog, sprite asset, dwelling effect, save/load via placed tile metadata |
| Fox Den (`form_fox_den`, `building_fox_den`) | Structure form/building | First upgraded housing and Red-Fox-only Satori bonus | Runtime CSV, Codex, structure catalog, sprite asset, dwelling and Satori bonus effects |
| Dew Bowl (`form_dew_bowl`, `building_dew_bowl`) | Structure form/building | First helper/storage action | Runtime CSV, Codex, structure catalog, sprite asset, storage-cap effect |
| Wind Chime (`form_wind_chime`, `building_wind_chime`) | Structure form/building | First helper/auto-harvest action | Runtime CSV, Codex, structure catalog, sprite asset, auto-harvest effect |
| Mist Stag (`spirit_mist_stag`) | Spirit | Ku unlock milestone | Spirit catalog, Codex, sprite asset, Ku gift path |
| Ku Seed (`recipe_ku`) | Seed | Void separator placement | Runtime CSV, seed ritual catalog, save/load coverage |
| Sacred Stone Seed (`recipe_chi_ku`) | Seed | Chi+Ku calm-water island invitation surface | Runtime CSV, seed ritual catalog, save/load coverage |
| Suijin (`spirit_suijin`) | Spirit/Kami | Endgame alpha invitation proof | Spirit catalog, Codex, sprite asset, island-scoped invitation logic |

## Deferred Content

The broader spirit roster, advanced structures, additional kami, advanced components, restoration paths, and authored discovery stingers remain outside the closed alpha route. They may exist in catalogs or assets, but tester-facing guidance should route the player through the primary content above.

## Asset Audit

- Primary alpha path sprite and UI assets are present for Red Fox, Mist Stag, Suijin, Meadow Dwelling, Fox Den, Dew Bowl, Wind Chime, title/menu UI, material icons, and ritual input icons.
- Ambient biome audio and spirit rhythm identity are generated procedurally by `SoundscapeEngine`; authored `.ogg` files are optional.
- Discovery stingers are deferred for alpha and no longer map to absent placeholder files.
- No primary-path placeholder asset remains intentionally exposed by the audited runtime files.

## Validation

- `tests/unit/test_alpha_content_readiness.gd` covers the primary content list, structure effects/assets, Codex registration, menu version display, seed availability, spirit assets, and deferred discovery stingers.
