extends Node2D

const SimScript = preload("res://scripts/soapbox_derby_simulation.gd")
const SAVE_PATH := "user://soapbox_derby_progress.json"
var sim
var mode := "briefing"
var selected_course := 0
var unlocked_courses := 1
var completed_runs := 0
var best_times: Array[float] = []
var frame_size := Vector2(1280, 800)

func _ready() -> void:
	_load_progress()
	sim = SimScript.new()
	sim.reset(selected_course)
	queue_redraw()

func _process(delta: float) -> void:
	if mode != "race":
		return
	sim.step(_controls(), delta)
	if sim.finished or sim.crashed:
		mode = "results"
		if sim.finished:
			_record_finish()
	queue_redraw()

func _controls() -> Dictionary:
	var steer := float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A))
	var brake := float(Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S))
	var pads := Input.get_connected_joypads()
	pads.sort()
	if not pads.is_empty():
		var pad: int = pads[0]
		var axis := Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
		if absf(axis) > 0.14:
			steer = signf(axis) * (absf(axis) - 0.14) / 0.86
		brake = maxf(brake, float(Input.is_joy_button_pressed(pad, JOY_BUTTON_B) or Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT) > 0.35))
	return {"steer": steer, "brake": brake}

func _confirm(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A)

func _unhandled_input(event: InputEvent) -> void:
	var left: bool = event.is_action_pressed("ui_left") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_LEFT)
	var right: bool = event.is_action_pressed("ui_right") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_RIGHT)
	var back: bool = event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
	var start: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
	if mode == "briefing":
		if left:
			selected_course = posmod(selected_course - 1, unlocked_courses)
		elif right:
			selected_course = posmod(selected_course + 1, unlocked_courses)
		elif _confirm(event):
			sim.reset(selected_course)
			mode = "race"
		elif back:
			get_tree().change_scene_to_file("res://scenes/hub.tscn")
	elif mode == "race" and (back or start):
		mode = "paused"
	elif mode == "paused":
		if _confirm(event) or start:
			mode = "race"
		elif back:
			mode = "briefing"
	elif mode == "results":
		if _confirm(event):
			if sim.finished:
				selected_course = mini(selected_course + 1, unlocked_courses - 1)
			mode = "briefing"
		elif back:
			mode = "briefing"
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, frame_size), Color("#10141d"))
	if mode == "briefing":
		_draw_briefing()
	elif mode == "race" or mode == "paused":
		_draw_race()
		if mode == "paused":
			draw_rect(Rect2(390, 320, 500, 160), Color("#07111fee"))
			draw_string(ThemeDB.fallback_font, Vector2(520, 382), "RACE PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("#67e8da"))
			draw_string(ThemeDB.fallback_font, Vector2(456, 430), "A / ENTER resume  ·  B / ESC course select", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	elif mode == "results":
		_draw_results()

func _draw_briefing() -> void:
	var course: Dictionary = SimScript.COURSES[selected_course]
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(72, 85), "SOAPBOX DERBY", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color("#ffcb73"))
	draw_string(font, Vector2(74, 124), "EIGHT GRAVITY-POWERED COURSES  ·  NO ENGINE  ·  PURE LINE CONTROL", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c7d4df"))
	draw_string(font, Vector2(74, 200), "COURSE %02d / 08  ·  UNLOCKED %02d" % [selected_course + 1, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#68e8d6"))
	draw_string(font, Vector2(74, 253), str(course.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
	draw_string(font, Vector2(74, 294), "%d m  ·  HILL GRADE %d%%  ·  GRIP %d%%" % [int(course.length), int(float(course.grade) * 100.0), int(float(course.grip) * 100.0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#bdd0db"))
	draw_string(font, Vector2(74, 365), "THREAD THE GATE MARKERS TO EARN LINE POINTS. A CLEAN LINE BEATS RAW SPEED.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffcb73"))
	draw_string(font, Vector2(74, 423), "STEER EARLY FOR EACH GATE. BRAKE BEFORE HAZARDS; EXCESS SPEED DESTROYS STABILITY.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_string(font, Vector2(74, 515), "KEYBOARD  A / ← steer left  ·  D / → steer right  ·  Space / ↓ brake", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#68e8d6"))
	draw_string(font, Vector2(74, 548), "GAMEPAD  left stick steer  ·  B / Circle or LT brake  ·  D-pad select  ·  A start", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c7d4df"))
	draw_string(font, Vector2(74, 616), "CAREER  %d finished runs  ·  best stage %02d" % [completed_runs, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9ab7c4"))
	draw_rect(Rect2(432, 668, 416, 66), Color("#875c34"), false, 3.0)
	draw_string(font, Vector2(500, 710), "START DERBY  ·  A / ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(font, Vector2(74, 762), "ESC / B returns to hub  ·  Complete a run to unlock the next course", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#849ba9"))

func _draw_race() -> void:
	var font := ThemeDB.fallback_font
	var course: Dictionary = SimScript.COURSES[sim.course_index]
	draw_rect(Rect2(0, 0, 1280, 510), Color("#283947"))
	draw_circle(Vector2(1060, 112), 44, Color("#ffd274"))
	draw_polygon(PackedVector2Array([Vector2(0, 360),Vector2(180, 170),Vector2(390, 380),Vector2(575, 140),Vector2(760, 365),Vector2(1010, 190),Vector2(1280, 350),Vector2(1280, 520),Vector2(0,520)]), PackedColorArray([Color("#42594f")]))
	var road := PackedVector2Array()
	for i in range(35):
		var world := clampf(sim.distance - 170.0 + float(i) * 42.0, 0.0, float(course.length))
		var sx: float = 470.0 + (world - sim.distance) * 1.18
		var bend := sin(world * 0.004 + float(sim.course_index)) * 65.0
		var sy := 430.0 + bend
		road.append(Vector2(sx, sy))
	if road.size() >= 2:
		draw_polyline(road, Color("#d8c49b"), 174.0, true)
		draw_polyline(road, Color("#544b42"), 162.0, true)
		draw_polyline(road, Color("#eee3c9"), 3.0, true)
	for gate_index in range(sim.gate_index, course.gates.size()):
		var gate: Dictionary = course.gates[gate_index]
		var gx: float = 470.0 + (float(gate.at) - sim.distance) * 1.18
		if gx > 390.0 and gx < 1260.0:
			var center_y := 430.0 + sin(float(gate.at) * 0.004 + float(sim.course_index)) * 65.0
			var lane_offset := float(gate.lane) * 48.0
			draw_line(Vector2(gx, center_y - 46.0), Vector2(gx, center_y + 46.0), Color("#6bf1d8"), 4.0)
			draw_circle(Vector2(gx, center_y + lane_offset), 8.0, Color("#ffd36e"))
	for hazard_index in range(sim.hazard_index, course.hazards.size()):
		var hazard: Dictionary = course.hazards[hazard_index]
		var hx: float = 470.0 + (float(hazard.at) - sim.distance) * 1.18
		if hx > 390.0 and hx < 1260.0:
			var hy := 430.0 + sin(float(hazard.at) * 0.004 + float(sim.course_index)) * 65.0
			draw_circle(Vector2(hx, hy), 21.0, Color("#ff7179"))
			draw_string(font, Vector2(hx - 65.0, hy - 28.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 130, 20, Color.WHITE)
	var cart_x := 472.0
	var cart_y: float = 430.0 + sin(sim.distance * 0.004 + float(sim.course_index)) * 65.0 + sim.lane * 48.0
	draw_rect(Rect2(cart_x - 25, cart_y - 13, 50, 24), Color("#ffc45f"))
	draw_circle(Vector2(cart_x - 16, cart_y + 13), 7.0, Color("#17202b"))
	draw_circle(Vector2(cart_x + 16, cart_y + 13), 7.0, Color("#17202b"))
	draw_rect(Rect2(34, 28, 1212, 94), Color("#07111ee8"))
	draw_string(font, Vector2(55, 59), str(course.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#68e8d6"))
	draw_string(font, Vector2(55, 94), "DISTANCE %d / %d m" % [int(sim.distance), int(course.length)], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	draw_string(font, Vector2(390, 94), "SPEED %02d km/h" % int(sim.speed * 3.6), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffcb73"))
	draw_string(font, Vector2(636, 94), "STABILITY %d%%" % int(sim.stability), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#68e8d6" if sim.stability > 40.0 else "#ff7179"))
	draw_string(font, Vector2(900, 94), "GATES %d/%d" % [sim.gates_hit, course.gates.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	var remain: float = float(course.length) - sim.distance
	var next_text: String = "FINISH LINE" if remain < 95.0 else "NEXT: " + str(course.hazards[sim.hazard_index].name) if sim.hazard_index < course.hazards.size() else "HOLD YOUR LINE"
	draw_string(font, Vector2(68, 568), next_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#ffcb73"))
	draw_string(font, Vector2(68, 606), "TIME %.1f s   ·   SCORE %d   ·   GATES MISSED %d" % [sim.elapsed, sim.score(), sim.gates_missed], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	if not sim.last_event.is_empty():
		draw_string(font, Vector2(68, 652), sim.last_event, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#68e8d6" if "CLEAN" in sim.last_event or "AVOIDED" in sim.last_event else "#ff7179"))
	draw_string(font, Vector2(68, 750), "A / ← left   D / → right   SPACE / ↓ brake   START / ESC pause", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#a8bac7"))

func _draw_results() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 1280, 800), Color("#10141d"))
	draw_string(font, Vector2(72, 94), "SOAPBOX DERBY · FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("#ffcb73"))
	draw_string(font, Vector2(72, 186), "COURSE %02d  ·  %s" % [sim.course_index + 1, str(SimScript.COURSES[sim.course_index].name).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
	draw_string(font, Vector2(72, 253), "RATING  " + sim.rating(), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#68e8d6" if sim.finished else "#ff7179"))
	draw_string(font, Vector2(72, 305), "TIME  %.2f s     SCORE  %d     GATES  %d / %d" % [sim.elapsed, sim.score(), sim.gates_hit, SimScript.COURSES[sim.course_index].gates.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
	draw_string(font, Vector2(72, 390), "EVENT  " + sim.last_event, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffcb73"))
	draw_string(font, Vector2(72, 484), "CAREER  %d finishes  ·  %d courses unlocked" % [completed_runs, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#9ab7c4"))
	draw_string(font, Vector2(72, 610), "A / ENTER  next unlocked course     B / ESC  course select", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#68e8d6"))

func _record_finish() -> void:
	completed_runs += 1
	if selected_course == unlocked_courses - 1 and unlocked_courses < SimScript.COURSES.size():
		unlocked_courses += 1
	while best_times.size() < SimScript.COURSES.size():
		best_times.append(0.0)
	var old: float = best_times[selected_course]
	if old == 0.0 or sim.elapsed < old:
		best_times[selected_course] = sim.elapsed
	_save_progress()

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		completed_runs = maxi(0, int(data.get("completed_runs", 0)))
		unlocked_courses = clampi(int(data.get("unlocked_courses", 1)), 1, SimScript.COURSES.size())
		best_times.assign(data.get("best_times", []))
		selected_course = clampi(int(data.get("selected_course", 0)), 0, unlocked_courses - 1)

func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"completed_runs": completed_runs, "unlocked_courses": unlocked_courses, "selected_course": selected_course, "best_times": best_times}))

