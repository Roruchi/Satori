class_name GodaiElement
extends RefCounted

enum Value {
	CHI = 0,
	SUI = 1,
	KA = 2,
	FU = 3,
	KU = 4,
}

const DISPLAY_NAMES: Dictionary = {
	Value.CHI: "Chi (地)",
	Value.SUI: "Sui (水)",
	Value.KA: "Ka (火)",
	Value.FU: "Fū (風)",
	Value.KU: "Kū (空)",
}

const LOCKED_BY_DEFAULT: Array[int] = [Value.KU]
