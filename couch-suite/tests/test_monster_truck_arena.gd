extends SceneTree

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://monster_truck_arena_progress.json"))
	var script=load("res://scripts/monster_truck_arena_simulation.gd")
	assert(script!=null and script.ARENAS.size()==5,"Five authored derby stadiums load")
	for arena_index in range(script.ARENAS.size()):
		var sim=script.new()
		sim.reset(arena_index)
		assert(sim.objects.size()==6 and sim.trucks.size()==6,"Six targets and six trucks are authored")
		var truck=sim.trucks[0]
		var target=sim.objects[0]
		truck.pos=Vector2(target.pos)+Vector2(float(target.radius)+10.0,0)
		truck.velocity=Vector2(-82.0,0)
		for strike in range(120):
			if not target.active:break
			truck.pos=Vector2(target.pos)+Vector2(float(target.radius)+10.0,0)
			truck.velocity=Vector2(-82.0,0)
			sim._collide_objects(truck,0.05)
		assert(not target.active and sim.hits==1 and int(truck.score)>0,"%s allows target destruction and awards points" % script.ARENAS[arena_index].name)
		var ramp=sim.objects[3]
		truck.pos=Vector2(ramp.pos)+Vector2(float(ramp.radius)+10.0,0)
		truck.velocity=Vector2(-70.0,0)
		sim._collide_objects(truck,0.05)
		assert(not ramp.active and float(truck.air_time)>0.0,"A fast ramp hit scores airtime")
		assert(sim.standings().size()==6,"Derby returns complete six-truck leaderboard")

	var full_round=script.new()
	full_round.reset(0)
	full_round.elapsed=script.ROUND_SECONDS-0.05
	full_round.step({"throttle":0.9},{"throttle":0.75},0.05)
	assert(full_round.finished and full_round.winner>=0,"Round timer ends the match and selects a valid winner")

	var scene=load("res://games/monster_truck_arena.tscn")
	assert(scene!=null,"Arena scene resolves")
	var game: Node=scene.instantiate()
	root.add_child(game)
	await process_frame
	var accept:=InputEventJoypadButton.new()
	accept.button_index=JOY_BUTTON_A
	accept.pressed=true
	game._unhandled_input(accept)
	assert(game.mode=="arena","Gamepad A starts the derby")
	var start:=InputEventJoypadButton.new()
	start.button_index=JOY_BUTTON_START
	start.pressed=true
	game._unhandled_input(start)
	assert(game.mode=="paused","Start pauses the arena")
	game._unhandled_input(start)
	assert(game.mode=="arena","Start resumes the arena")
	game.sim.finished=true
	game.sim.winner=0
	game._process(1.0/60.0)
	assert(game.mode=="results" and game.wins==1 and game.unlocked==2,"Win records results and unlocks the next stadium")
	var saved=JSON.parse_string(FileAccess.get_file_as_string("user://monster_truck_arena_progress.json"))
	assert(saved is Dictionary and int(saved.get("wins",0))==1,"Arena career persists")
	game.free()
	await process_frame
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://games.json"))
	var found:=false
	for entry in catalog:
		if int(entry.id)==9:
			found=bool(entry.launchable) and entry.scene=="res://games/monster_truck_arena.tscn"
	assert(found,"Monster Truck Arena is hub-launchable")
	print("PASS: five arenas, breakable target scoring, ramp airtime, AI field, controller flow, saved career, and hub launch.")
	quit(0)

