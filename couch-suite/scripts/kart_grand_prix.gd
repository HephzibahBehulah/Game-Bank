extends Node2D

var simulation: KartSimulation
var active_player_karts: Array[int] = [0,1]
var view_size := Vector2(1280,800)
var mode := "briefing"
var selection := 0
var race_result: Array[Dictionary] = []
var last_finish_order: Array[Dictionary] = []

func _ready() -> void:
    CupState.start_cup(1, 0)
    simulation = KartSimulation.new()
    simulation.reset(CupState.track_for_race(), CupState.difficulty, active_player_karts[0], active_player_karts[1])
    set_process(true)
    queue_redraw()

func _process(dt: float) -> void:
    if mode == "race":
        simulation.step(_controls(0), _controls(1), dt)
        if simulation.finished:
            last_finish_order = simulation.standings()
            CupState.record_race(KartSimulation.points_for_order(last_finish_order))
            mode = "race_result"
        queue_redraw()

func _controls(player: int) -> Dictionary:
    var device := _device_for_player(player)
    var keys: Array = [ [KEY_A,KEY_D,KEY_W,KEY_S], [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN] ][player]
    var steer := float(Input.is_key_pressed(keys[1])) - float(Input.is_key_pressed(keys[0]))
    var throttle := 1.0 if Input.is_key_pressed(keys[2]) else 0.0
    var brake := 1.0 if Input.is_key_pressed(keys[3]) else 0.0
    if device >= 0:
        steer = _apply_steering_deadzone(Input.get_joy_axis(device, JOY_AXIS_LEFT_X))
        var trigger := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT)
        throttle = maxf(throttle, clampf(trigger,0.0,1.0))
        if Input.is_joy_button_pressed(device, JOY_BUTTON_A):
            throttle = 1.0
        var brake_trigger := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT)
        brake = maxf(brake, clampf(brake_trigger,0.0,1.0))
        if Input.is_joy_button_pressed(device, JOY_BUTTON_B):
            brake = 1.0
    var drift := Input.is_key_pressed(KEY_X) if player == 0 else Input.is_key_pressed(KEY_PERIOD)
    var item := Input.is_key_pressed(KEY_Q) if player == 0 else Input.is_key_pressed(KEY_SLASH)
    if device >= 0:
        drift = drift or Input.is_joy_button_pressed(device, JOY_BUTTON_X)
        item = item or Input.is_joy_button_pressed(device, JOY_BUTTON_LEFT_SHOULDER)
    return {"steer":steer,"throttle":throttle,"brake":brake,"drift":drift,"item":item}

func _device_for_player(player: int) -> int:
    var devices := Input.get_connected_joypads()
    devices.sort()
    return devices[player] if player < devices.size() else -1

func _apply_steering_deadzone(value: float) -> float:
    var magnitude := absf(value)
    if magnitude <= 0.14:
        return 0.0
    return signf(value) * ((magnitude - 0.14) / 0.86)

