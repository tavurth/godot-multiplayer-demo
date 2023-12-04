extends MultiplayerSpawner


const SPAWN_RANDOM := 3.0

func _ready():
	set_spawn_function(self.spawn_player)


func spawn_player(id: int) -> Node:
	prints("Peer connected", id)

	var character = preload("res://player/Player.tscn").instantiate()

	# Set player id.
	character.player = id
	PlayerStore.add(character)

	# Randomize character position.
	var pos := Vector2.from_angle(randf() * 2 * PI)

	character.position = Vector3(
		pos.x * SPAWN_RANDOM * randf(),
		0,
		pos.y * SPAWN_RANDOM * randf()
	)

	return character
