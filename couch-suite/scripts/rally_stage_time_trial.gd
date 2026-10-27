extends Node2D

const SAVE_PATH := "user://rally_stage_progress.json"
const GRASS := Color("#142a2b")
const ROAD_EDGE := Color("#d1c5a0")
const ROAD := Color("#464b4c")
const stages: Array[Dictionary] = RallyStageSimulation.STAGES

var simulation: RallyStageSimulation
var mode := "stage_select"
var selected_stage := 0
var unlocked_stage := 0
var best_times: Array[float] = []
var qualified := false
var personal_best := false
var stage_best := 0.0
var window_size := Vector2(1280, 800)

func _ready() -> void:
    best_times.resize(stages.size())
    best_times.fill(0.0)
    _load_progress()
    selected_stage = unlocked_stage
    simulation = RallyStageSimulation.new()
    simulation.reset(selected_stage)
    queue_redraw()

func _process(delta: float) -> void:
    if mode != "race":
        return
    simulation.step(_read_controls(), delta)
    if simulation.finished:
        _finish_stage()
    queue_redraw()

func _read_controls() -> Dictionary:
    var steer := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
    var throttle := 1.0 if Input.is_key_pressed(KEY_W) else 0.0
    var brake := 1.0 if Input.is_key_pressed(KEY_S) else 0.0
    var handbrake := Input.is_key_pressed(KEY_SPACE)
    var devices := Input.get_connected_joypads()
    devices.sort()
    if not devices.is_empty():
        var device := devices[0]
        steer = _deadzone(Input.get_joy_axis(device, JOY_AXIS_LEFT_X))
        throttle = maxf(throttle, clampf(Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT), 0.0, 1.0))
        brake = maxf(brake, clampf(Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT), 0.0, 1.0))
        handbrake = handbrake or Input.is_joy_button_pressed(device, JOY_BUTTON_B)
    return {"steer":steer,"throttle":throttle,"brake":brake,"handbrake":handbrake}

func _is_confirm(event: InputEvent) -> bool:
    return event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A)

func _deadzone(axis: float) -> float:
    var magnitude := absf(axis)
    if magnitude <= 0.14:
        return 0.0
    return signf(axis) * ((magnitude - 0.14) / 0.86)

func _finish_stage() -> void:
    var stage: Dictionary = stages[selected_stage]
    stage_best = best_times[selected_stage]
    personal_best = false
    qualified = simulation.elapsed <= float(stage.target)
    if qualified:
        if stage_best <= 0.0 or simulation.elapsed < stage_best:
            best_times[selected_stage] = simulation.elapsed
            stage_best = simulation.elapsed
        if selected_stage < stages.size() - 1:
            unlocked_stage = maxi(unlocked_stage, selected_stage + 1)
        _save_progress()
    mode = "result"

func _unhandled_input(event: InputEvent) -> void:
    if mode == "stage_select":
        if _is_confirm(event):
            simulation.reset(selected_stage)
            mode = "race"
        elif event.is_action_pressed("ui_left") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_LEFT):
            selected_stage = maxi(0, selected_stage - 1)
        elif event.is_action_pressed("ui_right") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_RIGHT):
            selected_stage = mini(unlocked_stage, selected_stage + 1)
        elif event.is_action_pressed("ui_cancel"):
            get_tree().change_scene_to_file("res://scenes/hub.tscn")
        queue_redraw()
    elif mode == "race" and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)):
        mode = "paused"
        queue_redraw()
    elif mode == "paused":
        if _is_confirm(event) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
            mode = "race"
        elif event.is_action_pressed("ui_cancel"):
            mode = "stage_select"
        queue_redraw()
    elif mode == "result" and _is_confirm(event):
        if qualified and selected_stage == stages.size() - 1:
            mode = "finish"
        elif qualified:
            selected_stage = mini(selected_stage + 1, unlocked_stage)
            mode = "stage_select"
        else:
            simulation.reset(selected_stage)
            mode = "race"
        queue_redraw()
    elif mode == "finish" and _is_confirm(event):
        get_tree().change_scene_to_file("res://scenes/hub.tscn")

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, window_size), GRASS)
    if mode == "stage_select":
        _draw_stage_select()
    elif mode == "race" or mode == "paused":
        _draw_stage()
        if mode == "paused":
            _draw_pause()
    elif mode == "result":
        _draw_stage()
        _draw_result()
    elif mode == "finish":
        _draw_finish()

