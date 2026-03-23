class_name RuntimeLogger
extends RefCounted

static func warn(context: String, message: String) -> void:
	push_warning("[%s] %s" % [context, message])

static func info(context: String, message: String) -> void:
	print("[%s] %s" % [context, message])

static func err(context: String, message: String) -> void:
	push_error("[%s] %s" % [context, message])
