class_name SpiritService
extends Node

signal spirit_summoned(spirit_id: String, instance: SpiritInstance)
signal spirit_despawned(spirit_id: String)
signal riddle_hint_triggered(spirit_id: String, riddle_text: String)
signal sky_whale_event_triggered()

const _PatternLoaderScript = preload("res://src/biomes/pattern_loader.gd")
const _SpiritGiftProcessorScript = preload("res://src/spirits/SpiritGiftProcessor.gd")
const GodaiElementScript = preload("res://src/seeds/GodaiElement.gd")
const SpiritGiftTypeScript = preload("res://src/spirits/SpiritGiftType.gd")
const BiomeTypeScript = preload("res://src/biomes/BiomeType.gd")
const SatoriConditionEvaluatorScript = preload("res://src/satori/SatoriConditionEvaluator.gd")

var _catalog: SpiritCatalog
var _spawner: SpiritSpawner
var _riddle_evaluator: SpiritRiddleEvaluator
var _sky_whale_evaluator: SkyWhaleEvaluator
## Keyed by compound key "island_{island_id}|spirit_{spirit_id}" when island_id
## is known, or bare spirit_id for spirits without island scope (e.g. Sky Whale).
var _active_instances: Dictionary = {}
var _active_wanderers: Dictionary = {}
var _riddle_shown: Dictionary = {}
var _spirit_patterns: Array[PatternDefinition] = []
var _current_era: StringName = &"stillness"

func _ready() -> void:
	_catalog = SpiritCatalog.new()
	_catalog.load_from_data(SpiritCatalogData.new())
	_riddle_evaluator = SpiritRiddleEvaluator.new()
	_sky_whale_evaluator = SkyWhaleEvaluator.new()
	_spawner = SpiritSpawner.new()
	var loader: PatternLoader = _PatternLoaderScript.new()
	_spirit_patterns = loader.load_patterns("res://src/biomes/patterns/spirits")
	var scan_service: Node = get_node_or_null("/root/PatternScanService")
	if scan_service != null and scan_service.has_signal("discovery_triggered"):
		scan_service.discovery_triggered.connect(_on_discovery_triggered)
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_signal("tile_placed"):
		game_state.tile_placed.connect(_on_tile_placed)
	call_deferred("_setup_spawner")
	call_deferred("restore_from_persistence")
	call_deferred("_connect_soundscape")
	var satori_service: Node = get_node_or_null("/root/SatoriService")
	if satori_service != null and satori_service.has_signal("era_changed"):
		satori_service.era_changed.connect(_on_era_changed)
		if satori_service.has_method("get_current_era"):
			_current_era = satori_service.get_current_era()

func set_spawner_parent(parent: Node) -> void:
	_spawner.set_parent(parent)

func _connect_soundscape() -> void:
	var soundscape: Node = get_node_or_null("/root/SoundscapeEngine")
	if soundscape != null and soundscape.has_method("on_spirit_summoned"):
		spirit_summoned.connect(soundscape.on_spirit_summoned)

func _setup_spawner() -> void:
	var garden_view: Node = get_node_or_null("../GardenView")
	if garden_view == null:
		return
	var spirit_layer: Node2D = garden_view.get_node_or_null("SpiritLayer2D")
	if spirit_layer == null:
		spirit_layer = Node2D.new()
		spirit_layer.name = "SpiritLayer2D"
		garden_view.add_child(spirit_layer)
	_spawner.set_parent(spirit_layer)

func restore_from_persistence() -> void:
	var persistence: Node = get_node_or_null("/root/SpiritPersistence")
	if persistence == null:
		return
	for data: Dictionary in persistence.get_instances():
		var instance: SpiritInstance = SpiritInstance.deserialize(data)
		if instance.spirit_id.is_empty():
			continue
		var key: String = _spirit_key(instance.spirit_id, instance.island_id)
		_active_instances[key] = instance
		var entry: Dictionary = _catalog.lookup(instance.spirit_id)
		var wanderer: Node = _spawner.spawn(instance, entry)
		_active_wanderers[key] = wanderer
		var ecology: Node = get_node_or_null("/root/SpiritEcologyService")
		if ecology != null and ecology.has_method("register_wanderer"):
			ecology.register_wanderer(wanderer)

