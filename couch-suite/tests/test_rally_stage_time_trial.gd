extends SceneTree

func _initialize() -> void:
    call_deferred("_run_checks")

func _run_checks() -> void:
    var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://games.json"))
    assert(catalog is Array and catalog.size() == 100, "The hub catalog lists all 100 planned games")
    var launchable_count := 0
    for entry in catalog:
        if bool(entry.get("launchable",false)):
            launchable_count += 1
            assert(ResourceLoader.exists(str(entry.get("scene",""))), "Every launchable catalog item has a real scene")
    assert(launchable_count == 5, "Only the five completed couch games are launchable")
    var hub_scene = load("res://scenes/hub.tscn")
    var hub = hub_scene.instantiate()
    root.add_child(hub)
    await process_frame
    assert(hub.games.size() == 100 and hub.list_box.get_child_count() == 100, "Hub displays all 100 game rows")
    hub.free()
    var simulation_script = load("res://scripts/rally_stage_simulation.gd")
    assert(simulation_script != null, "Rally simulation script loads")
    assert(simulation_script.STAGES.size() == 10, "Ten authored point-to-point routes are defined")
    var sim = simulation_script.new()
    var controls := {"steer":0.0,"throttle":1.0,"brake":0.0,"handbrake":false}
    for stage_index in range(10):
        sim.reset(stage_index)
        assert(sim.route_length > 900.0, "Stage %d has a full route" % (stage_index+1))
        assert(simulation_script.STAGES[stage_index].notes.size() >= 4, "Stage %d has authored co-driver notes" % (stage_index+1))
        var ticks := 0
        while not sim.finished and ticks < 3000:
            var turn: float = sim.tangent_at(sim.distance).cross(sim.tangent_at(sim.distance + 90.0))
            controls.steer = signf(turn) * clampf(absf(turn) * sim.speed * 0.30 / 82.0, 0.0, 1.0)
            sim.step(controls,1.0/60.0)
            ticks += 1
        assert(sim.finished, "Stage %d reaches its finish gate" % (stage_index+1))
        assert(sim.elapsed <= float(simulation_script.STAGES[stage_index].target), "Stage %d target is achievable with clean driving" % (stage_index+1))
    var packed_scene = load("res://games/rally_stage_time_trial.tscn")
    assert(packed_scene != null, "Rally playable scene loads")
    var game = packed_scene.instantiate()
    root.add_child(game)
    await process_frame
    assert(game.mode == "stage_select", "Scene opens in route selection")
    var right_dpad := InputEventJoypadButton.new()
    right_dpad.button_index = JOY_BUTTON_DPAD_RIGHT
    right_dpad.pressed = true
    game._unhandled_input(right_dpad)
    assert(game.selected_stage == 0, "Gamepad D-pad cannot select a locked route")
    var left_dpad := InputEventJoypadButton.new()
    left_dpad.button_index = JOY_BUTTON_DPAD_LEFT
    left_dpad.pressed = true
    game._unhandled_input(left_dpad)
    assert(game.selected_stage == 0, "Gamepad D-pad keeps the only unlocked route selected")
    var start_button := InputEventJoypadButton.new()
    start_button.button_index = JOY_BUTTON_A
    start_button.pressed = true
    game._unhandled_input(start_button)
    assert(game.mode == "race", "Gamepad A can start a stage")
    var start_pause := InputEventJoypadButton.new()
    start_pause.button_index = JOY_BUTTON_START
    start_pause.pressed = true
    game._unhandled_input(start_pause)
    assert(game.mode == "paused", "Gamepad Start pauses during a stage")
    game._unhandled_input(start_pause)
    assert(game.mode == "race", "Gamepad Start resumes a paused stage")
    var cancel := InputEventAction.new()
    cancel.action = "ui_cancel"
    cancel.pressed = true
    game._unhandled_input(cancel)
    assert(game.mode == "paused", "Cancel pauses an active stage")
    game._unhandled_input(cancel)
    assert(game.mode == "stage_select", "Cancel returns from pause to route selection")
    var accept := InputEventAction.new()
    accept.action = "ui_accept"
    accept.pressed = true
    game._unhandled_input(accept)
    var slow_controls := {"steer":0.0,"throttle":0.2,"brake":0.0,"handbrake":false}
    var slow_ticks := 0
    while not game.simulation.finished and slow_ticks < 3000:
        game.simulation.step(slow_controls,1.0/60.0)
        slow_ticks += 1
    assert(game.simulation.finished, "Slow run reaches the finish for a target-miss result")
    game._process(1.0/60.0)
    assert(game.mode == "result" and not game.qualified, "Missed target is a real failure state")
    assert(game.unlocked_stage == 0, "Missing the target does not unlock the next stage")
    game._unhandled_input(accept)
    assert(game.mode == "race", "Failed stage can be retried")
    for stage_index in range(10):
        if game.mode == "stage_select":
            game._unhandled_input(accept)
        assert(game.mode == "race", "Stage %d launches" % (stage_index+1))
        var ticks := 0
        while not game.simulation.finished and ticks < 3000:
            var turn: float = game.simulation.tangent_at(game.simulation.distance).cross(game.simulation.tangent_at(game.simulation.distance + 90.0))
            controls.steer = signf(turn) * clampf(absf(turn) * game.simulation.speed * 0.30 / 82.0, 0.0, 1.0)
            game.simulation.step(controls,1.0/60.0)
            ticks += 1
        assert(game.simulation.finished, "Playable stage %d finishes" % (stage_index+1))
        game._process(1.0/60.0)
        assert(game.mode == "result" and game.qualified, "Stage %d passes the target and awards its unlock" % (stage_index+1))
        game._unhandled_input(accept)
        if stage_index < 9:
            assert(game.mode == "stage_select" and game.selected_stage == stage_index+1, "Next stage unlocks in sequence")
    assert(game.mode == "finish", "Tenth route reaches the finisher screen")
    var saved = JSON.parse_string(FileAccess.get_file_as_string("user://rally_stage_progress.json"))
    assert(saved is Dictionary and int(saved.get("unlocked_stage",-1)) == 9, "Local save records full progression")
    assert(saved.best_times.size() == 10, "Local save stores ten route records")
    game.free()
    await process_frame
    var resumed = packed_scene.instantiate()
    root.add_child(resumed)
    await process_frame
    assert(resumed.unlocked_stage == 9, "A new game session reloads the unlocked route")
    assert(resumed.best_times[9] > 0.0, "A new game session reloads the saved final-stage time")
    resumed.free()
    sim = null
    await process_frame
    print("PASS: 10 routes, authored pace notes, target times, stage unlocks, finisher, and persistent best times.")
    quit(0)


