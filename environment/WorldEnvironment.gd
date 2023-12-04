extends WorldEnvironment


func _ready():
	$Sun.shadow_enabled = Options.high_quality
	self.environment.sky.set_radiance_size(
		Sky.RADIANCE_SIZE_2048 if Options.high_quality else Sky.RADIANCE_SIZE_64
	)
