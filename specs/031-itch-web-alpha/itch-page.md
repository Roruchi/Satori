# itch.io Page Brief: Satori Restricted Web Alpha

Run date: 2026-06-28

## Publication Goal

Create a restricted or draft itch.io page that gives closed-alpha testers enough context to understand Satori before pressing play, then hosts the current browser-playable Web build.

The page is not verified until both are true:

- The page content is populated and reviewed on itch.io.
- The embedded HTML/Web build launches and passes the Web alpha smoke from the itch.io URL.

## Required Page Content

- Title: Satori
- Short description: A quiet garden ritual game about shaping biomes, caring for spirits, and inviting kami.
- Long description:
  - Explain the core loop: shape seeds, plant biomes, harvest materials, care for spirits, build homes, unlock Ku, and invite Suijin.
  - Set tester expectations: this is a closed alpha focused on the first playable spine, not the full spirit roster or final content breadth.
  - Mention persistence: saves are browser-local and should be checked with the same browser profile.
- Visuals:
  - At least one current title/menu image.
  - At least one current in-game garden image showing the alpha path.
  - No placeholder visuals from the primary alpha path or release shell.
  - Use the prepared page assets in `specs/031-itch-web-alpha/page-assets/`:
    - `satori-itch-cover.png` as the cover/key image.
    - `satori-itch-gallery-alpha-loop.png` as the first gallery image.
    - `satori-itch-banner.png` as a separate scenic wide page/banner image if itch.io accepts it cleanly. This banner intentionally has no logo text and should not repeat the cover/key art wordmark.
  - Recommended itch.io theme direction, inspired by polished reference pages:
    - Page background: deep garden teal `#0f2626`.
    - Content panel: warm paper `#efe3c5` or a close itch theme equivalent.
    - Primary text: dark moss `#173332`.
    - Accent/buttons/links: shrine gold `#d6b96d`.
    - Avoid default white/gray itch styling when possible; the page should read as a ritual garden before the tester presses play.
- Controls/how to play:
  - Mouse/touch select and place.
  - Use the ritual UI to combine elements into seeds/forms.
  - Save/reload should preserve progress in the same browser.
- Alpha scope:
  - Start a new garden.
  - Shape Wind/Fu into Meadow Seed.
  - Plant Meadow, harvest Living Wood, meet Red Fox, build housing, unlock Ku, and invite Suijin on the calm-water island path.
- Known issues:
  - PWA is disabled for the first Web alpha.
  - Browser-local saves are origin-specific; local builds and itch.io builds do not share saves.
  - Use the current `known-issues.md` notes for tester-facing caveats.
- Feedback route:
  - Record the actual feedback destination before inviting testers.
  - Ask testers whether the first ritual, housing loop, Ku unlock, Suijin invitation, and save/reload behavior were understandable.
- Build metadata:
  - Show or mention the visible build version: `0.1.0-alpha+20260627.1`.

## Draft Page Copy

### Short Description

A quiet garden ritual game about shaping biomes, caring for spirits, and inviting kami.

### About

Satori is a small, calm garden game built around ritual discovery. You shape elemental seeds, plant living biomes, harvest materials, care for visiting spirits, and build places that make the island feel more alive.

This restricted Web alpha focuses on the first complete playable spine. You should be able to start a new garden, shape Wind/Fu into a Meadow Seed, plant Meadow, harvest Living Wood, meet Red Fox, build a Warm Hollow, improve the first island, unlock Ku, and invite Suijin through the calm-water island path.

This is not the full content set yet. The goal of this alpha is to test whether the first path is understandable, satisfying, and safe to save and reload.

### Controls

- Use mouse or touch to select UI actions and place garden tiles.
- Use the ritual interface to combine elements into seeds and forms.
- Continue in the same browser profile when testing save/reload behavior.

### Closed Alpha Notes

- Saves are stored by the browser for this specific itch.io page.
- Reloading the same page in the same browser should preserve alpha-critical progress.
- Local development builds and itch.io builds use different browser origins and do not share saves.
- PWA behavior is disabled for this first Web alpha.

### What To Try

- Did the first ritual make sense?
- Did Meadow planting and Living Wood harvesting feel clear?
- Did Red Fox and its housing need feel readable?
- Did Ku and the Suijin invitation feel like a special milestone?
- Did save/reload preserve your garden as expected?

## Verification Checklist

- [ ] Page URL is recorded in `evidence.md`.
- [ ] Access mode is Draft or Restricted.
- [ ] Page has the short description, long description, controls, alpha scope, known issues, feedback route, build version, and visuals.
- [ ] Current Web build is uploaded as HTML/browser-playable.
- [ ] Actual itch.io URL launches the title screen.
- [ ] Actual itch.io URL passes new-game, first ritual, first placement, and same-browser reload smoke.
