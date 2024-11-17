extends Control

func SetScore(score, waveNum):
	$CanvasLayer/FinalScore.text = "Final Score: " + str(score) + "  Final Wave: " + str(waveNum)
	$CanvasLayer/FinalScore.visible = true

