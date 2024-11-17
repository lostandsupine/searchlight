extends Node2D

@export var minSpeed : float = 50
@export var maxSpeed : float = 600
@export var maxSpeedDistance : float = 500
var mousePosition : Vector2
var isActive : bool
var inactiveTime : float
var minSize : float = 0.08
var minSizeTime : float
var baseSize : float
var myLightNum : int

func SetLightNum(lightNum):
	myLightNum = lightNum

func SetSize(size):
	baseSize = 1 + sqrt(size-1) * 0.333
	self.scale = Vector2.ONE * baseSize
	
func SetTime(time):
	minSizeTime = 10 + sqrt(time-1) * 3.333
	
# Called when the node enters the scene tree for the first time.
func _ready():
	isActive = false

func SetActive(active : bool):
	if active:
		self.scale = Vector2.ONE * baseSize
	elif isActive != active:
		inactiveTime = 0
	
	isActive = active

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if isActive:
		mousePosition = get_global_mouse_position()
		var distance = (mousePosition - self.global_position).length()
		var speed = lerp(minSpeed, maxSpeed, distance / maxSpeedDistance)
		self.global_position += (mousePosition - self.global_position).normalized() * speed * delta
		self.global_position.x = clamp(self.global_position.x, 0, 1280)
		self.global_position.y = clamp(self.global_position.y, 0, 720)
	else:
		inactiveTime += delta
		self.scale = Vector2.ONE * lerp(baseSize, minSize, min(1, inactiveTime / minSizeTime))


func _on_area_2d_body_entered(body):
	body.EnteredLight(myLightNum)
	pass # Replace with function body.


func _on_area_2d_body_exited(body):
	body.ExitedLight(myLightNum)
	pass # Replace with function body.