func _on_discovery_triggered(discovery_id: String, triggering_coords: Array[Vector2i]) -> void:
	if not discovery_id.begins_with("spirit_"):
		return
	if discovery_id == SkyWhaleEvaluator.SPIRIT_ID:
		return  # Sky Whale is triggered by tile_placed balance check, not by PatternMatcher
	var island_id: String = _island_for_coords(triggering_coords)
	var key: String = _spirit_key(discovery_id, island_id)
	if _active_instances.has(key):
		return
	_summon_spirit(discovery_id, triggering_coords, island_id)

func _summon_spirit(spirit_id: String, coords: Array[Vector2i], island_id: String = "") -> void:
	var entry: Dictionary = _catalog.lookup(spirit_id)
	var wander_radius: int = int(entry.get("wander_radius", 4))
	var bounds: Rect2i = SpiritWanderBounds.from_coords(coords, wander_radius)
	var spawn: Vector2i = SpiritWanderBounds.centroid(coords)
	var instance: SpiritInstance = SpiritInstance.create(spirit_id, spawn, bounds)
	instance.island_id = island_id
	var key: String = _spirit_key(spirit_id, island_id)
	_active_instances[key] = instance
	var wanderer: Node = _spawner.spawn(instance, entry)
	_active_wanderers[key] = wanderer
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		var grid: RefCounted = game_state.grid
		if grid != null and grid.has_method("get_tile"):
			var spawn_tile: GardenTile = grid.get_tile(spawn)
			if spawn_tile != null:
				spawn_tile.metadata["spirit_id"] = spirit_id
	_SpiritGiftProcessorScript.process(spirit_id, entry)
	var ecology: Node = get_node_or_null("/root/SpiritEcologyService")
	if ecology != null and ecology.has_method("register_wanderer"):
		ecology.register_wanderer(wanderer)
	spirit_summoned.emit(spirit_id, instance)
	var codex: Node = get_node_or_null("/root/CodexService")
	if codex != null and codex.has_method("mark_discovered"):
		codex.mark_discovered(StringName(spirit_id))
	var persistence: Node = get_node_or_null("/root/SpiritPersistence")
	if persistence != null and persistence.has_method("record_instance"):
		persistence.record_instance(instance)
	_maybe_mark_shrine_buildable(instance)
	_maybe_queue_godai_charge_drop(spirit_id, entry)

func _on_tile_placed(_coord: Vector2i, _tile: GardenTile) -> void:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	var grid: RefCounted = game_state.grid
	if _sky_whale_evaluator.evaluate(grid) and not _active_instances.has(SkyWhaleEvaluator.SPIRIT_ID):
		_summon_sky_whale(grid)
	_evaluate_riddle_hints(grid)

func _evaluate_riddle_hints(grid: RefCounted) -> void:
	var persistence: Node = get_node_or_null("/root/DiscoveryPersistence")
	var registry: DiscoveryRegistry = DiscoveryRegistry.new()
	if persistence != null and persistence.has_method("get_discovered_ids"):
		var ids: Array[String] = persistence.get_discovered_ids()
		registry.mark_discoveries(ids)
	for pattern: PatternDefinition in _spirit_patterns:
		var sid: String = pattern.discovery_id
		# Skip if spirit is already active on any island — riddle hint no longer relevant.
		if _is_spirit_active_anywhere(sid):
			continue
		if _riddle_shown.has(sid):
			continue
		if _riddle_evaluator.evaluate_partial(pattern, grid, registry):
			_riddle_shown[sid] = true
			var entry: Dictionary = _catalog.lookup(sid)
			var riddle: String = str(entry.get("riddle_text", ""))
			riddle_hint_triggered.emit(sid, riddle)

