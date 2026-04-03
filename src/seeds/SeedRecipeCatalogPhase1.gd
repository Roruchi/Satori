class_name SeedRecipeCatalogPhase1
extends RefCounted

const _ALLOWED_KEYS: Dictionary = {
	"0": true,
	"1": true,
	"2": true,
	"3": true,
	"4": true,
	"0_1": true,
	"0_2": true,
	"0_3": true,
	"0_4": true,
	"1_2": true,
	"1_3": true,
	"1_4": true,
	"2_3": true,
	"2_4": true,
	"3_4": true,
}

func is_valid_token_count(token_count: int) -> bool:
	return token_count == 1 or token_count == 2

func is_allowed_key(key: String) -> bool:
	return _ALLOWED_KEYS.has(key)