func _draw_stage_select() -> void:
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(70,82), "RALLY STAGE TIME TRIAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("#f2d58a"))
    draw_string(font, Vector2(72,116), "10 POINT-TO-POINT STAGES  ·  BEAT THE TARGET TO OPEN THE NEXT ROUTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d4dfd3"))
    draw_string(font, Vector2(72,164), "CAREER RECORD  ·  %d / 10 STAGES UNLOCKED" % (unlocked_stage+1), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#83edcf"))
    for i in range(stages.size()):
        var column := i % 5
        var row := i / 5
        var box := Rect2(74 + column*228, 210 + row*104, 208, 82)
        var is_open := i <= unlocked_stage
        var is_selected := i == selected_stage
        draw_rect(box, Color("#1b3032") if is_open else Color("#121b20"))
        draw_rect(box, Color("#f2d58a") if is_selected else Color("#45605b"), false, 3.0 if is_selected else 1.0)
        var marker := "ROUTE %02d" % (i+1) if is_open else "LOCKED"
        draw_string(font, box.position+Vector2(12,25), marker, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f2d58a") if is_open else Color("#82908f"))
        draw_string(font, box.position+Vector2(12,49), str(stages[i].name), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ffffff") if is_open else Color("#82908f"))
        var best := best_times[i]
        draw_string(font, box.position+Vector2(12,69), "BEST  %s" % (_format_time(best) if best > 0.0 else "--:--.---"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#9fc5b4"))
    var current: Dictionary = stages[selected_stage]
    draw_string(font, Vector2(76,462), "SELECTED  %s  ·  TARGET %s" % [str(current.name).to_upper(),_format_time(float(current.target))], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#f2d58a"))
    draw_string(font, Vector2(76,510), "Pace notes: %s" % str(current.notes[0].text), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#d8e6e0"))
    draw_string(font, Vector2(76,575), "PAD  RT throttle  ·  LT brake  ·  left stick steer  ·  B handbrake  ·  A start", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#83edcf"))
    draw_string(font, Vector2(76,608), "KEYBOARD  W throttle  ·  S brake  ·  A/D steer  ·  SPACE handbrake  ·  ENTER start", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c2d1cc"))
    draw_string(font, Vector2(76,680), "← / → choose unlocked stage  ·  ESC return to the game hub", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9cafaa"))

func _draw_stage() -> void:
    var stage: Dictionary = stages[selected_stage]
    var width := float(stage.width)
    var route := PackedVector2Array()
    var points: Array = stage.points
    for point in points:
        route.append(point)
    draw_polyline(route, ROAD_EDGE, width+18.0, true)
    draw_polyline(route, ROAD, width, true)
    draw_polyline(route, Color("#c7b997"), 2.0, true)
    _draw_roadside_props()
    _draw_gates()
    var car_position := simulation.position_on_route(simulation.distance, simulation.lane)
    var direction := simulation.tangent_at(simulation.distance)
    var angle := direction.angle()
    var car_shape := PackedVector2Array([Vector2(20,0),Vector2(-12,-10),Vector2(-8,0),Vector2(-12,10)])
    var transformed := PackedVector2Array()
    for vertex in car_shape:
        transformed.append(car_position + vertex.rotated(angle))
    draw_colored_polygon(transformed, Color("#55ead0"))
    draw_polyline(PackedVector2Array([transformed[0],transformed[1],transformed[2],transformed[3],transformed[0]]), Color("#e7fff7"), 2.0)
    _draw_race_hud(stage)

func _draw_roadside_props() -> void:
    for i in range(2, 24):
        var distance := simulation.route_length * float(i) / 24.0
        var pos := simulation.position_on_route(distance)
        var normal := simulation.tangent_at(distance).orthogonal()
        for side in [-1.0, 1.0]:
            var tree: Vector2 = pos + normal * side * (float(stages[selected_stage].width) * 0.9 + 32.0 + float((i*19)%23))
            draw_circle(tree+Vector2(4,6),11,Color("#101d1c"))
            draw_circle(tree,9,Color("#2f5a3d"))
            draw_circle(tree+Vector2(-2,-3),4,Color("#4b7748"))

func _draw_gates() -> void:
    var points: Array = stages[selected_stage].points
    for i in range(1, points.size()-1):
        var marker_distance := _distance_to_point(i)
        var center: Vector2 = simulation.position_on_route(marker_distance)
        var normal := simulation.tangent_at(marker_distance).orthogonal()
        var half_width := float(stages[selected_stage].width)*0.45
        var color := Color("#f2d58a") if marker_distance >= simulation.distance else Color("#628174")
        draw_line(center-normal*half_width, center+normal*half_width, color, 3.0, true)

func _distance_to_point(point_index: int) -> float:
    var total := 0.0
    var points: Array = stages[selected_stage].points
    for i in range(point_index):
        total += (points[i] as Vector2).distance_to(points[i+1])
    return total

func _draw_race_hud(stage: Dictionary) -> void:
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(22,18,1236,112), Color("#091615e8"))
    draw_string(font, Vector2(42,48), "ROUTE %02d  ·  %s" % [selected_stage+1,str(stage.name).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f2d58a"))
    draw_string(font, Vector2(42,82), "TIME  %s   /   TARGET  %s" % [_format_time(simulation.elapsed),_format_time(float(stage.target))], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffffff"))
    draw_string(font, Vector2(42,110), "SPEED %03d   ·   ROAD %02d%%" % [int(round(simulation.speed)),int(round((0.5-absf(simulation.lane)/float(stage.width))*200.0))], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#83edcf"))
    var note_index := simulation.current_note_index()
    var note: Dictionary = stage.notes[note_index]
    draw_rect(Rect2(790,34,440,74), Color("#263322"))
    draw_string(font, Vector2(812,59), "CO-DRIVER  ·  NEXT NOTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#c3bf9e"))
    draw_string(font, Vector2(812,91), str(note.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffffff"))
    var progress := clampf(simulation.distance/maxf(simulation.route_length,0.001),0.0,1.0)
    draw_rect(Rect2(42,746,1190,14),Color("#293937"))
    draw_rect(Rect2(42,746,1190*progress,14),Color("#55ead0"))
    draw_string(font, Vector2(42,728), "START", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d9e7df"))
    draw_string(font, Vector2(1180,728), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d9e7df"))

func _draw_result() -> void:
    draw_rect(Rect2(310,245,660,305),Color("#0b1918eF"))
    var heading := "STAGE COMPLETE" if qualified else "TARGET MISSED"
    var tint := Color("#82f1d0") if qualified else Color("#ff987d")
    draw_string(ThemeDB.fallback_font,Vector2(375,305),heading,HORIZONTAL_ALIGNMENT_LEFT,-1,34,tint)
    draw_string(ThemeDB.fallback_font,Vector2(375,356),"%s  ·  TARGET %s" % [_format_time(simulation.elapsed),_format_time(float(stages[selected_stage].target))],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#ffffff"))
    draw_string(ThemeDB.fallback_font,Vector2(375,400),"%s" % str(stages[selected_stage].name),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#f2d58a"))
    if qualified:
        draw_string(ThemeDB.fallback_font,Vector2(375,446),("NEW PERSONAL BEST  " if personal_best else "PERSONAL BEST  ") + _format_time(best_times[selected_stage]),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#83edcf"))
        draw_string(ThemeDB.fallback_font,Vector2(375,497),"A / ENTER  ·  %s" % ("VIEW FINAL RESULTS" if selected_stage == stages.size()-1 else "OPEN NEXT STAGE"),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#f2d58a"))
    else:
        draw_string(ThemeDB.fallback_font,Vector2(375,455),"Need %s or faster to unlock the next route." % _format_time(float(stages[selected_stage].target)),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#ffc2b2"))
        draw_string(ThemeDB.fallback_font,Vector2(375,497),"A / ENTER  ·  RETRY STAGE",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#f2d58a"))

func _draw_finish() -> void:
    draw_rect(Rect2(230,210,820,360),Color("#0b1918eF"))
    draw_string(ThemeDB.fallback_font,Vector2(300,285),"SUMMIT RALLY  ·  FINISHER",HORIZONTAL_ALIGNMENT_LEFT,-1,36,Color("#f2d58a"))
    draw_string(ThemeDB.fallback_font,Vector2(300,342),"All 10 point-to-point stages are complete.",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("#ffffff"))
    draw_string(ThemeDB.fallback_font,Vector2(300,390),"Career record: %d routes unlocked" % (unlocked_stage+1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#83edcf"))
    draw_string(ThemeDB.fallback_font,Vector2(300,470),"A / ENTER  ·  RETURN TO HUB",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#f2d58a"))

func _draw_pause() -> void:
    draw_rect(Rect2(440,325,400,150),Color("#0b1918ee"))
    draw_string(ThemeDB.fallback_font,Vector2(510,390),"SERVICE PAUSE",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#f2d58a"))
    draw_string(ThemeDB.fallback_font,Vector2(475,430),"A / ENTER resume  ·  ESC stage select",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffffff"))

func _format_time(value: float) -> String:
    var total_millis := int(round(maxf(value,0.0)*1000.0))
    var minutes := total_millis / 60000
    var seconds := (total_millis / 1000) % 60
    var millis := total_millis % 1000
    return "%02d:%02d.%03d" % [minutes,seconds,millis]

func _save_progress() -> void:
    var file := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
    if file == null:
        push_warning("Could not save Rally career progress: %s" % error_string(FileAccess.get_open_error()))
        return
    file.store_string(JSON.stringify({"version":1,"unlocked_stage":unlocked_stage,"best_times":best_times},"\t"))

func _load_progress() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH,FileAccess.READ)
    if file == null:
        push_warning("Could not load Rally career progress: %s" % error_string(FileAccess.get_open_error()))
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary or int(parsed.get("version",0)) != 1:
        push_warning("Rally career save is invalid; starting from stage 1.")
        return
    unlocked_stage = clampi(int(parsed.get("unlocked_stage",0)),0,stages.size()-1)
    var saved_times: Array = parsed.get("best_times",[])
    for i in range(mini(saved_times.size(),best_times.size())):
        best_times[i] = maxf(0.0,float(saved_times[i]))
