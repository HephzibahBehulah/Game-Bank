extends SceneTree

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://stock_car_oval_progress.json"))
	var script=load("res://scripts/stock_car_oval_simulation.gd")
	assert(script!=null and script.TRACKS.size()==5,"Five authored ovals load")
	for track_index in range(script.TRACKS.size()):
		var sim=script.new()
		sim.reset(track_index)
		var ticks:=0
		while not sim.finished and ticks<40000:
			sim.step({"throttle":1.0,"steer":0.0},{"throttle":0.0,"steer":0.0},0.05)
			ticks+=1
		assert(sim.finished and sim.winner==0 and ticks<40000,"%s reaches a genuine six-lap finish" % script.TRACKS[track_index].name)
		assert(sim.completed_laps(0)==script.LAPS,"Player crosses all lap markers")
		assert(sim.standings().size()==script.CAR_COUNT,"Six-car field returns complete standings")
		assert(float(sim.cars[0].best_lap)>0.0,"Lap timing records a best lap")
		assert(float(sim.cars[0].temp)>=55.0,"Tire temperature remains bounded")

	var scene=load("res://games/stock_car_oval.tscn")
	assert(scene!=null,"Oval scene resolves")
	var game: Node=scene.instantiate()
	root.add_child(game)
	await process_frame
	var accept:=InputEventJoypadButton.new()
	accept.button_index=JOY_BUTTON_A
	accept.pressed=true
	game._unhandled_input(accept)
	assert(game.mode=="race","Gamepad A starts the race")
	var start:=InputEventJoypadButton.new()
	start.button_index=JOY_BUTTON_START
	start.pressed=true
	game._unhandled_input(start)
	assert(game.mode=="paused","Start pauses")
	game._unhandled_input(start)
	assert(game.mode=="race","Start resumes")
	game.sim.finished=true
	game.sim.winner=0
	game._process(1.0/60.0)
	assert(game.mode=="results" and game.wins==1 and game.unlocked==2,"Win shows results and unlocks the next circuit")
	var saved=JSON.parse_string(FileAccess.get_file_as_string("user://stock_car_oval_progress.json"))
	assert(saved is Dictionary and int(saved.get("wins",0))==1,"Career persists after finish")
	game.free()
	await process_frame
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://games.json"))
	var registered:=false
	for entry in catalog:
		if int(entry.id)==8:
			registered=bool(entry.launchable) and entry.scene=="res://games/stock_car_oval.tscn"
	assert(registered,"Completed oval appears as a launchable hub game")
	print("PASS: five six-lap stock-car races, AI field, lap timing, gamepad, pause, career save and hub launch.")
	quit(0)

