extends SceneTree

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://motorcycle_hill_progress.json"))
	var script := load("res://scripts/motorcycle_hill_simulation.gd")
	assert(script != null and script.COURSES.size() == 8, "Eight named mountain routes load")
	for course_index in range(script.COURSES.size()):
		var sim = script.new()
		sim.reset(course_index)
		var ticks := 0
		while not sim.finished and not sim.crashed and ticks < 30000:
			sim.step({"throttle": 1.0, "brake": 0.0, "lean": 0.0}, 0.05)
			ticks += 1
		assert(sim.finished and not sim.crashed and ticks < 30000, "%s is completable with controlled throttle and neutral pitch" % script.COURSES[course_index].name)
		assert(sim.jump_done and sim.rating() in ["GOLD", "SILVER", "BRONZE"], "%s clears its designed jump and scores finish" % script.COURSES[course_index].name)

	var jump_sim = script.new()
	jump_sim.reset(0)
	jump_sim.distance = float(script.COURSES[0].jump) - 0.001
	jump_sim.speed = 1.0
	jump_sim.step({"throttle": 0.0, "brake": 0.0, "lean": 0.0}, 0.05)
	assert(jump_sim.crashed and "SHORT JUMP" in jump_sim.event, "Insufficient takeoff speed fails at the gap")
	var pitch_sim = script.new()
	pitch_sim.reset(0)
	pitch_sim.pitch = 69.0
	pitch_sim.step({"throttle": 0.0, "brake": 0.0, "lean": 1.0}, 0.05)
	assert(pitch_sim.crashed and "LOOP-OUT" in pitch_sim.event, "Unsafe pitch ends the run")
	var controls_sim = script.new()
	controls_sim.reset(0)
	controls_sim.step({"throttle": 1.0, "brake": 0.0, "lean": 0.0}, 0.05)
	assert(controls_sim.speed > 0.0, "Throttle creates drive force")
	controls_sim.step({"throttle": 0.0, "brake": 1.0, "lean": 0.0}, 0.05)
	assert(controls_sim.speed < 1.5, "Brake applies strong deceleration")

	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://games.json"))
	var launchable_count := 0
	for entry in catalog:
		if bool(entry.get("launchable", false)):
			launchable_count += 1
			assert(ResourceLoader.exists(str(entry.get("scene", ""))), "Every completed hub card has a real scene")
	assert(launchable_count == 5, "Only five verified suite games are launchable")
	var scene := load("res://games/motorcycle_hill_climb.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)
	await process_frame
	var right := InputEventJoypadButton.new()
	right.button_index = JOY_BUTTON_DPAD_RIGHT
	right.pressed = true
	game._unhandled_input(right)
	assert(game.selected_course == 0, "Locked stages cannot be selected")
	var accept := InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	accept.pressed = true
	game._unhandled_input(accept)
	assert(game.mode == "ride", "Gamepad A starts the ride")
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	start.pressed = true
	game._unhandled_input(start)
	assert(game.mode == "paused", "Gamepad Start pauses")
	game._unhandled_input(start)
	assert(game.mode == "ride", "Gamepad Start resumes")
	game.simulation.finished = true
	game._process(1.0 / 60.0)
	assert(game.mode == "results" and game.unlocked_courses == 2, "Summit result unlocks stage two")
	var saved = JSON.parse_string(FileAccess.get_file_as_string("user://motorcycle_hill_progress.json"))
	assert(saved is Dictionary and int(saved.get("completed_courses", 0)) == 1, "Summit and best-time career data save")
	game.free()
	await process_frame
	var resumed: Node = scene.instantiate()
	root.add_child(resumed)
	await process_frame
	assert(resumed.completed_courses == 1 and resumed.unlocked_courses == 2, "Career data loads in a new session")
	resumed.free()
	await process_frame
	print("PASS: eight mountain routes, traction and pitch physics, jump success/failure, crash, gamepad, save/unlock, and hub scene wiring.")
	quit(0)


