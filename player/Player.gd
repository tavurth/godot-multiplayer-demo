extends CharacterBody3D

const WATER_LEVEL = -7

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") / 100

var carrying: Array = []

# Set by the authority, synchronized on spawn.
@export var player := 1 :
	set(id):
		prints("Setting player ID", id)
		player = id
		self.name = str(id)
		set_multiplayer_authority(id)

		$Camera.set_multiplayer_authority(id)
		%Flashlight.set_multiplayer_authority(id)
		$PlayerInput.set_multiplayer_authority(id)

		%BallCarrier.set_multiplayer_authority(id)
		$BallSelector.set_multiplayer_authority(id)


@export var JUMP := 20
@export var PLAYER_MOVE_SPEED := 8

@onready var BallCarrier = %BallCarrier
@onready var BallSelector = $BallSelector

@onready var Camera = $Camera
@onready var input: MultiplayerSynchronizer = $PlayerInput
@onready var animations = $character/AnimationPlayer
@onready var skeleton: Skeleton3D = get_node("character/Character/Skeleton3D")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_position"):
		print(self.global_position.y)


func setup_multiplayer_master() -> void:
	var is_master =  multiplayer.get_unique_id() == get_multiplayer_authority()

	# Give authority over the player input to the appropriate peer.
	$Camera.setup_multiplayer_master(is_master)
	%Flashlight.setup_multiplayer_master(is_master)
	$PlayerInput.setup_multiplayer_master(is_master)

	for item in ["Head", "LightOn", "LightOff", "Torch"]:
		skeleton.get_node(item).set_visible(not is_master)


func _ready() -> void:
	self.setup_multiplayer_master()

	animations.set_default_blend_time(0.2)

	# Only process on server.
	# EDIT: Let the client simulate player movement too to compesate network input latency.
	# set_physics_process(multiplayer.is_server())


func play_anim(new_name: String) -> void:
	if animations.current_animation == new_name:
		return

	animations.play(new_name)


func blend_animations() -> void:
	if not self.is_on_floor():
		return

	if input.jumping:
		return

	if input.direction.z < -0.1:
		play_anim("run-forward")
	elif input.direction.z > +0.1:
		play_anim("run-back")

	elif input.direction.x > +0.1:
		play_anim("run-right")
	elif input.direction.x < -0.1:
		play_anim("run-left")

	else:
		play_anim("idle")


func _physics_process(_delta: float) -> void:
	# Preserve the Y velocity from the previous frame
	self.velocity = Vector3(0, self.velocity.y, 0)

	# Always add velocity even when we're in the air
	self.velocity += get_transform().basis.x * input.direction.x * PLAYER_MOVE_SPEED
	self.velocity += get_transform().basis.z * input.direction.z * PLAYER_MOVE_SPEED

	# Apply less gravity if we were on the floor last frame
	# This helps our KinematicBody to avoid physics jitter
	if self.is_on_floor():
		self.velocity -= Vector3(0, gravity / 10, 0)
	else:
		self.velocity -= Vector3(0, gravity, 0)

	# Play the run/strafe/idle animation
	self.blend_animations()

	# Move back towards the center if too far away
	var future = self.global_position + self.velocity
	if future.distance_squared_to(Vector3()) > 12500:
		self.velocity = -(self.global_position.normalized() * PLAYER_MOVE_SPEED)

	self.move_and_slide()

	if BallSelector.is_colliding():
		var collider = BallSelector.get_collider()
		if collider.has_method("highlight"):
			collider.highlight()

	# Show the underwater effect
	$Underwater.set_visible(self.global_position.y < WATER_LEVEL)

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if not collider is RigidBody3D:
			continue

		collider.apply_central_impulse(-collision.get_normal() * 4)
		collider.apply_impulse(-collision.get_normal() * 0.01, collision.get_position())


func _on_flashlight_toggled(on_off: bool) -> void:
	if not skeleton:
		return
	
	skeleton.get_node("LightOn").set_visible(on_off)
	skeleton.get_node("LightOff").set_visible(not on_off)
