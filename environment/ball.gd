extends RigidBody3D


@onready var original_parent = get_parent()
@onready var CurrentPlayer: CharacterBody3D = null
var in_carry: CharacterBody3D = null

func _ready() -> void:
	PlayerStore.this_player_joined.connect(self._player_found)


func _player_found(player: CharacterBody3D) -> void:
	self.CurrentPlayer = player


func highlight() -> void:
	$Outline.show()


@rpc("call_local", "authority")
func throw(from: Vector3) -> void:
	var vector = (self.global_position - from).normalized()

	self.set_carry_mode(null)

	self.apply_central_impulse(vector * 8)
	self.apply_impulse(vector * 80, self.global_position - from)


func start_carry() -> void:
	self.set_freeze_enabled(true)


func end_carry() -> void:
	self.set_freeze_enabled(false)


@rpc("call_local", "authority")
func set_carry_mode(new_carrier: CharacterBody3D) -> void:
	in_carry = new_carrier
	$Outline.set_visible(not not new_carrier)

	if not new_carrier:
		end_carry()
	else:
		start_carry()


func _physics_process(_delta) -> void:
	if in_carry == CurrentPlayer:
		self.set_global_transform(in_carry.BallCarrier.global_transform)
		return

	if not CurrentPlayer:
		return

	if not CurrentPlayer.BallSelector.is_colliding():
		$Outline.hide()

	if CurrentPlayer.BallSelector.get_collider() != self:
		$Outline.hide()
