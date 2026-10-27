extends SceneTree

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://hovercraft_time_attack_progress.json"))
	var script := load("res://scripts/hovercraft_simulation.gd")
	assert(script != null and script.COURSES.size() == 8, "Eight authored water courses load")
	for course_index in range(script.COURSES.size()):
		var sim = script.new()
		sim.reset(course_index)
		var course: Dictionary = script.COURSES[course_index]
		var ticks := 0
		while not sim.finished and not sim.wrecked and ticks < 40000:
			var next_gate: Dictionary = course.gates[sim.gate_index] if sim.gate_index < course.gates.size() else {"at": 1.0e9, "lane": 0.0}
			var next_buoy: Dictionary = course.buoys[sim.buoy_index] if sim.buoy_index < course.buoys.size() else {"at": 1.0e9, "lane": 0.0}
			var target_lane := float(next_gate.lane)
			if float(next_buoy.at) < float(next_gate.at):
				target_lane = 0.68 if float(next_buoy.lane) <= 0.0 else -0.68
			var drift := sin(sim.distance * 0.008 + float(course_index) * 1.7) * float(course.wind) + sin(sim.distance * 0.003 + float(course_index)) * float(course.chop)
			var steering_power: float = 0.42 + sim.speed * 0.026
			var steer := clampf((target_lane - sim.lane) * 5.0 - drift / steering_power, -1.0, 1.0)
			sim.step({"steer": steer, "throttle": 1.0, "brake": 0.0, "boost": ticks % 240 < 100}, 0.05)
			ticks += 1
		assert(sim.finished and not sim.wrecked and ticks < 40000, "%s finishes with waterline controls" % course.name)
		assert(sim.gates_clean == course.gates.size() and sim.gates_missed == 0, "%s completes every racing gate" % course.name)
		assert(sim.buoys_avoided == course.buoys.size(), "%s avoids each authored buoy hazard" % course.name)
		assert(sim.rating() in ["GOLD", "SILVER", "BRONZE"] and sim.score() > 0, "%s produces finish rating and score" % course.name)

	var boost_sim = script.new()
	boost_sim.reset(0)
	boost_sim.step({"throttle": 1.0, "boost": true}, 0.05)
	assert(boost_sim.boost_energy < 100.0 and boost_sim.speed > 8.0, "Boost consumes charge while adding thrust")
	var wreck_sim = script.new()
	wreck_sim.reset(0)
	wreck_sim.integrity = 0.1
	wreck_sim.lane = 0.98
	wreck_sim.step({"steer": 1.0, "throttle": 1.0}, 0.05)
	assert(wreck_sim.wrecked and wreck_sim.rating() == "DNF", "Hull failure ends the race")

	var scene := load("res://games/hovercraft_time_attack.tscn")
	assert(scene != null, "Hovercraft scene resolves")
	var game: Node = scene.instantiate()
	root.add_child(game)
	await process_frame
	var right := InputEventJoypadButton.new()
	right.button_index = JOY_BUTTON_DPAD_RIGHT
	right.pressed = true
	game._unhandled_input(right)
	assert(game.selected_course == 0, "Locked course remains unavailable")
	var accept := InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	accept.pressed = true
	game._unhandled_input(accept)
	assert(game.mode == "race", "Gamepad A starts the time attack")
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	start.pressed = true
	game._unhandled_input(start)
	assert(game.mode == "paused", "Gamepad Start pauses")
	game._unhandled_input(start)
	assert(game.mode == "race", "Gamepad Start resumes")
	game.sim.finished = true
	game._process(1.0 / 60.0)
	assert(game.mode == "results" and game.unlocked_courses == 2, "Finish records result and unlocks course two")
	var saved = JSON.parse_string(FileAccess.get_file_as_string("user://hovercraft_time_attack_progress.json"))
	assert(saved is Dictionary and int(saved.get("completed_runs", 0)) == 1, "Career completion persists")
	game.free()
	await process_frame
	var resumed: Node = scene.instantiate()
	root.add_child(resumed)
	await process_frame
	assert(resumed.completed_runs == 1 and resumed.unlocked_courses == 2, "Career loads on new session")
	resumed.free()
	await process_frame
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://games.json"))
	var found := false
	for entry in catalog:
		if int(entry.id) == 7:
			found = bool(entry.launchable) and entry.scene == "res://games/hovercraft_time_attack.tscn"
	assert(found, "Hovercraft course is registered in the hub")
	print("PASS: eight water courses, gates, buoy avoidance, boost, hull DNF, gamepad, progression and catalog wiring.")
	quit(0)

