extends Node3D


func _ready():
	# We only need to spawn players on the server.
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

	# Spawn already connected players.
	for id in multiplayer.get_peers():
		add_player(id)

	# Spawn the local player unless this is a dedicated server export.
	if not OS.has_feature("dedicated_server"):
		add_player(1)


func _exit_tree():
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)


func add_player(id: int):
	$PlayerSpawner.spawn(id)


func del_player(id: int):
	prints("Peer disconnected", id)

	if not $Players.has_node(str(id)):
		return

	var player = $Players.get_node(str(id))
	PlayerStore.delete(player)
	player.queue_free()
