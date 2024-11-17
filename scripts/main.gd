extends Node2D

signal gameOver(score)
signal waveComplete(score)

var enemySmallPrefab = preload("res://prefabs/enemySmall.tscn")
var enemyMediumPrefab = preload("res://prefabs/enemyMedium.tscn")
var enemyFlyingSmallPrefab = preload("res://prefabs/enemyFlyingSmall.tscn")
var numStartEnemies : int = 10

var startTime : float
var minSpawn : float = 1
var maxSpawn : float = 7
var timeToFastSpawn = 60*4
var spawnTime : float = 3
var spawnTimer : Timer
var score : int
var wallHP : int
var totalTime : float
var totalEnemies : int
var maxEnemies : int
var minMediumEnemyProb : float = 0.01
var maxMediumEnemyProb : float = 0.1
var minFlyingSmallEnemyProb : float = 0.05
var maxFlyingSmallEnemyProb : float = 0.15
var turretLockOnTime : float = 2
var numTurrets : int = 10
var numSearchlights : int
var searchlightTime : int
var searchlightSize : int

var isActive : bool

func SetWaveParameters(waveParameter):
	maxEnemies = waveParameter["maxEnemies"]
	numStartEnemies = waveParameter["numStartEnemies"]
	minSpawn = waveParameter["minSpawn"]
	maxSpawn = waveParameter["maxSpawn"]
	timeToFastSpawn = waveParameter["timeToFastSpawn"]
	spawnTime = waveParameter["spawnTime"]
	score = waveParameter["currentScore"]
	numSearchlights = waveParameter["numSearchlights"]
	searchlightTime = waveParameter["searchlightTime"]
	searchlightSize = waveParameter["searchlightSize"]
	$Searchlights.SetLights(numSearchlights, searchlightSize, searchlightTime)
	

func StartWave():
	isActive = true
	startTime = 0
	spawnTimer = Timer.new()
	self.add_child(spawnTimer)
	spawnTimer.connect("timeout", _on_spawn_timer_timeout)
	spawnTimer.wait_time = spawnTime
	spawnTimer.one_shot = true
	spawnTimer.start()
	totalTime = 0
	totalEnemies = 0
	
	call_deferred("initialSpawn")	
	wallHP = 100
	$CanvasLayer/Score.text = str(score)
	$CanvasLayer/TextureProgressBar.value = wallHP
	
func _on_enemy_died(points : int):
	score += points
	$CanvasLayer/Score.text = str(score)
	totalEnemies += 1
	if totalEnemies >= maxEnemies:
		waveComplete.emit(score)
	
func _on_enemy_attacked(damage : int):
	wallHP -= damage
	$CanvasLayer/TextureProgressBar.value = wallHP
	$CanvasLayer/TextureProgressBar.modulate = Color.DARK_RED.lerp(Color.WHITE, float(wallHP) / 100)
	if wallHP <= 0 and totalEnemies < maxEnemies:
		gameOver.emit(score)
	
func spawnEnemy(numSpawn : int):
	var numTargets = get_node("Map/SpawnPoints/").get_child_count()
	var enemy
	print("Spawning " + str(numSpawn))
	var randSpawn = randf()
	var medProb = lerp(minMediumEnemyProb, maxMediumEnemyProb,  min(1, startTime / timeToFastSpawn))
	var smallFlyProb = lerp(minFlyingSmallEnemyProb, maxFlyingSmallEnemyProb,  min(1, startTime / timeToFastSpawn))
	for i in range(numSpawn):
		if randSpawn <= medProb:
			enemy = enemyMediumPrefab.instantiate()
		elif randSpawn <= medProb + smallFlyProb:
			enemy = enemyFlyingSmallPrefab.instantiate()
		else:
			enemy = enemySmallPrefab.instantiate()
		self.add_child(enemy)
		enemy.connect("died", _on_enemy_died)
		enemy.connect("attacked", _on_enemy_attacked)
		enemy.global_position = get_node("Map/SpawnPoints/").get_children()[randi_range(0,numTargets-1)].global_position

func _on_spawn_timer_timeout():
	var numSpawnBase : float = lerp(minSpawn, maxSpawn, min(1, startTime / timeToFastSpawn)) 
	var spawnMod : float = (1 + 0.5*sin(startTime/6))
	var numSpawn = int(numSpawnBase	* spawnMod)
	spawnEnemy(numSpawn)
	spawnTimer.start()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func initialSpawn():
	spawnEnemy(numStartEnemies)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	startTime += delta
	totalTime += delta
	if Input.is_action_pressed("exit"):
		get_tree().quit()