func _summon_sky_whale(grid: RefCounted) -> void:
	var bounds: Rect2i = grid.garden_bounds
	var center: Vector2i = bounds.position + bounds.size / 2
	var entry: Dictionary = _catalog.lookup(SkyWhaleEvaluator.SPIRIT_ID)
	var wander_radius: int = int(entry.get("wander_radius", 50))
	var expanded_bounds: Rect2i = Rect2i(
		bounds.position - Vector2i(wander_radius, wander_radius),
		bounds.size + Vector2i(wander_radius * 2, wander_radius * 2)
	)
	var instance: SpiritInstance = SpiritInstance.create(SkyWhaleEvaluator.SPIRIT_ID, center, expanded_bounds)
	# Sky Whale is global — no island scoping.
	instance.island_id = ""
	_active_instances[SkyWhaleEvaluator.SPIRIT_ID] = instance
	var wanderer: Node = _spawner.spawn(instance, entry)
	var ecology: Node = get_node_or_null("/root/SpiritEcologyService")
	if ecology != null and ecology.has_method("register_wanderer"):
		ecology.register_wanderer(wanderer)
	spirit_summoned.emit(SkyWhaleEvaluator.SPIRIT_ID, instance)
	sky_whale_event_triggered.emit()
	var persistence: Node = get_node_or_null("/root/SpiritPersistence")
	if persistence != null and persistence.has_method("record_instance"):
		persistence.record_instance(instance)

func active_count() -> int:
	return _active_instances.size()

func get_housing_snapshot() -> Dictionary:
	var total_active: int = _active_instances.size()
	var bonus_capacity: int = 0
	var satori_service: Node = get_node_or_null("/root/SatoriService")
	if satori_service != null and satori_service.has_method("get_spirit_housing_capacity_bonus"):
		bonus_capacity = int(satori_service.get_spirit_housing_capacity_bonus())
	var housed_count: int = mini(total_active, maxi(bonus_capacity, 0))
	var unhoused_count: int = maxi(total_active - housed_count, 0)
	var remaining_housed: int = housed_count

	var housed_by_island: Dictionary = {}
	if remaining_housed > 0:
		for key_variant: Variant in _active_instances.keys():
			var key: String = str(key_variant)
			var instance: SpiritInstance = _active_instances[key]
			if instance == null:
				continue
			if instance.island_id.is_empty():
				continue
			if remaining_housed <= 0:
				break
			housed_by_island[instance.island_id] = int(housed_by_island.get(instance.island_id, 0)) + 1
			remaining_housed -= 1

	var final_housed: int = housed_count
	return {
		"housed_count": final_housed,
		"unhoused_count": unhoused_count,
		"housed_by_island": housed_by_island,
	}

func get_catalog_entry(spirit_id: String) -> Dictionary:
	return _catalog.lookup(spirit_id)

## Return the compound active-instance key for a spirit on an island.
## When island_id is empty the bare spirit_id is used (Sky Whale, legacy).
func _spirit_key(spirit_id: String, island_id: String) -> String:
	if island_id.is_empty():
		return spirit_id
	return "island_%s|spirit_%s" % [island_id, spirit_id]

## Return true if the given spirit is active on any island.
## Checks both bare keys (Sky Whale / empty island) and compound island-scoped keys.
func _is_spirit_active_anywhere(spirit_id: String) -> bool:
	if _active_instances.has(spirit_id):
		return true
	var suffix: String = "|spirit_%s" % spirit_id
	for key: Variant in _active_instances:
		if str(key).ends_with(suffix):
			return true
	return false

func _on_era_changed(new_era: StringName) -> void:
	_current_era = new_era
	_apply_era_requirements()

func _apply_era_requirements() -> void:
	var keys_to_remove: Array[String] = []
	for key_variant: Variant in _active_instances.keys():
		var key: String = str(key_variant)
		var instance: SpiritInstance = _active_instances[key]
		if instance == null:
			continue
		var entry: Dictionary = _catalog.lookup(instance.spirit_id)
		var required_era: StringName = StringName(str(entry.get("min_era", "stillness")))
		if SatoriConditionEvaluatorScript.era_meets_requirement(_current_era, required_era):
			continue
		keys_to_remove.append(key)
	for key: String in keys_to_remove:
		_despawn_by_key(key)

func _despawn_by_key(key: String) -> void:
	var instance: SpiritInstance = _active_instances.get(key)
	if instance == null:
		return
	var wanderer: Node = _active_wanderers.get(key)
	if wanderer != null:
		wanderer.queue_free()
	_active_wanderers.erase(key)
	_active_instances.erase(key)
	spirit_despawned.emit(instance.spirit_id)

