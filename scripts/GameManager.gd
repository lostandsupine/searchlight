extends Node

enum Options {none, addSearchlight, searchlightTime, searchlightSize}
enum GameState {menu, intro, main, gameOver, waveComplete}
var currentState : GameState
var minWaitTime : float = 0.25
var isReady : bool

var menuPrefab = preload("res://scenes/menu.tscn")
var introPrefab = preload("res://scenes/intro.tscn")
var mainPrefab = preload("res://scenes/main.tscn")
var gameOverPrefab = preload("res://scenes/gameover.tscn")
var waveCompletePrefab = preload("res://scenes/waveComplete.tscn")

var menu
var intro
var main
var gameOver
var waveComplete

var waveNum : int
var currentScore : int
var numSearchlights : int
var searchlightSize : int
var searchlightTime : int

var waveParameters : Dictionary

func _on_min_wait_timer_timeout():
	isReady = true
	
func _on_waveComplete_start(option):
	if currentState != GameState.waveComplete:
		return
		
	waveComplete.queue_free()
	main = mainPrefab.instantiate()
	main.connect("gameOver", _on_main_gameOver)
	main.connect("waveComplete", _on_main_waveComplete)
	self.add_child(main)
	$MinWaitTimer.start()
	isReady = false
	currentState = GameState.main
	
	match option:
		Options.none:
			pass
		Options.addSearchlight:
			numSearchlights += 1
		Options.searchlightSize:
			searchlightSize += 1
		Options.searchlightTime:
			searchlightTime += 1
	
	waveParameters = updateWaveParameters(waveParameters)
	main.SetWaveParameters(waveParameters)
	main.StartWave.call_deferred()

func _on_main_gameOver(score):
	if currentState != GameState.main:
		return
		
	gameOver =  gameOverPrefab.instantiate()
	main.queue_free()
	self.add_child(gameOver)
	isReady = false
	$MinWaitTimer.start()
	currentState = GameState.gameOver
	currentScore = score
	gameOver.SetScore(currentScore, waveNum)
	
	
func _on_main_waveComplete(score):
	if currentState != GameState.main:
		return
		
	waveComplete =  waveCompletePrefab.instantiate()
	main.queue_free()
	self.add_child(waveComplete)
	waveComplete.connect("startNextWave", _on_waveComplete_start)
	isReady = false
	$MinWaitTimer.start()
	waveNum += 1
	currentState = GameState.waveComplete
	currentScore = score
	waveComplete.SetScore(currentScore, waveNum)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	currentState = GameState.menu
	$MinWaitTimer.wait_time = minWaitTime
	$MinWaitTimer.start()
	isReady = false
	menu = menuPrefab.instantiate()
	self.add_child(menu)
	waveNum = 0
	numSearchlights = 1
	searchlightSize = 1
	searchlightTime = 1
	
	waveParameters = {"maxEnemies" : 20,
		"numStartEnemies": 5,
		"minSpawn": 1,
		"maxSpawn": 7,
		"timeToFastSpawn": 60*4,
		"spawnTime": 3,
		"numSearchlights": numSearchlights,
		"searchlightSize": searchlightSize,
		"searchlightTime": searchlightTime}

	
func updateWaveParameters(waveParameters):
	var newWaveParameters = waveParameters.duplicate()
	newWaveParameters["maxEnemies"] = 20 + waveNum * 20
	newWaveParameters["numStartEnemies"] = 5 + waveNum * 5
	newWaveParameters["minSpawn"] = 1 + waveNum * 0.25
	newWaveParameters["maxSpawn"] = 7 + waveNum * 0.5
	newWaveParameters["timeToFastSpawn"] = max(60*4 - waveNum * 10, 60)
	newWaveParameters["spawnTime"] = max(3 - waveNum * 0.1, 0.5)
	
	newWaveParameters["currentScore"] = currentScore
	newWaveParameters["numSearchlights"] = numSearchlights
	newWaveParameters["searchlightSize"] = searchlightSize
	newWaveParameters["searchlightTime"] = searchlightTime
	return newWaveParameters
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match currentState:
		GameState.menu:
			if Input.is_action_pressed("exit"):
				get_tree().quit()
			elif Input.is_anything_pressed() and isReady:
				menu.queue_free()
				intro = introPrefab.instantiate()
				self.add_child(intro)
				$MinWaitTimer.start()
				isReady = false
				currentState = GameState.intro
				currentScore = 0
		GameState.gameOver:
			if Input.is_action_pressed("exit"):
				get_tree().quit()
			elif Input.is_anything_pressed() and isReady:
				gameOver.queue_free()
				currentScore = 0
				waveNum = 0
				numSearchlights = 1
				searchlightSize = 1
				searchlightTime = 1
				intro = introPrefab.instantiate()
				self.add_child(intro)
				$MinWaitTimer.start()
				isReady = false
				currentState = GameState.intro
		GameState.intro:
			if Input.is_action_pressed("exit"):
				get_tree().quit()
			elif Input.is_anything_pressed() and isReady:
				intro.queue_free()
				main = mainPrefab.instantiate()
				main.connect("gameOver", _on_main_gameOver)
				main.connect("waveComplete", _on_main_waveComplete)
				self.add_child(main)
				$MinWaitTimer.start()
				isReady = false
				currentState = GameState.main
				waveParameters = updateWaveParameters(waveParameters)
				main.SetWaveParameters(waveParameters)
				main.StartWave.call_deferred()
		GameState.waveComplete:
			if Input.is_action_pressed("exit"):
				get_tree().quit()
