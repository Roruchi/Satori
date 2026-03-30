# Structure Building System Proposal

## Goal
Evaluate and compare three approaches for structure construction in Satori, then recommend a direction that balances gameplay clarity, technical reliability, and implementation cost.

---

## Option A: Keep Current In-World Shape Building
Players place biome tiles in build mode and structures resolve from valid in-world patterns.

### Pros
- Preserves the strongest discovery fantasy (players discover structures in the world itself).
- Minimal additional UI work.
- Keeps elemental placement and structure creation tightly coupled.
- Feels systemic and emergent.

### Cons
- High technical complexity during incremental placement.
- Frequent edge-case bugs (partial footprints, anchor drift, mixed house/structure outcomes).
- Harder onboarding (rules are less explicit than inventory crafting).
- Higher regression burden due to many tile metadata transitions.

---

## Option B: Full Crafting Menu + Placeable Structure Inventory
Players craft structures using elemental charges, then place crafted structure items from inventory.

### Pros
- Validation shifts to craft-time, reducing placement-time complexity.
- Placement logic becomes straightforward (fit/collision check + commit).
- Clearer UX: craft item -> place item.
- Easier balancing via explicit recipe costs.
- Strongly reduces multi-tile metadata drift bugs.

### Cons
- Highest up-front implementation cost (crafting UI, inventory state, placement item flow).
- Risks losing some emergent puzzle feel if all structure logic leaves terrain interactions.
- Requires migration strategy for existing worlds and pending projects.
- Adds menu friction if not designed carefully.

---

## Option C: Hybrid 
Keep pattern/discovery for unlocking structures, then require crafting a placeable structure item before placement.

### Pros
- Retains discovery identity while simplifying placement reliability.
- Clear separation of concerns:
  - Discovery = unlock eligibility.
  - Crafting = resource commitment.
  - Placement = footprint fit and spawn.
- Directly addresses current bug classes (partial footprints, mixed house/structure conversion, invalid grouped confirmations).
- Easier UX communication than pure pattern-only systems.
- Lower migration risk than a full replacement.

### Cons
- More surface area than either pure approach.
- Requires clear UI messaging for unlock vs craft vs place states.
- Needs careful balancing of charge costs and structure power.

---

## Option D: Unified Craft Grid + Single Place Menu 
One 3x3 crafting grid crafts both tiles and structures. The player then places crafted outputs from one place menu.

Core idea from current design discussion:
- Single and duo elemental seeds still craft biomes/tiles.
- Structures (including house variants) become explicit recipes in the same craft grid.
- Build mode becomes a single placement inventory (tiles + structures), reducing menu switching.

### Pros
- Lowest menu friction (craft and place loop is consolidated).
- Removes most in-world rotation/pattern validation complexity.
- Very clear player mental model: craft result -> place result.
- Easier to enforce placement constraints consistently per item.
- Strong foundation for future content scaling (new recipes are data additions).

### Cons
- Largest crafting UX scope (must clearly support tile and structure recipes together).
- Requires clear tutorialization to avoid overloading players early.
- Multi-tile structure crafting/placement UX must be designed carefully.
- Requires migration from implicit pattern-building to explicit crafted outputs.

---

## Multi-Tile Crafting and UX Proposal
Recommended approach to keep it user friendly:

1. Craft-time yields a structure item, not placed tiles.
2. Placement-time shows a ghost footprint on the map.
3. Rotate/flip footprint in-place before confirm.
4. One confirm places the full structure atomically.
5. If footprint is invalid, show blocked cells and reason text.

Suggested placement validation output (human-readable):
- Invalid terrain (example: "Origin Shrine requires Stone").
- Occupied tile in footprint.
- Island/uniqueness rule violation.
- Out-of-bounds footprint.

---

## Placement Rule Strategies
Two viable strategies for special structures such as Origin Shrine:

### Strategy 1: Keep Terrain Rule (Stone-only)
- Recipe remains moderate.
- Placement validator enforces Stone-only footprint.

Pros:
- Preserves world-logic consistency.
- Keeps shrine identity tied to terrain.

Cons:
- Slightly more placement friction.

### Strategy 2: Relax Terrain Rule, Increase Recipe Complexity
- Example: Ku in center, surrounded by all four base elements in craft grid.
- Placement can be "any non-Ku" (or broader), since recipe itself is the gate.

Pros:
- Smoother placement flow.
- Difficulty shifts to crafting puzzle, not terrain checking.

Cons:
- Less spatial identity from terrain.
- Recipe balancing becomes critical.

---

## Updated Recommendation
Adopt Option D as target architecture, shipped through a hybrid transition.