## Look up the island_id for the first valid coord in a triggering-coords array.
## Returns "" if the coord is not in the grid or has no island_id (e.g., Ku tile).
## The has_method guard allows this to work in unit-test contexts where GameState
## may have a mock grid that has not yet implemented get_island_id.
func _island_for_coords(coords: Array[Vector2i]) -> String:
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return ""
	var grid: RefCounted = game_state.grid
	if grid == null or not grid.has_method("get_island_id"):
		return ""
	for coord: Vector2i in coords:
		var iid: String = grid.get_island_id(coord)
		if not iid.is_empty():
			return iid
	return ""

func _maybe_mark_shrine_buildable(instance: SpiritInstance) -> void:
	if instance == null:
		return
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state == null:
		return
	var grid: RefCounted = game_state.grid
	if grid == null or not grid.has_method("get_tile"):
		return
	var tile: GardenTile = grid.get_tile(instance.spawn_coord)
	if tile == null:
		return
	tile.metadata["shrine_buildable"] = true
	tile.metadata["shrine_built"] = false
	tile.metadata["shrine_spirit_id"] = instance.spirit_id

func _maybe_queue_godai_charge_drop(spirit_id: String, entry: Dictionary) -> void:
	var elements: Array[int] = _elements_for_spirit_charge(entry)
	if elements.is_empty():
		return
	var element_parts: PackedStringArray = []
	for element: int in elements:
		element_parts.append(str(element))
	_SpiritGiftProcessorScript.process_gift(
		SpiritGiftTypeScript.Value.GODAI_CHARGE,
		StringName("%s:%s" % [spirit_id, ",".join(element_parts)])
	)

func _elements_for_spirit_charge(entry: Dictionary) -> Array[int]:
	var elements: Array[int] = []
	var seen: Dictionary = {}
	var preferred_variant: Variant = entry.get("preferred_biomes", [])
	if preferred_variant is Array:
		var preferred_biomes: Array = preferred_variant as Array
		for biome_variant: Variant in preferred_biomes:
			var biome: int = int(biome_variant)
			var mapped: Array[int] = _elements_for_biome(biome)
			for element: int in mapped:
				if seen.has(element):
					continue
				seen[element] = true
				elements.append(element)
	if elements.is_empty():
		elements.append(GodaiElementScript.Value.CHI)
	return elements

func _elements_for_biome(biome: int) -> Array[int]:
	match biome:
		BiomeTypeScript.Value.STONE:
			return [GodaiElementScript.Value.CHI]
		BiomeTypeScript.Value.RIVER:
			return [GodaiElementScript.Value.SUI]
		BiomeTypeScript.Value.EMBER_FIELD:
			return [GodaiElementScript.Value.KA]
		BiomeTypeScript.Value.MEADOW:
			return [GodaiElementScript.Value.FU]
		BiomeTypeScript.Value.WETLANDS:
			return [GodaiElementScript.Value.CHI, GodaiElementScript.Value.SUI]
		BiomeTypeScript.Value.BADLANDS:
			return [GodaiElementScript.Value.CHI, GodaiElementScript.Value.KA]
		BiomeTypeScript.Value.WHISTLING_CANYONS:
			return [GodaiElementScript.Value.CHI, GodaiElementScript.Value.FU]
		BiomeTypeScript.Value.PRISMATIC_TERRACES:
			return [GodaiElementScript.Value.SUI, GodaiElementScript.Value.KA]
		BiomeTypeScript.Value.FROSTLANDS:
			return [GodaiElementScript.Value.SUI, GodaiElementScript.Value.FU]
		BiomeTypeScript.Value.THE_ASHFALL:
			return [GodaiElementScript.Value.KA, GodaiElementScript.Value.FU]
		BiomeTypeScript.Value.SACRED_STONE:
			return [GodaiElementScript.Value.CHI, GodaiElementScript.Value.KU]
		BiomeTypeScript.Value.MOONLIT_POOL:
			return [GodaiElementScript.Value.SUI, GodaiElementScript.Value.KU]
		BiomeTypeScript.Value.EMBER_SHRINE:
			return [GodaiElementScript.Value.KA, GodaiElementScript.Value.KU]
		BiomeTypeScript.Value.CLOUD_RIDGE:
			return [GodaiElementScript.Value.FU, GodaiElementScript.Value.KU]
		BiomeTypeScript.Value.KU:
			return [GodaiElementScript.Value.KU]
		_:
			return []
