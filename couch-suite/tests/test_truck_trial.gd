extends SceneTree

func _run_checks() -> void:
	var script := load("res://scripts/truck_trial_simulation.gd")
	assert(script != null and script.COURSES.size() == 8, "Eight authored Truck Trial courses load")
	for course_index in range(script.COURSES.size()):
		var sim = script.new()
		sim.reset(course_index)
		var course: Dictionary = script.COURSES[course_index]
		var target_speed := 15.0
		var throttle := target_speed / (54.0 * (1.0 - float(course.roughness) * 0.2))
		var ticks := 0
		var crane_cleared := false
		while not sim.finished and not sim.rolled_over and ticks < 30000:
			sim.step({"throttle": throttle, "brake": 0.0, "crane": 1.0}, 0.05)
			if "CRANE CLEAR" in sim.last_event:
				crane_cleared = true
			ticks += 1
		assert(sim.finished and not sim.rolled_over and ticks < 30000, "%s has a completable safe route" % course.name)
		assert(sim.obstacle_index == course.obstacles.size(), "%s resolves every authored obstacle" % course.name)
		assert(sim.elapsed > 0.0 and sim.result_rating() in ["GOLD", "SILVER", "BRONZE"], "%s returns a timed finish rating" % course.name)
		if bool(course.get("crane", false)):
			assert(crane_cleared, "%s crane clears its authored obstacle during a full run" % course.name)

	var crane_sim = script.new()
	crane_sim.reset(3)
	for tick in range(30):
		crane_sim.step({"throttle": 0.0, "brake": 0.0, "crane": 1.0}, 0.05)
	assert(crane_sim.crane_angle > 0.9, "Right-stick crane input raises the articulated arm")

	var impact_sim = script.new()
	impact_sim.reset(0)
	var hazard: Dictionary = script.COURSES[0].obstacles[0]
	impact_sim.progress = float(hazard.at) - 0.1
	impact_sim.speed = 50.0
	impact_sim.step({"throttle": 1.0, "brake": 0.0}, 0.05)
	assert(impact_sim.obstacle_index == 1 and "HARD IMPACT" in impact_sim.last_event, "Fast obstacle entry produces a visible impact and body roll")
	var rollover_sim = script.new()
	rollover_sim.reset(0)
	rollover_sim.tilt = 47.5
	rollover_sim.progress = float(hazard.at) - 0.1
	rollover_sim.speed = 50.0
	rollover_sim.step({"throttle": 1.0, "brake": 0.0}, 0.05)
	assert(rollover_sim.rolled_over and rollover_sim.result_rating() == "ROLLOVER", "Exceeding 48 degrees ends the attempt")

	var scene := load("res://games/truck_trial.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)
	await process_frame
	var right := InputEventJoypadButton.new()
	right.button_index = JOY_BUTTON_DPAD_RIGHT
	right.pressed = true
	game._unhandled_input(right)
	assert(game.selected_course == 0, "Locked courses cannot be selected")
	var accept := InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	accept.pressed = true
	game._unhandled_input(accept)
	assert(game.mode == "drive", "Gamepad A starts the unlocked course")
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	start.pressed = true
	game._unhandled_input(start)
	assert(game.mode == "paused", "Gamepad Start pauses the drive")
	game._unhandled_input(start)
	assert(game.mode == "drive", "Gamepad Start resumes the drive")
	game.simulation.finished = true
	game._process(1.0 / 60.0)
	assert(game.mode == "results" and game.unlocked_courses == 2, "Finish produces a result and unlocks course two")
	var save = JSON.parse_string(FileAccess.get_file_as_string("user://truck_trial_progress.json"))
	assert(save is Dictionary and int(save.get("completed_courses", 0)) == 1, "Career result persists locally")
	game.free()
	await process_frame
	var resumed: Node = scene.instantiate()
	root.add_child(resumed)
	await process_frame
	assert(resumed.completed_courses == 1 and resumed.unlocked_courses == 2, "Career and unlock state reload in a new session")
	resumed.free()
	await process_frame
	print("PASS: 8 authored routes, hazard physics, rollover, crane, gamepad flow, results, unlock, and local save.")
	quit(0)

func _initialize() -> void:
	call_deferred("_run_checks")










