extends Node

var current_day: int = 1
var current_puzzle: String = "day_01_01"

var lies_told = 0
var attachment = 0

const ATTACHMENT_NAMES: Dictionary = {
	"low": "Distant",
	"middle": "Neutral",
	"high": "Close"
}

# Gameplay variables
var free_snacks = false

var puzzle_scores: Dictionary = {
	"day_01_01": {"score": false, "answer": []},
	"day_02_bird": {"score": false, "answer": []},
	"day_02_cookie": {"score": false, "answer": []},
}

func set_current_puzzle(puzzle_name: String):
	current_puzzle = puzzle_name

func add_answer(puzzle_id: String, correct_answer: String) -> void:
	if puzzle_scores.has(puzzle_id):
		if correct_answer not in puzzle_scores[puzzle_id]["answer"]:
			puzzle_scores[puzzle_id]["answer"].append(correct_answer)
			print("Answer added for", puzzle_id, ":", correct_answer)
		else:
			print("Answer already exists for", puzzle_id, ":", correct_answer)
	else:
		print("Puzzle ID not found:", puzzle_id)

func is_correct_answer(provided_answer: String) -> bool:
	if puzzle_scores.has(current_puzzle):
		var is_correct = provided_answer in puzzle_scores[current_puzzle]["answer"]
		puzzle_scores[current_puzzle]["score"] = is_correct  # Update the score
		print_all_scores()  # Print all scores after updating
		return is_correct
	else:
		print("Puzzle ID not found:", current_puzzle)
		return false

func print_all_scores() -> void:
	print("Current Puzzle Scores:")
	for puzzle_id in puzzle_scores.keys():
		var score = puzzle_scores[puzzle_id]["score"]
		print("- ", puzzle_id, ": ", score)

func get_total_score() -> int:
	var total_score = 0
	for puzzle_id in puzzle_scores.keys():
		if puzzle_scores[puzzle_id]["score"]:
			total_score += 1
	return total_score

func get_attachment_name() -> String:
	if attachment < -1:
		return ATTACHMENT_NAMES["low"]
	elif attachment > 5:
		return ATTACHMENT_NAMES["high"]
	else:
		return ATTACHMENT_NAMES["middle"]

func reset():
	current_day = 1
	current_puzzle = "day_01_01"
	lies_told = 0
	attachment = 0
	free_snacks = false

	# Reset puzzle scores
	for puzzle_id in puzzle_scores.keys():
		puzzle_scores[puzzle_id]["score"] = false
		puzzle_scores[puzzle_id]["answer"] = []

	print("Game has been reset!")