func _unhandled_input(event: InputEvent) -> void:
    if mode == "briefing":
        if event.is_action_pressed("ui_accept"):
            CupState.start_cup(CupState.difficulty, CupState.track_seed)
            mode = "race"
        elif event.is_action_pressed("ui_left"):
            active_player_karts[selection] = posmod(active_player_karts[selection]-1, KartSimulation.KARTS.size())
        elif event.is_action_pressed("ui_right"):
            active_player_karts[selection] = posmod(active_player_karts[selection]+1, KartSimulation.KARTS.size())
        elif event.is_action_pressed("ui_up"):
            CupState.difficulty = mini(2, CupState.difficulty+1)
        elif event.is_action_pressed("ui_down"):
            CupState.difficulty = maxi(0, CupState.difficulty-1)
        elif event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
            selection = 1-selection
        elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_BACK:
            selection = 1-selection
        elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_LEFT:
            active_player_karts[selection] = posmod(active_player_karts[selection]-1, KartSimulation.KARTS.size())
        elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_RIGHT:
            active_player_karts[selection] = posmod(active_player_karts[selection]+1, KartSimulation.KARTS.size())
        elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            if Rect2(470,430,340,70).has_point(event.position):
                mode = "race"
        queue_redraw()
    elif mode == "race_result" and event.is_action_pressed("ui_accept"):
        if CupState.cup_race >= 4:
            CupState.complete_cup()
            mode = "cup_result"
        else:
            simulation.reset(CupState.track_for_race(), CupState.difficulty, active_player_karts[0], active_player_karts[1])
            mode = "race"
        queue_redraw()
    elif mode == "cup_result" and event.is_action_pressed("ui_accept"):
        get_tree().change_scene_to_file("res://scenes/hub.tscn")
    elif mode == "race" and event.is_action_pressed("ui_cancel"):
        mode = "paused"
        queue_redraw()
    elif mode == "race" and event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
        mode = "paused"
        queue_redraw()
    elif mode == "paused" and event.is_action_pressed("ui_accept"):
        mode = "race"
        queue_redraw()
    elif mode == "paused" and event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
        mode = "race"
        queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, view_size), Color("#07111f"))
    if mode == "briefing":
        _draw_briefing()
    elif mode == "race" or mode == "paused":
        _draw_race()
        if mode == "paused":
            _draw_message("PAUSED  ·  PRESS A / ENTER")
    elif mode == "race_result":
        _draw_race()
        _draw_result(false)
    elif mode == "cup_result":
        _draw_result(true)

