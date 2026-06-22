# Contract: Spirit Assistant Ritual Input

**Branch**: `024-spirit-assistants-components` | **Date**: 2026-06-22

## Availability Input

```gdscript
{
	"island_id": String,
	"include_blocked": bool
}
```

## Availability Output

```gdscript
{
	"assistants": Array[Dictionary] # AssistantAvailability records
}
```

## Ritual Use Input

```gdscript
{
	"spirit_key": String,
	"ritual_id": StringName,
	"context": Dictionary
}
```

## Invariants

- A spirit assistant is a ritual input, not an ingredient.
- Ritual success never removes, despawns or consumes the spirit.
- Ritual failure never changes spirit state except optional non-gameplay feedback/cooldown if explicitly designed later.
- A spirit can appear only once in a ritual attempt.
- Confirmation must revalidate mood, active state, island scope and cooldown.
- Red Fox assistant profile includes Fire intent.
- Hare assistant profile supports Meadow/Earth shelter paths.

## Required Block Reasons

- `not_housed`
- `not_happy`
- `cooldown`
- `wrong_island`
- `inactive`
- `assistant_gate_locked`

## Initial Acceptance Fixtures

| Spirit State | Ritual Selection | Expected |
|--------------|------------------|----------|
| Red Fox housed + happy + gate unlocked | select Red Fox | available |
| Red Fox restless | select Red Fox | blocked `not_happy` |
| Red Fox selected twice | confirm ritual | duplicate/failure |
| Red Fox assists successful ritual | post-commit | Red Fox remains active |
| Hare housed + happy | shelter variant ritual | supports Hare Hollow path |
