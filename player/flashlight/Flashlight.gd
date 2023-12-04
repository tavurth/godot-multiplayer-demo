extends Node3D

signal toggled(on_off);


@export var enabled: bool = false:
	set(new_val):
		enabled = new_val
		
		self.set_visible(enabled)


@rpc("call_local", "authority")
func toggle() -> void:
	self.enabled = !enabled
	$Sound.pitch_scale = 1.1 if enabled else 0.9
	$Sound.play()

	self.toggled.emit(enabled)


func setup_multiplayer_master(is_master: bool) -> void:
	$Cone.set_visible(not is_master)


func _input(event: InputEvent):
	if multiplayer.get_unique_id() != get_multiplayer_authority():
		return
	
	if event.is_action_pressed("action_flashlight"):
		toggle.rpc()
