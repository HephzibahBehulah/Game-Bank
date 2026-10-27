extends SceneTree

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://drone_racing_progress.json"))
	var script=load("res://scripts/drone_racing_simulation.gd")
	assert(script!=null and script.TRACKS.size()==5,"Five authored race circuits load")
	for track_index in range(script.TRACKS.size()):
		var sim=script.new()
		sim.reset(track_index)
		var gate_count=sim.TRACKS[track_index].gates.size()
		for i in range(script.LAPS*gate_count):
			var next=sim.drones[0].gate
			sim.drones[0].pos=Vector2(sim.TRACKS[track_index].gates[next])
			sim.step({"throttle":0.0},{"throttle":0.0},0.01)
		assert(sim.finished and sim.winner==0 and sim.drones[0].lap==script.LAPS,"%s finishes three laps by crossing ordered gates" % sim.TRACKS[track_index].name)
		assert(sim.drones[0].score==script.LAPS*gate_count*500,"Every ordered gate awards points")
		assert(sim.standings().size()==6,"Six pilot flight order remains available")

	var boost=script.new()
	boost.reset(0)
	boost.step({"throttle":1.0,"boost":true},{"throttle":0.0},0.05)
	assert(float(boost.drones[0].battery)<100.0 and Vector2(boost.drones[0].velocity).length()>0.0,"Throttle and boost consume battery while moving")
	var scene=load("res://games/drone_racing.tscn")
	assert(scene!=null,"Drone Racing scene resolves")
	var game:Node=scene.instantiate()
	root.add_child(game)
	await process_frame
	var accept:=InputEventJoypadButton.new()
	accept.button_index=JOY_BUTTON_A
	accept.pressed=true
	game._unhandled_input(accept)
	assert(game.mode=="race","Gamepad A launches flight")
	var start:=InputEventJoypadButton.new()
	start.button_index=JOY_BUTTON_START
	start.pressed=true
	game._unhandled_input(start)
	assert(game.mode=="paused","Start pauses flight")
	game._unhandled_input(start)
	assert(game.mode=="race","Start resumes flight")
	game.sim.finished=true
	game.sim.winner=0
	game._process(1.0/60.0)
	assert(game.mode=="results" and game.wins==1 and game.unlocked==2,"Winner screen unlocks the next course")
	var saved=JSON.parse_string(FileAccess.get_file_as_string("user://drone_racing_progress.json"))
	assert(saved is Dictionary and int(saved.get("wins",0))==1,"Drone career persists")
	game.free()
	await process_frame
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://games.json"))
	var found:=false
	for entry in catalog:
		if int(entry.id)==10:
			found=bool(entry.launchable) and entry.scene=="res://games/drone_racing.tscn"
	assert(found,"Drone Racing is available from the hub")
	print("PASS: five circuits, all ordered gates, 3-lap finish, battery boost, gamepad, career save and hub launch.")
	quit(0)

