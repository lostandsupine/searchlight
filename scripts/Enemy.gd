extends CharacterBody2D

signal died(points)
signal attacked(damage)
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
var isFlipped : bool
enum EnemyState {spawning, toWaypoint, toTarget, attacking, dying, dead, hit}
var currentState : EnemyState
var lastState : EnemyState
var targetDistance : float = 5
@export var movementSpeed : float = 21
@export var hitPoints : int = 2
var hitTimer : Timer
@export var hitTime : float = 1.05
var deadTimer : Timer
var deadTime : float = 3
@export var points : int = 1
@export var damage : int = 1

var hitSounds : Array
var dieSounds : Array
var attackSounds : Array
var isInLights : Array[bool]
@export var isFlying : bool = false

func isInLight() -> bool :
	var isInTheLight : bool = false
	return isInLights[0] or isInLights[1] or isInLights[2]

func EnteredLight(lightNum : int):
	# print("Im in the light: " + str(lightNum))
	if currentState != EnemyState.dead and currentState != EnemyState.dying and !isInLight():
		hitTimer.start()
		$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)
	isInLights[lightNum] = true
	
func ExitedLight(lightNum : int):
	# print("Im out of light: " + str(lightNum))
	isInLights[lightNum] = false
	if currentState != EnemyState.dead and currentState != EnemyState.dying and !isInLight():
		# print("I'm out of all lights!")
		$AnimatedSprite2D.modulate = Color(1, 1, 1, 0.45)
		hitTimer.stop()

func _on_hitTimer_timeout():
	#print("Im hit!")
	hitPoints -= 1
	lastState = currentState
	if hitPoints <= 0:
		currentState = EnemyState.dying
		hitTimer.stop()
		died.emit(points)
	else:
		currentState = EnemyState.hit
	$AnimatedSprite2D.play("hit")
	$AudioStreamPlayer.stream = hitSounds[randi_range(0,hitSounds.size()-1)]
	$AudioStreamPlayer.play()
	$Line.visible = true
	$Line.look_at(Vector2(randf_range(0, 1280), 730))
	
func _on_deadTimer_timeout():
	self.queue_free.call_deferred()

func _ready():
	$Line.visible = false
	hitTimer = Timer.new()
	self.add_child(hitTimer)
	hitTimer.wait_time = hitTime
	hitTimer.connect("timeout", _on_hitTimer_timeout)
	
	deadTimer = Timer.new()
	self.add_child(deadTimer)
	deadTimer.wait_time = deadTime
	deadTimer.connect("timeout", _on_deadTimer_timeout)
	
	navigation_agent.path_desired_distance = 10.0
	navigation_agent.target_desired_distance = 1.0
	navigation_agent.max_speed = movementSpeed
	navigation_agent.radius = 2
	isFlipped = false
	
	hitSounds.append(preload("res://assets/sounds/hit_sound_0.wav"))
	hitSounds.append(preload("res://assets/sounds/hit_sound_1.wav"))
	hitSounds.append(preload("res://assets/sounds/hit_sound_2.wav"))
	
	dieSounds.append(preload("res://assets/sounds/die.wav"))
	dieSounds.append(preload("res://assets/sounds/die_1.wav"))

	
	attackSounds.append(preload("res://assets/sounds/attack_0.wav"))
	attackSounds.append(preload("res://assets/sounds/attack_1.wav"))
	attackSounds.append(preload("res://assets/sounds/attack_2.wav"))
	
	isInLights = []
	for i in range(30):
		isInLights.append(false)
	currentState = EnemyState.spawning
	
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 0.45)
	
	
func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	if isFlying:
		var numTargets = get_node("../Map/TargetPoints/").get_child_count()
		navigation_agent.target_position = get_node("../Map/TargetPoints/").get_children()[randi_range(0,numTargets-1)].global_position
		currentState = EnemyState.toTarget
	else:
		var numTargets = get_node("../Map/Waypoints/").get_child_count()
		navigation_agent.target_position = get_node("../Map/Waypoints/").get_children()[randi_range(0,numTargets-1)].global_position
		currentState = EnemyState.toWaypoint
	
func _physics_process(delta):
	match currentState:
		EnemyState.spawning:
			#print("Spawning")
			call_deferred("actor_setup")
		EnemyState.toWaypoint:
			var next_path_position : Vector2 = navigation_agent.get_next_path_position()
			var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movementSpeed
			_on_velocity_computed(new_velocity)
			
			move_and_slide()
			if velocity.x > 0 and isFlipped:
				get_node("AnimatedSprite2D").flip_h = 0
				$CPUParticles2D.position = Vector2(-13, -1)
				isFlipped = false
			if velocity.x < 0 and not isFlipped:
				get_node("AnimatedSprite2D").flip_h = 1
				$CPUParticles2D.position = Vector2(-13, -1)
				isFlipped = true
			
			if navigation_agent.target_position.distance_to(self.global_position) <= targetDistance:
				var numTargets = get_node("../Map/TargetPoints/").get_child_count()
				navigation_agent.target_position = get_node("../Map/TargetPoints/").get_children()[randi_range(0,numTargets-1)].global_position
				currentState = EnemyState.toTarget
		
		EnemyState.toTarget:
			if isFlying:
				velocity = global_position.direction_to(navigation_agent.target_position) * movementSpeed
				move_and_slide()
			else:
				var next_path_position : Vector2 = navigation_agent.get_next_path_position()
				var new_velocity: Vector2 = global_position.direction_to(next_path_position) * movementSpeed
				_on_velocity_computed(new_velocity)
				move_and_slide()
			
			
			if velocity.x > 0 and isFlipped:
				get_node("AnimatedSprite2D").flip_h = 0
				$CPUParticles2D.position = Vector2(13, -1)
				isFlipped = false
			if velocity.x < 0 and not isFlipped:
				get_node("AnimatedSprite2D").flip_h = 1
				$CPUParticles2D.position = Vector2(-13, -1)
				isFlipped = true
			
			if navigation_agent.target_position.distance_to(self.global_position) <= targetDistance:
				#print("Starting attack")
				currentState = EnemyState.attacking
				$AnimatedSprite2D.play("attack")
			
		EnemyState.attacking:
			pass
		
		EnemyState.hit:
			pass
		
		EnemyState.dead:
			pass

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity 


func _on_animated_sprite_2d_animation_finished():
	if currentState == EnemyState.dying:
		currentState = EnemyState.dead
		$AnimatedSprite2D.play("dead")
		$AudioStreamPlayer.stream = dieSounds[randi_range(0, dieSounds.size()-1)]
		$AudioStreamPlayer.play()
		deadTimer.start()
		$Line.visible = false
			
	elif currentState == EnemyState.hit:	
		currentState = lastState
		$Line.visible = false
		if lastState == EnemyState.attacking:
			$AnimatedSprite2D.play("attack")
		else:
			$AnimatedSprite2D.play("default")
				


func _on_animated_sprite_2d_animation_looped():
	if currentState == EnemyState.attacking:
		$AudioStreamPlayer.stream = attackSounds[randi_range(0, attackSounds.size()-1)]
		$AudioStreamPlayer.play()
		attacked.emit(damage)
		$CPUParticles2D.emitting = true
