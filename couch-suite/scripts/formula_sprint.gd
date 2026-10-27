extends Node2D

const SimulationScript = preload("res://scripts/formula_sprint_simulation.gd")
var simulation: FormulaSprintSimulation
var mode := "briefing"
var selected_circuit := 0
var frame_size := Vector2(1280,800)
var races_completed := 0
var podium_finishes := 0
var best_player_finish := 8
const SAVE_PATH := "user://formula_sprint_progress.json"

func _ready() -> void:
    _load_career()
    simulation=SimulationScript.new()
    simulation.reset(selected_circuit)
    queue_redraw()

func _process(delta: float) -> void:
    if mode!="race":
        return
    simulation.step(_player_controls(0),_player_controls(1),delta)
    if simulation.finished:
        mode="results"
        _record_result()
    queue_redraw()

func _player_controls(player: int) -> Dictionary:
    var keys: Array = [[KEY_A,KEY_D,KEY_W,KEY_S,KEY_F],[KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_PERIOD]][player]
    var steer := float(Input.is_key_pressed(keys[1]))-float(Input.is_key_pressed(keys[0]))
    var throttle := 1.0 if Input.is_key_pressed(keys[2]) else 0.0
    var brake := 1.0 if Input.is_key_pressed(keys[3]) else 0.0
    var pit := Input.is_key_pressed(keys[4])
    var devices := Input.get_connected_joypads()
    devices.sort()
    if player<devices.size():
        var device: int=devices[player]
        steer=_deadzone(Input.get_joy_axis(device,JOY_AXIS_LEFT_X))
        throttle=maxf(throttle,clampf(Input.get_joy_axis(device,JOY_AXIS_TRIGGER_RIGHT),0.0,1.0))
        brake=maxf(brake,clampf(Input.get_joy_axis(device,JOY_AXIS_TRIGGER_LEFT),0.0,1.0))
        pit=pit or Input.is_joy_button_pressed(device,JOY_BUTTON_X)
    return {"steer":steer,"throttle":throttle,"brake":brake,"pit":pit}

func _deadzone(value: float) -> float:
    var magnitude:=absf(value)
    if magnitude<=0.14:
        return 0.0
    return signf(value)*((magnitude-0.14)/0.86)

func _is_confirm(event: InputEvent) -> bool:
    return event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_A)

func _unhandled_input(event: InputEvent) -> void:
    if mode=="briefing":
        if _is_confirm(event):
            simulation.reset(selected_circuit)
            mode="race"
        elif event.is_action_pressed("ui_left") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_DPAD_LEFT):
            selected_circuit=posmod(selected_circuit-1,SimulationScript.TRACKS.size())
            simulation.reset(selected_circuit)
        elif event.is_action_pressed("ui_right") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_DPAD_RIGHT):
            selected_circuit=posmod(selected_circuit+1,SimulationScript.TRACKS.size())
            simulation.reset(selected_circuit)
        elif event.is_action_pressed("ui_cancel"):
            get_tree().change_scene_to_file("res://scenes/hub.tscn")
        queue_redraw()
    elif mode=="race" and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START)):
        mode="paused"
        queue_redraw()
    elif mode=="paused":
        if _is_confirm(event) or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START):
            mode="race"
        elif event.is_action_pressed("ui_cancel"):
            mode="briefing"
        queue_redraw()
    elif mode=="results" and _is_confirm(event):
        get_tree().change_scene_to_file("res://scenes/hub.tscn")

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,frame_size),Color("#08131b"))
    if mode=="briefing":
        _draw_briefing()
    elif mode=="race" or mode=="paused":
        _draw_race()
        if mode=="paused":
            _draw_pause()
    elif mode=="results":
        _draw_results()

