class_name SeedCraftGridNormalizer
extends RefCounted

const EMPTY_SLOT: int = -1

func normalize_slots(slot_tokens: Array[int]) -> Dictionary:
	var occupied_tokens: Array[int] = []
	var occupied_slot_indices: Array[int] = []
	for i: int in range(slot_tokens.size()):
		var token: int = slot_tokens[i]
		if token == EMPTY_SLOT:
			continue
		occupied_tokens.append(token)
		occupied_slot_indices.append(i)
	var normalized_tokens: Array[int] = occupied_tokens.duplicate()
	normalized_tokens.sort()
	return {
		"occupied_count": occupied_tokens.size(),
		"occupied_tokens": occupied_tokens,
		"occupied_slot_indices": occupied_slot_indices,
		"normalized_tokens": normalized_tokens,
		"normalized_key": canonical_key(normalized_tokens),
	}

func canonical_key(tokens: Array[int]) -> String:
	if tokens.is_empty():
		return ""
	var parts: Array[String] = []
	for token: int in tokens:
		parts.append(str(token))
	return "_".join(parts)
