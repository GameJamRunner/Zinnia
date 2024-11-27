extends Node

var puzzle_scores: Dictionary = {
	"day_01_01": {"score": false, "answer": []},
	"day_02_01": {"score": false, "answer": []},
}

func add_answer(puzzle_id: String, correct_answer: String) -> void:
	if puzzle_scores.has(puzzle_id):
		if correct_answer not in puzzle_scores[puzzle_id]["answer"]:
			puzzle_scores[puzzle_id]["answer"].append(correct_answer)
			print("Answer added for", puzzle_id, ":", correct_answer)
		else:
			print("Answer already exists for", puzzle_id, ":", correct_answer)
	else:
		print("Puzzle ID not found:", puzzle_id)