func _draw_briefing() -> void:
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(78,105), "KART GRAND PRIX", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color("#70f5df"))
    draw_string(font, Vector2(80,145), "8 circuits  ·  8 tuned karts  ·  4 race cup  ·  2-player split view", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#c4d5e1"))
    draw_string(font, Vector2(80,205), "CUP TRACKS: " + _cup_track_names(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f0c969"))
    draw_string(font, Vector2(80,238), "CAREER  %d CUPS  ·  %d PLAYER WINS  ·  PERSONAL BEST %d PTS" % [CupState.cups_completed,CupState.player_cup_wins,CupState.best_cup_points], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#8deedc"))
    for p in range(2):
        var kart: Dictionary = KartSimulation.KARTS[active_player_karts[p]]
        var row_y := 280.0 + p*72
        draw_string(font, Vector2(100,row_y), "P%d  %s     TOP SPEED %.0f     GRIP %.2f" % [p+1,kart.name,kart.max,kart.grip], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, kart.color)
        draw_string(font, Vector2(650,row_y), "LEFT / RIGHT chooses kart   ·   TAB selects player", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9eb3c6"))
    draw_string(font, Vector2(100,430), "DIFFICULTY: " + ["ROOKIE","PRO","ELITE"][CupState.difficulty] + "     ·     UP / DOWN changes", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#f0c969"))
    draw_rect(Rect2(470,430,340,70), Color("#37d9bd"), false, 3)
    draw_string(font, Vector2(510,475), "START CUP  ·  A / ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#ffffff"))
    draw_string(font, Vector2(90,570), "P1 WASD + X drift + Q item     ·     P2 ARROWS + . drift + / item", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#9eb3c6"))
    draw_string(font, Vector2(90,610), "Gamepad: left stick steer · RT/A accelerate · LT/B brake · X drift · LB item · Start pause", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#9eb3c6"))

func _cup_track_names() -> String:
    var out := PackedStringArray()
    for i in range(4):
        out.append(KartSimulation.TRACKS[(CupState.track_seed+i*2)%8].name)
    return "  →  ".join(out)

func _draw_race() -> void:
    var w := view_size.x/2.0
    _draw_view(Rect2(0,0,w,view_size.y-74),0)
    _draw_view(Rect2(w,0,w,view_size.y-74),1)
    draw_rect(Rect2(w-2,0,4,view_size.y-74),Color("#65f0df"))
    var lap := clampi(int(float(simulation.racers[0].progress) / simulation.track_length) + 1, 1, 3)
    draw_string(ThemeDB.fallback_font,Vector2(25,view_size.y-24),"RACE %d / 4  ·  LAP %d / 3  ·  %s" % [CupState.cup_race+1,lap,KartSimulation.TRACKS[simulation.track_index].name],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#e9f5ff"))

func _draw_view(rect: Rect2, human_id: int) -> void:
    draw_rect(rect,Color("#0a1d24"))
    var pts: Array = KartSimulation.TRACKS[simulation.track_index].points
    var scale_factor := minf((rect.size.x-38)/1000.0,(rect.size.y-38)/700.0)
    var offset := rect.position + (rect.size-Vector2(1000,700)*scale_factor)*.5
    var line := PackedVector2Array()
    for p in pts:
        line.append(offset+p*scale_factor)
    line.append(line[0])
    draw_polyline(line,Color("#243746"),(float(KartSimulation.TRACKS[simulation.track_index].width)*2+22)*scale_factor,true)
    draw_polyline(line,Color("#728493"),float(KartSimulation.TRACKS[simulation.track_index].width)*2*scale_factor,true)
    draw_polyline(line,Color("#314656"),float(KartSimulation.TRACKS[simulation.track_index].width)*2*scale_factor-8,true)
    for r in simulation.racers:
        var world: Vector2=simulation.place_on_track(float(r.progress),float(r.lane))
        var pos:=offset+world*scale_factor
        draw_circle(pos,9.0 if r.id<2 else 7.0,r.color)
        if r.id==human_id:
            draw_circle(pos,13.0,Color("#ffffff"),false,2.0)
    draw_string(ThemeDB.fallback_font,rect.position+Vector2(18,26),"PLAYER %d VIEW" % (human_id+1),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#eaf7ff"))
    var player_car: Dictionary = simulation.racers[human_id]
    var player_place := 1
    for racer in simulation.racers:
        if float(racer.progress) > float(player_car.progress):
            player_place += 1
    draw_string(ThemeDB.fallback_font,rect.position+Vector2(18,48),"SPEED %03d   POSITION %d / 8   BOOST %d" % [int(round(float(player_car.speed))),player_place,int(player_car.items)],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#70f5df"))

func _draw_result(cup: bool) -> void:
    draw_rect(Rect2(70,65,view_size.x-140,view_size.y-130),Color("#0c1c2d"))
    var standings: Array[int] = CupState.cup_standings() if cup else _race_standings_ids()
    var title: String = "CUP CHAMPION: " + KartSimulation.KARTS[CupState.cup_winner()].name if cup else "RACE %d RESULTS" % CupState.cup_race
    draw_string(ThemeDB.fallback_font,Vector2(110,130),title,HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("#70f5df"))
    for place in range(standings.size()):
        var racer_id := standings[place]
        var racer: Dictionary = simulation.racers[racer_id]
        var points := int(CupState.cup_points[racer_id]) if cup else int(KartSimulation.points_for_order(last_finish_order)[racer_id])
        draw_string(ThemeDB.fallback_font,Vector2(130,190+place*42),"%d. %s  ·  %d POINTS" % [place+1,str(racer.name),points],HORIZONTAL_ALIGNMENT_LEFT,-1,20,racer.color)
    var message := "A / ENTER  ·  RETURN TO HUB" if cup else "A / ENTER  ·  NEXT RACE"
    draw_string(ThemeDB.fallback_font,Vector2(410,view_size.y-100),message,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#f0c969"))

func _race_standings_ids() -> Array[int]:
    var ids: Array[int] = []
    for racer in last_finish_order:
        ids.append(int(racer.get("id", -1)))
    return ids

func _draw_message(text: String) -> void:
    draw_rect(Rect2(390,350,500,100),Color("#07111fee"))
    draw_string(ThemeDB.fallback_font,Vector2(425,410),text,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("#ffffff"))
