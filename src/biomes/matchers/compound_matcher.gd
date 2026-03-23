class_name CompoundMatcher
extends RefCounted

func prerequisites_met(pattern: PatternDefinition, discovery_registry: DiscoveryRegistry, scan_discoveries: Dictionary) -> bool:
	for required_id in pattern.prerequisite_ids:
		if not discovery_registry.has_discovery(required_id) and not scan_discoveries.has(required_id):
			return false
	return true