Rationale:
- Matches your goal of reducing menu switches.
- Eliminates most fragile runtime pattern checks.
- Keeps room for special-placement identity via explicit validators when desired.

Transition note:
- You can keep legacy discovery unlocks while moving production and placement to crafted items.
- This keeps progression flavor while simplifying build correctness.

---

## Phased Rollout
1. Add unified 3x3 craft grid model and one place menu shell (no behavior changes yet).
2. Pilot with two crafted structures (Wayfarer Torii and Origin Shrine) using ghost-footprint placement.
3. Move house creation to crafted outputs (single-tile starter house, then advanced house recipes).
4. Migrate tile crafting into the same grid flow while preserving elemental charge economy.
5. Retire legacy grouped build-confirm path and metadata-heavy structure inference.

---

## Success Criteria
- No mixed footprint outcomes (single structure + accidental houses).
- Multi-tile structures always finalize atomically.
- Invalid grouped non-recipe projects are blocked.
- Players can explain build flow in 1 sentence (craft -> place).
- Regression test coverage includes footprint finalization, anchor-only effects, and placement blocking rules.
- Menu switching decreases measurably (craft + place completed with one menu family).

---

## No-Stack Recipe Spec (Draft)

This section defines a no-stack crafting grammar for Option D.

### Rules
- Each 3x3 slot contains zero or one element token.
- Seed recipes use token sets (position-insensitive).
- Structure recipes use exact 3x3 patterns (position-sensitive).
- Craft output is always a single item.
- Placement validates footprint atomically before commit.

### Seed Recipes (Position-Insensitive)

Single-element seeds (1 token):

| Input Token Set | Output |
|---|---|
| `CHI` | Stone Seed |
| `SUI` | River Seed |
| `KA` | Ember Field Seed |
| `FU` | Meadow Seed |
| `KU` | Ku Seed (requires Ku unlock) |

Dual-element seeds (2 tokens):

| Input Token Set | Output |
|---|---|
| `CHI + SUI` | Wetlands Seed |
| `CHI + KA` | Badlands Seed |
| `CHI + FU` | Whistling Canyons Seed |
| `SUI + KA` | Prismatic Terraces Seed |
| `SUI + FU` | Frostlands Seed |
| `KA + FU` | The Ashfall Seed |
| `CHI + KU` | Sacred Stone Seed |
| `SUI + KU` | Moonlit Pool Seed |
| `KA + KU` | Ember Shrine Seed |
| `FU + KU` | Cloud Ridge Seed |

### House Recipes (Pattern-Sensitive, No Stacking)

All houses craft to placeable items and are placed from the shared place menu.

| Recipe ID | 3x3 Pattern (row-major) | Output Item | Notes |
|---|---|---|---|
| `house_basic_kit` | `. FU . / CHI . SUI / . . .` | Basic House Kit | Starter single-tile house |
| `house_stone_kit` | `. CHI . / CHI FU CHI / . KA .` | Stone House Kit | Durable variant |
| `house_river_kit` | `. SUI . / CHI FU SUI / . SUI .` | River House Kit | Water-aligned variant |
| `house_ku_kit` | `. KU . / CHI FU SUI / . KA .` | Spirit House Kit | Late-game house |

Legend: `.` means empty slot.

### Intermediate Components (For Advanced Structures Without Stacking)

To represent concepts like `(CHI+KU)+(FU+KU)` without slot stacking, craft components first.

| Component Recipe | 3x3 Pattern | Output |
|---|---|---|
| `sigil_chi_ku` | `. CHI . / . KU . / . . .` | Chi-Ku Sigil |
| `sigil_fu_ku` | `. FU . / . KU . / . . .` | Fu-Ku Sigil |
| `core_fourfold` | `. FU . / CHI KU KA / . SUI .` | Fourfold Core |

Then use those components in higher-tier structure recipes.

### Example Structure Recipe Using Components

| Recipe ID | 3x3 Pattern | Output |
|---|---|---|
| `origin_shrine_item` | `. Fu-Ku Sigil . / Chi-Ku Sigil Fourfold Core Chi-Ku Sigil / . Fu-Ku Sigil .` | Origin Shrine Item |

### Placement Validation Rules (Draft)
- Origin Shrine footprint must be on Stone tiles (if terrain rule strategy is chosen).
- Structure cannot overlap occupied tiles.
- Unique-per-island and unique-per-biome checks run before placement commit.
- Invalid footprint highlights blocked cells and shows one explicit reason.

### UX Notes
- Seed recipes should accept any token positions (auto-normalized set matching).
- Structure recipes should require exact 3x3 shape matching for readability and mastery.
- Recipe book should show both token list and visual 3x3 pattern.
