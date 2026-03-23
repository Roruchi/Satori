# Feature Specification: Camera and Mobile Navigation

**Feature Branch**: `010-camera-mobile-nav`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Touch-first camera with momentum panning and mobile thumb-zone navigation"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Momentum Panning (Priority: P1)

The player drags a single finger to move the camera around the garden. When they lift their finger the view continues to drift in the drag direction, decelerating organically to a full stop. The feel is fluid and tactile — like sliding a physical object across a smooth surface.

**Why this priority**: Panning is the primary navigation interaction. The entire game is experienced through camera movement. If panning feels unresponsive or sticky the game is unpleasant to use regardless of content quality.

**Independent Test**: On a device, perform a fast swipe across the screen and lift the finger. Verify the camera continues to move after finger lift and gradually decelerates to a stop over approximately 0.5–1.5 seconds. Verify a slow drag with an abrupt stop produces little or no momentum drift.

**Acceptance Scenarios**:

1. **Given** the camera is at rest, **When** the player performs a fast single-finger drag and lifts their finger, **Then** the camera continues moving in the drag direction and decelerates smoothly to a complete stop within 0.5–2.0 seconds.
2. **Given** the camera is drifting from momentum, **When** the player places a finger on screen, **Then** the momentum drift stops immediately and the camera follows the new finger position.
3. **Given** the player performs a slow deliberate drag and releases, **When** the finger is lifted, **Then** the post-release drift velocity is proportionally low — the momentum reflects the actual drag speed, not a fixed constant.
4. **Given** the camera is at rest, **When** the player performs multiple rapid swipes in the same direction, **Then** each new swipe adds to or replaces the in-progress velocity rather than teleporting the camera.

---

### User Story 2 - Pinch-to-Zoom (Priority: P1)

The player places two fingers on screen and pinches them together or spreads them apart to zoom the garden in or out. Zoom respects a minimum and maximum limit and does not overshoot those limits regardless of pinch speed.

**Why this priority**: Zoom is the second primary navigation interaction. Without zoom the player cannot see both the detail of individual tiles and the large-scale structure of their garden in the same session.

**Independent Test**: Begin a slow pinch-out gesture and verify the camera zooms in. Continue pinching beyond what would normally be the maximum zoom level. Verify the camera stops at the maximum and does not zoom further even if the pinch gesture continues.

**Acceptance Scenarios**:

1. **Given** the camera is at normal zoom, **When** the player spreads two fingers apart (pinch out), **Then** the garden zooms in (tiles appear larger) proportionally to the spread distance.
2. **Given** the camera is at normal zoom, **When** the player pinches two fingers together (pinch in), **Then** the garden zooms out (tiles appear smaller) proportionally to the pinch distance.
3. **Given** the camera is at the maximum zoom-in limit, **When** the player continues spreading fingers further, **Then** the camera does not zoom in further; zoom level is clamped at the maximum.
4. **Given** the camera is at the minimum zoom-out limit, **When** the player continues pinching further, **Then** the camera does not zoom out further; zoom level is clamped at the minimum.

---

### User Story 3 - Double-Tap Re-Centre (Priority: P2)

A quick double-tap anywhere on the screen re-centres the camera on the Origin tile at grid coordinate (0,0). This gives the player a reliable "home base" navigation shortcut when they have panned far into the garden.

**Why this priority**: Players who have explored far from the origin can easily become lost in an infinite grid. Double-tap re-centre provides a fast, learnable escape hatch. It is lower priority than basic panning/zoom because the garden is still navigable without it.

**Independent Test**: Pan the camera far from the origin so that tile (0,0) is not visible. Double-tap anywhere on screen. Verify the camera moves to centre on (0,0) within one frame and that tile (0,0) is now centred in the viewport.

**Acceptance Scenarios**:

1. **Given** the camera is far from the origin, **When** the player double-taps anywhere on the screen, **Then** the camera re-centres on tile (0,0) within one frame of the gesture being recognised.
2. **Given** the camera is already centred on (0,0), **When** the player double-taps, **Then** no visible movement occurs (camera stays centred).
3. **Given** the camera is mid-momentum drift, **When** the player double-taps, **Then** momentum is cancelled and the camera re-centres on (0,0) immediately.

---

### User Story 4 - Thumb-Zone UI Layout (Priority: P3)

All interactive UI elements — the tile type selector and the settings button — are positioned at the bottom of the screen in portrait orientation, reachable with either thumb without the player shifting their hand grip on a standard phone.

