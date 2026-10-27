extends Node2D

const SimScript = preload("res://scripts/hovercraft_simulation.gd")
const SAVE_PATH := "user://hovercraft_time_attack_progress.json"
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
	if sim.finished or sim.wrecked:
		mode = "results"
		if sim.finished:
			_record_finish()
	queue_redraw()

func _controls() -> Dictionary:
	var steer := float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A))
	var throttle := float(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W))
	var brake := float(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_SPACE))
	var boost := Input.is_key_pressed(KEY_SHIFT)
	var pads := Input.get_connected_joypads()
	pads.sort()
	if not pads.is_empty():
		var pad: int = pads[0]
		var axis := Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
		if absf(axis) > 0.14:
			steer = signf(axis) * (absf(axis) - 0.14) / 0.86
		throttle = maxf(throttle, clampf(Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT), 0.0, 1.0))
		brake = maxf(brake, clampf(Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT), 0.0, 1.0))
		boost = boost or Input.is_joy_button_pressed(pad, JOY_BUTTON_RIGHT_SHOULDER)
	return {"steer": steer, "throttle": throttle, "brake": brake, "boost": boost}

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
	draw_rect(Rect2(Vector2.ZERO, frame_size), Color("#071b27"))
	if mode == "briefing":
		_draw_briefing()
	elif mode == "race" or mode == "paused":
		_draw_race()
		if mode == "paused":
			draw_rect(Rect2(390, 320, 500, 160), Color("#06131bee"))
			draw_string(ThemeDB.fallback_font, Vector2(520, 382), "RACE PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("#70f0e5"))
			draw_string(ThemeDB.fallback_font, Vector2(456, 430), "A / ENTER resume  ·  B / ESC course select", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	elif mode == "results":
		_draw_results()

func _draw_briefing() -> void:
	var course: Dictionary = SimScript.COURSES[selected_course]
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(74, 88), "HOVERCRAFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 43, Color("#70f0e5"))
	draw_string(font, Vector2(76, 128), "TIME ATTACK  ·  EIGHT WATER COURSES  ·  MOMENTUM + TWIN-FAN THRUST", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b9d5dd"))
	draw_string(font, Vector2(76, 203), "COURSE %02d / 08  ·  UNLOCKED %02d" % [selected_course + 1, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#a4ffd4"))
	draw_string(font, Vector2(76, 256), str(course.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
	draw_string(font, Vector2(76, 298), "%d m  ·  THRUST %.1f  ·  WAVE CHOP %d%%  ·  CROSSWIND %d%%" % [int(course.length), course.thrust, int(float(course.chop) * 100.0), int(float(course.wind) * 100.0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#b9d5dd"))
	draw_string(font, Vector2(76, 369), "PASS THE GATES ON THEIR AMBER LINE. THREAD AROUND THE RED BUOYS.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffd36e"))
	draw_string(font, Vector2(76, 416), "STEERING HAS MOMENTUM: LEAD YOUR TURN, THEN COUNTER-STEER TO SETTLE.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_string(font, Vector2(76, 516), "KEYBOARD  W / ↑ throttle  ·  A/D or ←/→ steer  ·  S / ↓ brake  ·  SHIFT boost", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#70f0e5"))
	draw_string(font, Vector2(76, 550), "GAMEPAD  RT throttle  ·  left stick steer  ·  LT brake  ·  RB boost  ·  A start", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b9d5dd"))
	draw_string(font, Vector2(76, 616), "CAREER  %d finishes  ·  best course %02d" % [completed_runs, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9ab7c4"))
	draw_rect(Rect2(430, 668, 420, 66), Color("#315f68"), false, 3.0)
	draw_string(font, Vector2(495, 710), "START TIME ATTACK  ·  A / ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	draw_string(font, Vector2(76, 762), "ESC / B returns to hub  ·  Finish a course to unlock the next", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#849ba9"))

func _draw_race() -> void:
	var font := ThemeDB.fallback_font
	var course: Dictionary = SimScript.COURSES[sim.course_index]
	draw_rect(Rect2(0, 0, 1280, 800), Color("#082c3a"))
	for band in range(12):
		var y := float(band) * 70.0 + fposmod(sim.distance * 1.4, 70.0)
		draw_line(Vector2(0, y), Vector2(1280, y + sin(y * 0.025) * 16.0), Color("#a0f6e015"), 2.0)
	draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(280,0),Vector2(500,800),Vector2(0,800)]),PackedColorArray([Color("#173f3b")]))
	draw_polygon(PackedVector2Array([Vector2(1000,0),Vector2(1280,0),Vector2(1280,800),Vector2(780,800)]),PackedColorArray([Color("#173f3b")]))
	var center_x := 640.0 + sin(sim.distance * 0.0022 + float(sim.course_index)) * 54.0
	draw_line(Vector2(center_x - 250.0, 132.0), Vector2(center_x - 116.0, 800.0), Color("#c9faf044"), 4.0)
	draw_line(Vector2(center_x + 250.0, 132.0), Vector2(center_x + 116.0, 800.0), Color("#c9faf044"), 4.0)
	for gate_index in range(sim.gate_index, course.gates.size()):
		var gate: Dictionary = course.gates[gate_index]
		var gy: float = 300.0 + (float(gate.at) - sim.distance) * 0.72
		if gy > 135.0 and gy < 760.0:
			draw_line(Vector2(center_x - 140.0, gy), Vector2(center_x + 140.0, gy), Color("#70f0e5"), 4.0)
			draw_circle(Vector2(center_x + float(gate.lane) * 100.0, gy), 10.0, Color("#ffd36e"))
	for buoy_index in range(sim.buoy_index, course.buoys.size()):
		var buoy: Dictionary = course.buoys[buoy_index]
		var by: float = 300.0 + (float(buoy.at) - sim.distance) * 0.72
		if by > 135.0 and by < 760.0:
			draw_circle(Vector2(center_x + float(buoy.lane) * 100.0, by), 20.0, Color("#ff6878"))
	var craft_x: float = center_x + sim.lane * 100.0
	draw_polygon(PackedVector2Array([Vector2(craft_x,620),Vector2(craft_x-27,681),Vector2(craft_x-12,700),Vector2(craft_x+12,700),Vector2(craft_x+27,681)]),PackedColorArray([Color("#ffcf68")]))
	draw_circle(Vector2(craft_x - 31.0, 676.0), 10.0, Color("#70f0e5"))
	draw_circle(Vector2(craft_x + 31.0, 676.0), 10.0, Color("#70f0e5"))
	draw_rect(Rect2(32, 25, 1216, 105), Color("#051521e8"))
	draw_string(font, Vector2(55, 57), str(course.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#70f0e5"))
	draw_string(font, Vector2(55, 96), "DISTANCE %d / %d m" % [int(sim.distance), int(course.length)], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(font, Vector2(400, 96), "SPEED %02d km/h" % int(sim.speed * 3.6), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffd36e"))
	draw_string(font, Vector2(625, 96), "HULL %d%%" % int(sim.integrity), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#a4ffd4" if sim.integrity > 40.0 else "#ff6878"))
	draw_string(font, Vector2(825, 96), "BOOST %d%%" % int(sim.boost_energy), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#70f0e5"))
	draw_string(font, Vector2(1030, 96), "GATES %d/%d" % [sim.gates_clean, course.gates.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	var remain: float = float(course.length) - sim.distance
	var next_text: String = "FINISH LINE" if remain < 100.0 else "NEXT BUOY · " + str(course.buoys[sim.buoy_index].name) if sim.buoy_index < course.buoys.size() else "HOLD THE LINE"
	draw_string(font, Vector2(65, 590), next_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#ffd36e"))
	draw_string(font, Vector2(65, 625), "TIME %.1f s  ·  SCORE %d  ·  MISSED GATES %d" % [sim.elapsed, sim.score(), sim.gates_missed], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	if not sim.last_event.is_empty():
		draw_string(font, Vector2(65, 664), sim.last_event, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#70f0e5" if "CLEAN" in sim.last_event or "AVOIDED" in sim.last_event else "#ff7a86"))
	draw_string(font, Vector2(65, 750), "W / ↑ throttle  ·  A/D or ←/→ steer  ·  S / ↓ brake  ·  SHIFT boost  ·  START pause", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b9d5dd"))

func _draw_results() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 1280, 800), Color("#071b27"))
	draw_string(font, Vector2(72, 96), "HOVERCRAFT TIME ATTACK · FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("#70f0e5"))
	draw_string(font, Vector2(72, 186), "COURSE %02d  ·  %s" % [sim.course_index + 1, str(SimScript.COURSES[sim.course_index].name).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)
	draw_string(font, Vector2(72, 253), "RATING  " + sim.rating(), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#a4ffd4" if sim.finished else "#ff6878"))
	draw_string(font, Vector2(72, 305), "TIME  %.2f s   SCORE  %d   GATES  %d / %d   BUOYS AVOIDED %d" % [sim.elapsed, sim.score(), sim.gates_clean, SimScript.COURSES[sim.course_index].gates.size(), sim.buoys_avoided], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	draw_string(font, Vector2(72, 380), "EVENT  " + sim.last_event, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffd36e"))
	draw_string(font, Vector2(72, 480), "CAREER  %d finishes  ·  %d courses unlocked" % [completed_runs, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#9ab7c4"))
	draw_string(font, Vector2(72, 610), "A / ENTER  next unlocked course     B / ESC  course select", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#70f0e5"))

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

