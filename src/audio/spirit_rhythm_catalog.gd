## SpiritRhythmCatalog — maps each spirit to its rhythmic audio contribution.
## Audio asset paths point to placeholder locations; assets are loaded
## only when the file exists (graceful no-op when .ogg files are absent).
##
## Each entry:
##   audio_key  : unique audio identifier
##   path       : res:// path to a looping rhythmic audio file
##   volume_db  : base volume in dB at full weight (negative = quieter)
##   layer      : "hihat" | "drum" | "melodic" | "texture" — used for
##                mix-balancing across many simultaneous spirits
class_name SpiritRhythmCatalog
extends RefCounted

## Maximum per-layer dB reduction applied as more spirit layers are added.
## Each doubling of active spirits reduces each layer by STACK_ROLLOFF_DB.
const STACK_ROLLOFF_DB: float = 3.0

## Registry: spirit_id → {audio_key, path, volume_db, layer}
const ENTRIES: Dictionary = {
	"spirit_mist_stag": {
		"audio_key": "stag_hihat",
		"path": "res://assets/audio/spirits/stag_hihat.ogg",
		"volume_db": -6.0,
		"layer": "hihat"
	},
	"spirit_boreal_wolf": {
		"audio_key": "wolf_drums",
		"path": "res://assets/audio/spirits/wolf_drums.ogg",
		"volume_db": -3.0,
		"layer": "drum"
	},
	"spirit_sky_whale": {
		"audio_key": "whale_drone",
		"path": "res://assets/audio/spirits/whale_drone.ogg",
		"volume_db": -4.0,
		"layer": "texture"
	},
	"spirit_frost_owl": {
		"audio_key": "owl_chime",
		"path": "res://assets/audio/spirits/owl_chime.ogg",
		"volume_db": -8.0,
		"layer": "melodic"
	},
	"spirit_owl_of_silence": {
		"audio_key": "owl_chime",
		"path": "res://assets/audio/spirits/owl_chime.ogg",
		"volume_db": -8.0,
		"layer": "melodic"
	},
	"spirit_river_otter": {
		"audio_key": "water_plonk",
		"path": "res://assets/audio/spirits/water_plonk.ogg",
		"volume_db": -9.0,
		"layer": "melodic"
	},
	"spirit_koi_fish": {
		"audio_key": "water_plonk",
		"path": "res://assets/audio/spirits/water_plonk.ogg",
		"volume_db": -10.0,
		"layer": "melodic"
	},
	"spirit_blue_kingfisher": {
		"audio_key": "kingfisher_ting",
		"path": "res://assets/audio/spirits/kingfisher_ting.ogg",
		"volume_db": -9.0,
		"layer": "hihat"
	},
	"spirit_dragonfly": {
		"audio_key": "dragonfly_buzz",
		"path": "res://assets/audio/spirits/dragonfly_buzz.ogg",
		"volume_db": -12.0,
		"layer": "texture"
	},
	"spirit_golden_bee": {
		"audio_key": "bee_hum",
		"path": "res://assets/audio/spirits/bee_hum.ogg",
		"volume_db": -11.0,
		"layer": "texture"
	},
	"spirit_jade_beetle": {
		"audio_key": "beetle_click",
		"path": "res://assets/audio/spirits/beetle_click.ogg",
		"volume_db": -12.0,
		"layer": "hihat"
	},
	"spirit_meadow_lark": {
		"audio_key": "lark_trill",
		"path": "res://assets/audio/spirits/lark_trill.ogg",
		"volume_db": -8.0,
		"layer": "melodic"
	},
	"spirit_white_heron": {
		"audio_key": "heron_wing",
		"path": "res://assets/audio/spirits/heron_wing.ogg",
		"volume_db": -10.0,
		"layer": "texture"
	},
	"spirit_mountain_goat": {
		"audio_key": "mountain_knock",
		"path": "res://assets/audio/spirits/mountain_knock.ogg",
		"volume_db": -7.0,
		"layer": "drum"
	},
	"spirit_stone_golem": {
		"audio_key": "golem_thud",
		"path": "res://assets/audio/spirits/golem_thud.ogg",
		"volume_db": -5.0,
		"layer": "drum"
	},
	"spirit_granite_ram": {
		"audio_key": "ram_stomp",
		"path": "res://assets/audio/spirits/ram_stomp.ogg",
		"volume_db": -6.0,
		"layer": "drum"
	},
	"spirit_red_fox": {
		"audio_key": "fox_shuffle",
		"path": "res://assets/audio/spirits/fox_shuffle.ogg",
		"volume_db": -10.0,
		"layer": "hihat"
	},
	"spirit_hare": {
		"audio_key": "hare_tap",
		"path": "res://assets/audio/spirits/hare_tap.ogg",
		"volume_db": -11.0,
		"layer": "hihat"
	},
	"spirit_field_mouse": {
		"audio_key": "mouse_skitter",
		"path": "res://assets/audio/spirits/mouse_skitter.ogg",
		"volume_db": -13.0,
		"layer": "hihat"
	},
	"spirit_tree_frog": {
		"audio_key": "frog_croak",
		"path": "res://assets/audio/spirits/frog_croak.ogg",
		"volume_db": -9.0,
		"layer": "melodic"
	},
	"spirit_marsh_frog": {
		"audio_key": "frog_croak",
		"path": "res://assets/audio/spirits/frog_croak.ogg",
		"volume_db": -9.0,
		"layer": "melodic"
	},
	"spirit_peat_salamander": {
		"audio_key": "salamander_drip",
		"path": "res://assets/audio/spirits/salamander_drip.ogg",
		"volume_db": -12.0,
		"layer": "texture"
	},
	"spirit_swamp_crane": {
		"audio_key": "crane_horn",
		"path": "res://assets/audio/spirits/crane_horn.ogg",
		"volume_db": -8.0,
		"layer": "melodic"
	},
	"spirit_murk_crocodile": {
		"audio_key": "croc_low",
		"path": "res://assets/audio/spirits/croc_low.ogg",
		"volume_db": -5.0,
		"layer": "drum"
	},
	"spirit_mud_crab": {
		"audio_key": "crab_click",
		"path": "res://assets/audio/spirits/crab_click.ogg",
		"volume_db": -11.0,
		"layer": "hihat"
	},
	"spirit_tundra_lynx": {
		"audio_key": "lynx_pad",
		"path": "res://assets/audio/spirits/lynx_pad.ogg",
		"volume_db": -8.0,
		"layer": "texture"
	},
	"spirit_ice_cavern_bat": {
		"audio_key": "bat_echo",
		"path": "res://assets/audio/spirits/bat_echo.ogg",
		"volume_db": -10.0,
		"layer": "texture"
	},
	"spirit_emerald_snake": {
		"audio_key": "snake_hiss",
		"path": "res://assets/audio/spirits/snake_hiss.ogg",
		"volume_db": -11.0,
		"layer": "texture"
	},
	"spirit_sun_lizard": {
		"audio_key": "lizard_tap",
		"path": "res://assets/audio/spirits/lizard_tap.ogg",
		"volume_db": -12.0,
		"layer": "hihat"
	},
	"spirit_rock_badger": {
		"audio_key": "badger_grunt",
		"path": "res://assets/audio/spirits/badger_grunt.ogg",
		"volume_db": -9.0,
		"layer": "drum"
	},
	"spirit_oyamatsumi": {
		"audio_key": "earth_pulse",
		"path": "res://assets/audio/spirits/earth_pulse.ogg",
		"volume_db": -4.0,
		"layer": "drum"
	},
	"spirit_suijin": {
		"audio_key": "rain_drop",
		"path": "res://assets/audio/spirits/rain_drop.ogg",
		"volume_db": -6.0,
		"layer": "melodic"
	},
	"spirit_kagutsuchi": {
		"audio_key": "fire_crackle",
		"path": "res://assets/audio/spirits/fire_crackle.ogg",
		"volume_db": -5.0,
		"layer": "texture"
	},
	"spirit_fujin": {
		"audio_key": "wind_pulse",
		"path": "res://assets/audio/spirits/wind_pulse.ogg",
		"volume_db": -5.0,
		"layer": "texture"
	},
}

## Return the catalog entry for a spirit, or an empty dict if unknown.
static func lookup(spirit_id: String) -> Dictionary:
	return ENTRIES.get(spirit_id, {})

## Compute per-layer volume_db for a given number of concurrently active spirit
## rhythm tracks.  Uses a rolloff based on log2 of active count to stay calming.
static func stacked_volume_db(base_db: float, active_count: int) -> float:
	if active_count <= 1:
		return base_db
	# Godot 4 provides log() (natural log); log2 = log(n)/log(2).
	var rolloff: float = STACK_ROLLOFF_DB * log(float(active_count)) / log(2.0)
	return base_db - rolloff
