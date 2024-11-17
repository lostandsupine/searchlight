extends Control
signal startNextWave(optionChosen)

enum Options {none, addSearchlight, searchlightTime, searchlightSize}
var currentOption = Options.none
func SetScore(score, waveNum):
	$CanvasLayer/CurrentScore.text = "Current Score: " + str(score)
	$CanvasLayer/CurrentScore.visible = true
	$CanvasLayer/NextWave.text = "NextWave: " + str(waveNum)
	$CanvasLayer/NextWave.visible = true


func _on_button_start_pressed():
	startNextWave.emit(currentOption)


func _on_button_searchlight_pressed():
	currentOption = Options.addSearchlight


func _on_button_size_pressed():
	currentOption = Options.searchlightSize


func _on_button_time_pressed():
	currentOption = Options.searchlightTime
