extends SceneTree

func _initialize() -> void:
    call_deferred("_run_checks")

func _clean_line(sim, controls: Dictionary, max_ticks: int = 30000) -> int:
    var ticks := 0
    while not sim.finished and ticks < max_ticks:
        var turn: float = sim.tangent_at(float(sim.racers[0].progress)).cross(sim.tangent_at(float(sim.racers[0].progress)+85.0))
        var turn_two: float = sim.tangent_at(float(sim.racers[1].progress)).cross(sim.tangent_at(float(sim.racers[1].progress)+85.0))
        var first := controls.duplicate()
        var second := controls.duplicate()
        first.steer=signf(turn)*clampf(absf(turn)*float(sim.racers[0].speed)*0.28/92.0,0.0,1.0)
        second.steer=signf(turn_two)*clampf(absf(turn_two)*float(sim.racers[1].speed)*0.28/92.0,0.0,1.0)
        sim.step(first,second,1.0/60.0)
        ticks+=1
    return ticks

func _run_checks() -> void:
    var simulation_script=load("res://scripts/formula_sprint_simulation.gd")
    assert(simulation_script!=null,"Formula race engine loads")
    assert(simulation_script.TRACKS.size()==5,"Five authored circuits exist")
    var sim=simulation_script.new()
    var controls={"steer":0.0,"throttle":1.0,"brake":0.0,"pit":false}
    for circuit in range(5):
        sim.reset(circuit)
        assert(sim.racers.size()==8,"Race fields have two local players and six rivals")
        assert(sim.track_length>1000.0,"Each circuit has a complete closed route")
        var ticks:=_clean_line(sim,controls)
        assert(sim.finished and ticks<30000,"Circuit %d completes 10 laps" % (circuit+1))
        assert(sim.standings().size()==8,"Circuit %d produces eight race results" % (circuit+1))
        assert(float(sim.racers[0].wear)>0.0 and float(sim.racers[0].fuel)<100.0,"Tire wear and fuel usage affect each race")
    sim.reset(0)
    sim.racers[0].fuel=37.0
    sim.racers[0].wear=62.0
    sim.step({"steer":0.0,"throttle":0.0,"brake":0.0,"pit":true},controls,1.0/60.0)
    assert(str(sim.racers[0].pit_state)=="lugs","Pit request enters the wheel-gun stop at pit lane")
    var clean_controls={"steer":0.0,"throttle":0.0,"brake":0.0,"pit":false}
    for lug in range(simulation_script.PIT_TARGETS.size()):
        var target: float=simulation_script.PIT_TARGETS[lug]
        var found:=false
        for tick in range(80):
            sim.step(clean_controls,controls,0.05)
            var gauge: float=sim.pit_gauge(sim.racers[0])
            var difference:=minf(absf(gauge-target),1.0-absf(gauge-target))
            if difference<=0.025:
                sim.step({"steer":0.0,"throttle":0.0,"brake":0.0,"pit":true},controls,0.01)
                sim.step(clean_controls,controls,0.01)
                found=true
                break
        assert(found,"Wheel-gun lug %d has an attainable timing window" % (lug+1))
    assert(int(sim.racers[0].pit_good)==4 and int(sim.racers[0].pit_missed)==0,"Four precise wheel-gun hits are scored")
    assert(str(sim.racers[0].pit_state)=="service","Four lug events begin a service stop")
    for tick in range(40):
        sim.step(clean_controls,controls,0.05)
    assert(str(sim.racers[0].pit_state)=="track" and int(sim.racers[0].pit_services)==1,"Pit service returns the car to the race")
    assert(float(sim.racers[0].fuel)==100.0 and float(sim.racers[0].wear)==0.0,"Pit service refuels and restores tyres")
    sim.reset(0)
    sim.step({"steer":0.0,"throttle":0.0,"brake":0.0,"pit":true},controls,1.0/60.0)
    sim.step(clean_controls,controls,0.05)
    sim.step({"steer":0.0,"throttle":0.0,"brake":0.0,"pit":true},controls,0.01)
    assert(int(sim.racers[0].pit_missed)==1,"A mistimed wheel-gun press records a miss")
    var scene=load("res://games/formula_sprint.tscn")
    var game=scene.instantiate()
    root.add_child(game)
    await process_frame
    var right:=InputEventJoypadButton.new()
    right.button_index=JOY_BUTTON_DPAD_RIGHT
    right.pressed=true
    game._unhandled_input(right)
    assert(game.selected_circuit==1,"Gamepad D-pad selects a circuit")
    var accept:=InputEventJoypadButton.new()
    accept.button_index=JOY_BUTTON_A
    accept.pressed=true
    game._unhandled_input(accept)
    assert(game.mode=="race","Gamepad A starts the race")
    var start:=InputEventJoypadButton.new()
    start.button_index=JOY_BUTTON_START
    start.pressed=true
    game._unhandled_input(start)
    assert(game.mode=="paused","Gamepad Start pauses the race")
    game._unhandled_input(start)
    assert(game.mode=="race","Gamepad Start resumes the race")
    game.simulation.finished=true
    game._process(1.0/60.0)
    assert(game.mode=="results","Finished race opens the result and podium screen")
    var saved=JSON.parse_string(FileAccess.get_file_as_string("user://formula_sprint_progress.json"))
    assert(saved is Dictionary and int(saved.get("races_completed",0))==1,"Career result is persisted locally")
    game.free()
    await process_frame
    var resumed=scene.instantiate()
    root.add_child(resumed)
    await process_frame
    assert(resumed.races_completed==1 and resumed.best_player_finish==int(saved.get("best_player_finish",8)),"New session reloads the Formula Sprint career record")
    resumed.free()
    sim=null
    await process_frame
    print("PASS: five 10-lap circuits, two-player/eight-car fields, resource wear, wheel-gun pit service, gamepad menu/pause, results, and career save.")
    quit(0)
