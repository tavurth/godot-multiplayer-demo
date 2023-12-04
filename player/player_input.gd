# player_input.gd
extends MultiplayerSynchronizer

# Set via RPC to simulate is_action_just_pressed.
@export var jumping := false

# Synchronized property.
@export var direction := Vector3()

@onready var player: CharacterBody3D = null

func _init() -> void:
	set_process(false)
	PlayerStore.this_player_joined.connect(self._player_found)


func _player_found(this_player: CharacterBody3D) -> void:
	self.player = this_player


func _ready() -> void:
	self.player = PlayerStore.get_current()


func setup_multiplayer_master(is_master: bool) -> void:
	prints("Setting master input for", self.name, is_master)

	# Only process for the local player.
	set_process(is_master)
	set_process_input(is_master)


@rpc("call_local", "authority")
func jump():
	if not player.is_on_floor():
		return

	if jumping:
		return

	if player.global_position.y < player.WATER_LEVEL:
		return

	jumping = true
	player.play_anim("jump")
	await get_tree().create_timer(0.05).timeout

	player.velocity.y += player.JUMP

	await get_tree().create_timer(0.1).timeout
	jumping = false


@rpc("call_local", "authority")
func action_drop() -> void:
	for child in player.carrying:
		if child.has_method("set_carry_mode"):
			child.set_carry_mode.rpc(null)
			player.carrying.erase(child)


@rpc("call_local", "authority")
func action_throw() -> void:
	for child in player.carrying:
		if child.has_method("throw"):
			child.throw.rpc(player.Camera.global_position)
			player.carrying.erase(child)


@rpc("call_local", "authority")
func action_pickup() -> void:
	if player.BallCarrier.get_child_count() > 0:
		action_drop.rpc()
		return

	if not player.BallSelector.is_colliding():
		return

	var collider = player.BallSelector.get_collider()
	if collider.has_method("set_carry_mode"):
		player.carrying.append(collider)
		collider.set_carry_mode.rpc(PlayerStore.get_current())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action_pickup"):
		action_pickup.rpc()

	if event.is_action_pressed("action_throw"):
		action_throw.rpc()


func apply_friction(delta: float) -> void:
	direction *= Vector3.ONE - Vector3(0.9, 1.0, 0.9) * (10 * delta)


func _process(delta: float) -> void:
	"""
	Allow the player to move the camera with WASD
	See Project settings -> Input map for keyboard bindings
	"""
	if not player:
		return

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var new_direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var amount: float = 1

	if not player.is_on_floor() or jumping:
		amount = 0.2

	if Input.is_action_just_pressed("action_jump"):
		jump.rpc()

	# Apply friction
	if player.is_on_floor():
		apply_friction(delta)

	direction.x += new_direction.x * amount
	direction.z += new_direction.y * amount
	direction = direction.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))