func _draw_briefing() -> void:
    var font:=ThemeDB.fallback_font
    draw_string(font,Vector2(70,82),"FORMULA SPRINT",HORIZONTAL_ALIGNMENT_LEFT,-1,42,Color("#70f3da"))
    draw_string(font,Vector2(72,116),"FIVE CIRCUITS  ·  TEN LAPS  ·  TWO-PLAYER SPLIT SCREEN",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#cfdae4"))
    draw_string(font,Vector2(72,172),"SELECT CIRCUIT  %02d / 05" % (selected_circuit+1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ffd26d"))
    var card: Dictionary=SimulationScript.TRACKS[selected_circuit]
    draw_string(font,Vector2(72,222),str(card.name).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#ffffff"))
    draw_string(font,Vector2(72,257),"Race 10 laps. Tyres lose grip and fuel falls each lap. Watch both gauges.",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#a8c1d0"))
    draw_string(font,Vector2(72,309),"PIT STRATEGY",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ffd26d"))
    draw_string(font,Vector2(72,339),"Queue a stop with X / F. The pit lane is at the start line; the request carries to it.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#cfdae4"))
    draw_string(font,Vector2(72,369),"Stop the wheel-gun marker in four green windows. Each mistimed lug adds service time.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#cfdae4"))
    draw_string(font,Vector2(72,431),"P1  WASD steer / throttle / brake  ·  F pit",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#70f3da"))
    draw_string(font,Vector2(72,461),"P2  ARROWS steer / throttle / brake  ·  . pit",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffd26d"))
    draw_string(font,Vector2(72,513),"PAD  Left stick steer  ·  RT throttle  ·  LT brake  ·  X pit / wheel gun  ·  Start pause",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#a8c1d0"))
    draw_string(font,Vector2(72,546),"CAREER  %d races  ·  %d podiums  ·  best player finish %d" % [races_completed,podium_finishes,best_player_finish],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#92c4b8"))
    draw_rect(Rect2(440,590,400,70),Color("#26bba4"),false,3.0)
    draw_string(font,Vector2(493,634),"START RACE  ·  A / ENTER",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#ffffff"))
    draw_string(font,Vector2(72,704),"← / → select circuit  ·  ESC return to hub  ·  podium requires a player in the top three",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#8da7b7"))

func _draw_race() -> void:
    var half:=frame_size.x*0.5
    _draw_driver_view(Rect2(0,0,half,frame_size.y),0)
    _draw_driver_view(Rect2(half,0,half,frame_size.y),1)
    draw_rect(Rect2(half-2,0,4,frame_size.y),Color("#70f3da"))

func _draw_driver_view(rect: Rect2, player: int) -> void:
    draw_rect(rect,Color("#102027"))
    var points: Array=SimulationScript.TRACKS[simulation.circuit_index].points
    var scale_factor: float=minf((rect.size.x-34.0)/1000.0,(rect.size.y-160.0)/700.0)
    var map_size: Vector2=Vector2(1000,700)*scale_factor
    var offset: Vector2=rect.position+Vector2((rect.size.x-map_size.x)*0.5,140.0+(rect.size.y-150.0-map_size.y)*0.5)
    var route:=PackedVector2Array()
    for point in points:
        route.append(offset+point*scale_factor)
    route.append(route[0])
    var road_width:=float(SimulationScript.TRACKS[simulation.circuit_index].width)*2.0*scale_factor
    draw_polyline(route,Color("#c4b894"),road_width+16.0*scale_factor,true)
    draw_polyline(route,Color("#596066"),road_width,true)
    draw_polyline(route,Color("#343e44"),maxf(2.0,road_width-12.0*scale_factor),true)
    for i in range(points.size()):
        var pos: Vector2=offset+(points[i] as Vector2)*scale_factor
        draw_circle(pos,3.0,Color("#e8e0c6"))
    for car in simulation.racers:
        var world: Vector2=simulation.position_on_track(float(car.progress),float(car.lane))
        var tangent: Vector2=simulation.tangent_at(float(car.progress))
        var pos: Vector2=offset+world*scale_factor
        var shape:=PackedVector2Array([Vector2(13,0),Vector2(-8,-5),Vector2(-4,0),Vector2(-8,5)])
        var body:=PackedVector2Array()
        for vertex in shape:
            body.append(pos+vertex.rotated(tangent.angle()))
        draw_colored_polygon(body,car.color)
        if int(car.id)==player:
            draw_circle(pos,12.0,Color("#ffffff"),false,2.0)
    var car: Dictionary=simulation.racers[player]
    var lap:=clampi(int(maxf(0.0,float(car.progress))/simulation.track_length)+1,1,SimulationScript.RACE_LAPS)
    draw_rect(Rect2(rect.position.x+12,12,rect.size.x-24,116),Color("#071219eb"))
    draw_string(ThemeDB.fallback_font,rect.position+Vector2(25,40),"P%d  ·  %s" % [player+1,str(SimulationScript.TRACKS[simulation.circuit_index].name)],HORIZONTAL_ALIGNMENT_LEFT,-1,17,car.color)
    draw_string(ThemeDB.fallback_font,rect.position+Vector2(25,68),"LAP %02d / 10   ·   SPEED %03d" % [lap,int(round(float(car.speed)))],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#ffffff"))
    draw_string(ThemeDB.fallback_font,rect.position+Vector2(25,96),"TYRE %02d%%   FUEL %02d%%" % [int(round(100.0-float(car.wear))),int(round(float(car.fuel)))],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#70f3da"))
    draw_string(ThemeDB.fallback_font,rect.position+Vector2(25,119),"PIT QUEUED" if bool(car.pit_queue) else ("PIT SERVICE" if str(car.pit_state)!="track" else "PIT READY"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#ffd26d"))
    _draw_pit_status(rect,player,car)

func _draw_pit_status(rect: Rect2, player: int, car: Dictionary) -> void:
    if str(car.pit_state)=="track":
        return
    var box:=Rect2(rect.position+Vector2(30,rect.size.y-210),rect.size-Vector2(60,rect.size.y-210)-Vector2(0,20))
    draw_rect(box,Color("#071219ed"))
    if str(car.pit_state)=="lugs":
        var target:=SimulationScript.PIT_TARGETS[int(car.pit_step)]
        var gauge:=simulation.pit_gauge(car)
        draw_string(ThemeDB.fallback_font,box.position+Vector2(18,30),"PIT CREW  ·  WHEEL GUN %d / 4" % (int(car.pit_step)+1),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#ffd26d"))
        draw_rect(Rect2(box.position+Vector2(18,52),Vector2(box.size.x-36,22)),Color("#263638"))
        draw_rect(Rect2(box.position.x+18+(box.size.x-36)*target-8,box.position.y+49,16,28),Color("#55de9b"))
        draw_rect(Rect2(box.position.x+18+(box.size.x-36)*gauge-3,box.position.y+46,6,34),Color("#ffffff"))
        draw_string(ThemeDB.fallback_font,box.position+Vector2(18,101),"PRESS X / F WHEN THE WHITE MARKER HITS GREEN",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#ffffff"))
        draw_string(ThemeDB.fallback_font,box.position+Vector2(18,126),"CLEAN LUGS %d   ·   MISSED %d" % [int(car.pit_good),int(car.pit_missed)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#95bcb0"))
    else:
        draw_string(ThemeDB.fallback_font,box.position+Vector2(18,55),"CREW FITTING TYRES AND REFUELLING…",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#70f3da"))
        draw_string(ThemeDB.fallback_font,box.position+Vector2(18,88),"SERVICE %0.1f s" % float(car.service_left),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#ffffff"))

func _draw_pause() -> void:
    draw_rect(Rect2(425,330,430,145),Color("#071219ed"))
    draw_string(ThemeDB.fallback_font,Vector2(515,390),"RACE PAUSED",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#70f3da"))
    draw_string(ThemeDB.fallback_font,Vector2(465,430),"A / ENTER resume  ·  ESC circuit select",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#ffffff"))

func _player_best_place(order: Array[Dictionary]) -> int:
    var best := order.size()+1
    for place in range(order.size()):
        if int(order[place].id)<2:
            best=mini(best,place+1)
    return best

func _record_result() -> void:
    var best := _player_best_place(simulation.standings())
    races_completed+=1
    best_player_finish=mini(best_player_finish,best)
    if best<=3:
        podium_finishes+=1
    var file:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
    if file==null:
        push_warning("Could not save Formula Sprint career: %s" % error_string(FileAccess.get_open_error()))
        return
    file.store_string(JSON.stringify({"version":1,"races_completed":races_completed,"podium_finishes":podium_finishes,"best_player_finish":best_player_finish,"selected_circuit":selected_circuit},"\t"))

func _load_career() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file:=FileAccess.open(SAVE_PATH,FileAccess.READ)
    if file==null:
        push_warning("Could not load Formula Sprint career: %s" % error_string(FileAccess.get_open_error()))
        return
    var parsed=JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary or int(parsed.get("version",0))!=1:
        push_warning("Formula Sprint career save is invalid; starting a new record.")
        return
    races_completed=maxi(0,int(parsed.get("races_completed",0)))
    podium_finishes=maxi(0,int(parsed.get("podium_finishes",0)))
    best_player_finish=clampi(int(parsed.get("best_player_finish",8)),1,8)
    selected_circuit=posmod(int(parsed.get("selected_circuit",0)),SimulationScript.TRACKS.size())

func _draw_results() -> void:
    var order:=simulation.standings()
    var podium:=false
    for place in range(mini(3,order.size())):
        if int(order[place].id)<2:
            podium=true
    draw_rect(Rect2(70,48,1140,704),Color("#0a171eef"))
    draw_string(ThemeDB.fallback_font,Vector2(110,102),"PODIUM SECURED" if podium else "RACE COMPLETE  ·  OUTSIDE THE PODIUM",HORIZONTAL_ALIGNMENT_LEFT,-1,31,Color("#ffd26d") if podium else Color("#a9bdc8"))
    draw_string(ThemeDB.fallback_font,Vector2(112,138),"%s  ·  10 LAPS" % str(SimulationScript.TRACKS[simulation.circuit_index].name).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#70f3da"))
    for place in range(order.size()):
        var car: Dictionary=order[place]
        var extra: String="   ·   SERVICE %d   ·   TYRE %02d%%   FUEL %02d%%" % [int(car.pit_services),int(round(100.0-float(car.wear))),int(round(float(car.fuel)))]
        draw_string(ThemeDB.fallback_font,Vector2(125,194+place*48),"%d. %s%s%s" % [place+1,str(car.name),"  ·  PLAYER %d" % (int(car.id)+1) if int(car.id)<2 else "  ·  CPU",extra],HORIZONTAL_ALIGNMENT_LEFT,-1,16,car.color)
    draw_string(ThemeDB.fallback_font,Vector2(410,700),"A / ENTER  ·  RETURN TO GAME HUB",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ffffff"))


