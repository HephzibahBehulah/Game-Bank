extends SceneTree

func _initialize() -> void:
    call_deferred("_run_checks")

func _run_checks() -> void:
    var simulation_script = load("res://scripts/kart_simulation.gd")
    var cup_script = load("res://scripts/cup_state.gd")
    assert(simulation_script != null, "KartSimulation script loads")
    assert(cup_script != null, "CupState script loads")
    var sim = simulation_script.new()
    var throttle := {"steer":0.0,"throttle":1.0,"brake":0.0,"drift":false,"item":false}
    var completed_tracks: Array[int] = []
    for track_index in range(8):
        sim.reset(track_index, 1, 0, 1)
        assert(sim.racers.size() == 8, "Each race has two local players and six AI racers")
        assert(sim.track_length > 0.0, "Track has a measurable closed route")
        var ticks := 0
        while not sim.finished and ticks < 2400:
            sim.step(throttle, throttle, 1.0 / 60.0)
            ticks += 1
        assert(sim.finished, "Track %d reaches its finish condition" % track_index)
        var order: Array[Dictionary] = sim.standings()
        assert(order.size() == 8, "All racers appear in race results")
        var points: Array[int] = simulation_script.points_for_order(order)
        assert(points.size() == 8, "Race points are stored by racer id")
        var point_sum := 0
        for value in points:
            point_sum += value
        assert(point_sum == 58, "Race awards the complete 58-point scale")
        assert(points[int(order[0].id)] == 15, "Race winner receives 15 points by racer id")
        assert(points[int(order[7].id)] == 1, "Last-place racer receives 1 point by racer id")
        completed_tracks.append(track_index)
    var cup = cup_script.new()
    cup.start_cup(2, 1)
    var selected_tracks: Array[int] = []
    for race in range(4):
        var track: int = cup.track_for_race()
        selected_tracks.append(track)
        sim.reset(track, cup.difficulty, 0, 1)
        var ticks := 0
        while not sim.finished and ticks < 2400:
            sim.step(throttle, throttle, 1.0 / 60.0)
            ticks += 1
        assert(sim.finished, "Cup race %d finishes" % (race + 1))
        cup.record_race(simulation_script.points_for_order(sim.standings()))
    assert(cup.cup_race == 4, "Cup reaches its end after exactly four races")
    assert(cup.cup_standings().size() == 8, "Cup result ranks every racer")
    assert(cup.cup_winner() >= 0 and cup.cup_winner() < 8, "Cup winner is a valid racer")
    assert(selected_tracks.size() == 4 and selected_tracks[0] != selected_tracks[1] and selected_tracks[1] != selected_tracks[2] and selected_tracks[2] != selected_tracks[3], "Cup selects four distinct tracks")
    var game_scene = load("res://games/kart_grand_prix.tscn")
    assert(game_scene != null, "Playable game scene loads")
    var game = game_scene.instantiate()
    root.add_child(game)
    await process_frame
    var accept := InputEventAction.new()
    accept.action = "ui_accept"
    accept.pressed = true
    game._unhandled_input(accept)
    assert(game.mode == "race", "Start input launches the first race")
    for race in range(4):
        var game_sim = game.simulation
        var race_ticks := 0
        while not game_sim.finished and race_ticks < 2400:
            game_sim.step(throttle, throttle, 1.0 / 60.0)
            race_ticks += 1
        assert(game_sim.finished, "Playable scene race %d reaches the finish" % (race + 1))
        game._process(1.0 / 60.0)
        assert(game.mode == "race_result", "Race result screen follows each finish")
        game._unhandled_input(accept)
        if race < 3:
            assert(game.mode == "race", "Continue starts the next cup race")
    assert(game.mode == "cup_result", "Fourth race leads to the cup end screen")
    assert(root.get_node("CupState").cup_race == 4, "Playable scene awards all four cup races")
    var saved_progress = JSON.parse_string(FileAccess.get_file_as_string("user://kart_grand_prix_progress.json"))
    assert(saved_progress is Dictionary, "Completed cup writes a readable local career save")
    assert(int(saved_progress.get("cups_completed", 0)) >= 1, "Local career save records completed cups")
    game.free()
    sim = null
    cup.free()
    await process_frame
    print("PASS: all tracks, race points, scene start/result/continue, and four-race end state.")
    quit(0)
