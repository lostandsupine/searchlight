extends Node2D

var lightPrefab = preload("res://prefabs/searchlight.tscn")
var pointLights : Array
var activeLightNum : int
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

func SetLights(numLights, size, time):
	activeLightNum = 0
	pointLights = []
	for i in range(numLights):
		var light = lightPrefab.instantiate()
		light.SetSize(size)
		light.SetTime(time)
		light.SetLightNum(i)
		self.add_child(light)
		pointLights.append(light)
		
	
	pointLights[0].SetActive(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("leftClick"):
		activeLightNum = (activeLightNum+1) % pointLights.size()
		for pointLight in pointLights:
			pointLight.SetActive(false)
		pointLights[activeLightNum].SetActive(true)
	elif Input.is_action_just_pressed("rightClick"):
		activeLightNum = (activeLightNum-1) % pointLights.size()
		for pointLight in pointLights:
			pointLight.SetActive(false)
		pointLights[activeLightNum].SetActive(true)
