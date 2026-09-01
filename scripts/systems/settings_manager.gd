extends Node
## Autoload singleton ("SettingsManager"). Add this script as an Autoload named
## "SettingsManager" in Project Settings > Autoload.
##
## Loads user preferences from user://settings.cfg on startup, applies them
## (fullscreen mode + master volume), and saves them back whenever they change.
## This keeps display/audio preferences persistent across sessions and lets any
## UI (settings menu, pause menu) read/write them through one place.

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "settings"

## Current persisted fullscreen state (true = fullscreen, false = windowed).
var fullscreen: bool = false
## Current persisted master volume in linear 0..1.
var master_volume: float = 0.8


func _ready() -> void:
	_load()
	_apply()


## Set and persist fullscreen state, applying it immediately.
func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()
	_save()


## Set and persist the master volume (linear 0..1), applying it immediately.
func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	_save()


# ── Loading / saving ──

func _load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	fullscreen = bool(cfg.get_value(SECTION, "fullscreen", fullscreen))
	master_volume = clampf(float(cfg.get_value(SECTION, "volume", master_volume)), 0.0, 1.0)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "fullscreen", fullscreen)
	cfg.set_value(SECTION, "volume", master_volume)
	cfg.save(SETTINGS_PATH)


# ── Applying ──

func _apply() -> void:
	_apply_fullscreen()
	_apply_volume()


func _apply_fullscreen() -> void:
	# When the game runs embedded in the editor's Game tab it shares the editor
	# window, so the OS window mode can't actually change. Skip applying (but we
	# still persist the choice) — fullscreen applies in standalone runs/exports.
	if Engine.is_embedded_in_editor():
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus == -1:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(master_volume))
	AudioServer.set_bus_mute(bus, master_volume <= 0.0)
