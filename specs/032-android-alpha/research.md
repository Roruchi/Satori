# Research: Android Alpha

## Decision: Add Android after save safety

**Rationale**: Touch testing is useful earlier, but external Android alpha is unsafe until save/load is reliable.

## Decision: Physical device preferred, emulator acceptable initially

**Rationale**: Mobile UI and lifecycle issues are best caught on device, but an emulator can unblock export validation.

## Decision: Document signing approach before release-like build

**Rationale**: Debug install is enough for early testing, but repeatable alpha distribution needs known signing/versioning.

## Decision: Use package id `com.lunaverse.satori`

**Rationale**: The alpha needs a stable package identity before device testing and save/lifecycle checks.

## Decision: No orientation lock

**Rationale**: Alpha testing should catch layout problems instead of hiding them behind a lock. Phone portrait remains the primary manual-check path, and both orientations must avoid broken layouts.

## Decision: Use the title emblem for the Android icon

**Rationale**: The alpha build should not ship placeholder identity assets. The title emblem is the minimum acceptable Android icon source.

## Decision: Use visible zero-based alpha build versioning

**Rationale**: Android tester feedback needs exact build identity. The menu shows a version such as `0.1.0-alpha+20260627.1`.
