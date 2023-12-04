extends Node

signal this_player_joined(player)

var players: Array[CharacterBody3D] = []


func add(player: CharacterBody3D) -> void:
	if player in players:
		return

	players.append(player)

	if player.player == multiplayer.get_unique_id():
		self.this_player_joined.emit(player)


func delete(player: CharacterBody3D) -> void:
	if not player in players:
		return

	players.erase(player)


func get_current() -> CharacterBody3D:
	for player in players:
		if player.player == multiplayer.get_unique_id():
			return player

	return null
