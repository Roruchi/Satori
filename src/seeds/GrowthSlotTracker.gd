class_name GrowthSlotTracker
extends RefCounted

var active_seeds: Array[SeedInstance] = []
var capacity: int = 3

func available_slots() -> int:
	return maxi(0, capacity - active_seeds.size())

func is_full() -> bool:
	return active_seeds.size() >= capacity

func add(seed: SeedInstance) -> void:
	active_seeds.append(seed)

func remove_bloomed(coord: Vector2i) -> void:
	for i in range(active_seeds.size()):
		if active_seeds[i].hex_coord == coord:
			active_seeds.remove_at(i)
			return

func get_at(coord: Vector2i) -> SeedInstance:
	for seed: SeedInstance in active_seeds:
		if seed.hex_coord == coord:
			return seed
	return null

func get_ready_seeds() -> Array[SeedInstance]:
	var ready: Array[SeedInstance] = []
	for seed: SeedInstance in active_seeds:
		if seed.state == SeedState.Value.READY:
			ready.append(seed)
	return ready
