# Data Model: Spirit Happiness, Ritual Assistants and Components

**Branch**: `024-spirit-assistants-components` | **Date**: 2026-06-22 | **Spec**: [spec.md](spec.md)

## SpiritMoodState

Persistent mood state for one active spirit.

Fields:

- `spirit_key: String`
- `spirit_id: String`
- `island_id: String`
- `mood: StringName` (`visiting|housed|happy|restless|unhappy|wandering|dormant|elder|assistant_ready`)
- `mood_since: float`
- `housed: bool`
- `house_coord: Vector2i`
- `comfort_score: int`
- `restless_since: float`
- `assistant_ready: bool`
- `assistant_cooldown_until: float`

Validation:

- `assistant_ready` requires a housed/happy/elder-compatible mood unless debug-gated.
- `house_coord` is meaningful only when `housed == true`.
- Mood transitions must be deterministic for a given saved state and current garden state.

## SpiritAssistantProfile

Definition data for a spirit's assistant behavior.

Fields:

- `spirit_id: StringName`
- `element_tags: Array[int]`
- `role_tags: Array[StringName]`
- `requires_mood: StringName`
- `cooldown_seconds: float`
- `ritual_hint_ids: Array[StringName]`

Initial profiles:

- Red Fox: Fire intent, warmth, foxfire, shelter specialization.
- Hare: Meadow/Earth shelter support, soft dwelling, stability.

Validation:

- A profile cannot make the spirit consumable.
- Element tags must be compatible with ritual resolver input tags.

## AssistantAvailability

Derived view for ritual menu selection.

Fields:

- `spirit_key: String`
- `spirit_id: StringName`
- `display_name: String`
- `input_key: String`
- `available: bool`
- `blocked_reason: StringName`
- `element_tags: Array[int]`

Validation:

- `input_key` uses `spirit:<spirit_key>` or equivalent stable identity.
- Availability is recomputed for preview and confirmation.

## ComponentDefinition

Ritual component definition.

Fields:

- `component_id: StringName`
- `display_name: String`
- `source_kind: StringName` (`discovered_structure|placed_structure|inventory_item|memory`)
- `source_id: StringName`
- `role_tags: Array[StringName]`
- `element_tags: Array[int]`
- `requires_island_local: bool`
- `consumed_on_use: bool`

Validation:

- `consumed_on_use` defaults to false for discovered or placed structures.
- Placed-structure components require a target island or context island.
- Component input key must not collide with material or spirit keys.

## ComponentAvailability

Derived view for component ritual input.

Fields:

- `component_id: StringName`
- `input_key: String`
- `available: bool`
- `blocked_reason: StringName`
- `source_coord: Vector2i`
- `island_id: String`

Validation:

- Discovery-based components require the discovery to be recorded.
- Placed components require a matching placed structure in the required scope.

## ComponentRitualRule

Ritual definition that uses a component.

Fields:

- `ritual_id: StringName`
- `input_keys_or_tags: Array[String]`
- `requires_assistant_tags: Array[StringName]`
- `requires_component_id: StringName`
- `requires_satori_min: int`
- `requires_island_state: StringName`
- `result_id: StringName`
- `result_kind: StringName`

Validation:

- Inputs still obey the global no-duplicate slot rule.
- At least one essence or assistant-provided elemental intent must be present according to the resolver contract.
- Spirits are never consumed.

## State Transitions

1. **Housing Snapshot**: SpiritService computes current house assignment.
2. **Mood Evaluation**: Mood state updates from housing, biome fit, comfort structures and timers.
3. **Assistant Availability**: Happy/ready spirits become ritual input candidates.
4. **Component Availability**: Discovery and placed-structure state become ritual input candidates.
5. **Ritual Preview**: Resolver uses assistants/components without mutating state.
6. **Confirm Revalidation**: Availability is checked again.
7. **Commit**: Result is produced; spirit remains active; component is consumed only if explicitly inventory-based and marked consumable.