**Why this priority**: Mobile-first design is a core project constraint. Placing buttons outside the natural thumb arc forces a two-handed grip or awkward hand shuffle, degrading the calm, one-handed meditation experience the game targets.

**Independent Test**: On a standard phone (screen diagonal 6.0–6.7 inches, 19:9 ratio), hold the device in one hand in portrait mode with the thumb resting naturally. Verify every interactive UI element is within comfortable thumb reach without any hand position adjustment.

**Acceptance Scenarios**:

1. **Given** the game is running in portrait mode, **When** the player holds the phone in one hand, **Then** the tile selector strip and the settings button are both within the bottom 30% of the screen height and reachable with a natural thumb arc.
2. **Given** the settings panel is open, **When** the player uses only a thumb to interact with it, **Then** all settings controls (volume sliders, toggles) are reachable within the thumb-zone without repositioning the hand.
3. **Given** a discovery notification appears at the top of the screen, **When** the player dismisses it, **Then** the dismiss control is either at the top (reachable with the other thumb) or redundantly dismissible by tapping anywhere — no modal block requires a difficult reach.

---

### Edge Cases

- **Panning far from the origin**: The camera should apply soft resistance (reduced pan speed) as it approaches the boundary of the current garden bounding box extended by a configurable padding (e.g., 20 tiles). The camera must never hard-lock; it should just feel increasingly sluggish near the edge.
- **Momentum carrying the camera past the garden edge**: If momentum would carry the camera beyond the soft-resistance boundary, the velocity is damped exponentially as the distance past the boundary grows. On release from that position the camera gently springs back toward the garden.
- **Simultaneous pan and pinch gestures**: When a second finger touches down during an active pan, the system transitions to pinch-zoom mode; the pan velocity is discarded. When the second finger lifts, the system re-enters single-finger pan mode with zero initial momentum.
- **Very fast pinch past zoom limits**: A fast pinch gesture that mathematically overshoots the zoom clamp must be hard-clamped at the limit in the same frame; the zoom must not briefly exceed the limit before snapping back.
- **Double-tap misidentified as two single taps**: The gesture recogniser must distinguish a double-tap from two slow successive taps (threshold: two taps within 300ms on approximately the same screen position). Slow taps that might also be tile placements must not accidentally re-centre the camera.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST respond to single-finger drag gestures to pan the camera across the garden
- **FR-002**: System MUST apply momentum to panning so the camera continues to drift after the finger is lifted, decelerating smoothly to rest; drift duration and deceleration curve MUST be tunable via exported parameters
- **FR-003**: System MUST respond to two-finger pinch gestures to zoom the camera in and out proportionally to the pinch scale delta
- **FR-004**: System MUST enforce configurable minimum and maximum zoom limits, clamping zoom hard at those values with no overshoot
- **FR-005**: System MUST re-centre the camera on the Origin tile (0,0) when a double-tap gesture is detected (two taps within 300ms at approximately the same position)
- **FR-006**: System MUST apply soft exponential resistance to camera movement when the camera approaches or exceeds the garden's bounding edge, without ever hard-locking movement
- **FR-007**: System MUST trigger haptic feedback on tile placement and discovery events when haptics are enabled (setting sourced from spec 013)
- **FR-008**: All interactive UI elements (tile selector, settings button) MUST be positioned within the bottom 30% of the screen height in portrait orientation to remain within natural thumb reach

### Key Entities

- **CameraState**: current world-space position (Vector2), current zoom level (float), current pan velocity (Vector2) used for momentum calculations
- **GardenBounds**: the axis-aligned bounding box (min/max grid coordinates) of all placed tiles, used to compute the soft-resistance edge zone; updated whenever a new tile is placed

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Camera panning feels natural — after a fast swipe the momentum drift decelerates smoothly with no sudden stop, and a frame-by-frame velocity graph shows monotonically decreasing speed from finger-lift to rest
- **SC-002**: Pinch-to-zoom works reliably with no overshoot — zoom level measured at every frame never exceeds the defined maximum or falls below the defined minimum regardless of pinch speed
- **SC-003**: Double-tap re-centring moves the camera so that tile (0,0) is centred in the viewport within one frame of the gesture being recognised, verified by automated gesture injection test
- **SC-004**: The tile selector and settings button are reachable with a single thumb without grip adjustment on a standard 6.1-inch portrait-mode phone, verified by a reachability heatmap overlay showing all controls inside the standard thumb arc
