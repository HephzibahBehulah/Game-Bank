extends SceneTree

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://soapbox_derby_progress.json"))
	var script := load("res://scripts/soapbox_derby_simulation.gd")
	assert(script != null and script.COURSES.size() == 8, "Eight authored hill courses load")
	for course_index in range(script.COURSES.size()):
		var sim = script.new()
		sim.reset(course_index)
		var course: Dictionary = script.COURSES[course_index]
		var ticks := 0
		while not sim.finished and not sim.crashed and ticks < 40000:
			var next_gate: Dictionary = course.gates[sim.gate_index] if sim.gate_index < course.gates.size() else {"at": 1.0e9, "lane": 0.0}
			var next_hazard: Dictionary = course.hazards[sim.hazard_index] if sim.hazard_index < course.hazards.size() else {"at": 1.0e9, "lane": 0.0}
			var target_lane := float(next_gate.lane)
			if float(next_hazard.at) < float(next_gate.at):
				target_lane = -0.68 if float(next_hazard.lane) >= 0.0 else 0.68
			var steer := 0.0
			if sim.distance >= minf(float(next_gate.at), float(next_hazard.at)) - 85.0:
				if absf(target_lane - sim.lane) > 0.08:
					steer = signf(target_lane - sim.lane)
			sim.step({"steer": steer, "brake": 0.0}, 0.05)
			ticks += 1
		assert(sim.finished and not sim.crashed and ticks < 40000, "%s is finishable with stable line control" % course.name)
		assert(sim.gates_hit == course.gates.size() and sim.gates_missed == 0, "%s awards all four clean line gates" % course.name)
		assert(sim.hazards_avoided == course.hazards.size(), "%s lets the driver avoid every marked hazard" % course.name)
		assert(sim.rating() in ["GOLD", "SILVER", "BRONZE"] and sim.score() > 0, "%s returns a scored medal result" % course.name)

	var crash_sim = script.new()
	crash_sim.reset(0)
	crash_sim.stability = 0.01
	crash_sim.lane = 0.98
	crash_sim.speed = 40.0
	crash_sim.step({"steer": 1.0, "brake": 0.0}, 0.05)
	assert(crash_sim.crashed and crash_sim.rating() == "DNF", "Loss of stability produces an explicit DNF")

	var scene := load("res://games/soapbox_derby.tscn")
	assert(scene != null, "Soapbox Derby scene resolves")
	var game: Node = scene.instantiate()
	root.add_child(game)
	await process_frame
	var right := InputEventJoypadButton.new()
	right.button_index = JOY_BUTTON_DPAD_RIGHT
	right.pressed = true
	game._unhandled_input(right)
	assert(game.selected_course == 0, "Locked course selection cannot skip ahead")
	var accept := InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	accept.pressed = true
	game._unhandled_input(accept)
	assert(game.mode == "race", "Gamepad A starts the derby")
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	start.pressed = true
	game._unhandled_input(start)
	assert(game.mode == "paused", "Gamepad Start pauses the race")
	game._unhandled_input(start)
	assert(game.mode == "race", "Gamepad Start resumes the race")
	game.sim.finished = true
	game._process(1.0 / 60.0)
	assert(game.mode == "results" and game.unlocked_courses == 2, "Finish shows results and unlocks the next course")
	var saved = JSON.parse_string(FileAccess.get_file_as_string("user://soapbox_derby_progress.json"))
	assert(saved is Dictionary and int(saved.get("completed_runs", 0)) == 1, "Best time and career progression persist")
	game.free()
	await process_frame
	var resumed: Node = scene.instantiate()
	root.add_child(resumed)
	await process_frame
	assert(resumed.completed_runs == 1 and resumed.unlocked_courses == 2, "Career progression reloads in a fresh game instance")
	resumed.free()
	await process_frame
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://games.json"))
	var found := false
	for entry in catalog:
		if int(entry.id) == 6:
			found = bool(entry.launchable) and entry.scene == "res://games/soapbox_derby.tscn"
	assert(found, "Completed course scene is registered as hub-launchable")
	print("PASS: eight hill routes, line gates, hazards, crash/end state, gamepad start/pause, saved progression, and hub launch.")
	quit(0)
