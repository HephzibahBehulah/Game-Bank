extends Node2D

const SimulationScript = preload("res://scripts/truck_trial_simulation.gd")
const SAVE_PATH := "user://truck_trial_progress.json"
var simulation: TruckTrialSimulation
var mode := "briefing"
var selected_course := 0
var unlocked_courses := 1
var completed_courses := 0
var best_times: Array[float] = []
var frame_size := Vector2(1280, 800)

func _ready() -> void:
	_load_progress()
	simulation = SimulationScript.new()
	simulation.reset(selected_course)
	queue_redraw()

func _process(delta: float) -> void:
	if mode != "drive":
		return
	simulation.step(_controls(), delta)
	if simulation.finished or simulation.rolled_over:
		mode = "results"
		if simulation.finished:
			_record_finish()
	queue_redraw()

func _controls() -> Dictionary:
	var throttle := float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var brake := float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	var crane := float(Input.is_key_pressed(KEY_T)) - float(Input.is_key_pressed(KEY_G))
	var devices := Input.get_connected_joypads()
	devices.sort()
	if not devices.is_empty():
		var device: int = devices[0]
		throttle = maxf(throttle, clampf(Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT), 0.0, 1.0))
		brake = maxf(brake, clampf(Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT), 0.0, 1.0))
		var stick_y := Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
		if absf(stick_y) > 0.16:
			crane = -stick_y
	return {"throttle": throttle, "brake": brake, "crane": crane}

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
			simulation.reset(selected_course)
			mode = "drive"
		elif back:
			get_tree().change_scene_to_file("res://scenes/hub.tscn")
	elif mode == "drive" and (back or start):
		mode = "paused"
	elif mode == "paused":
		if _confirm(event) or start:
			mode = "drive"
		elif back:
			mode = "briefing"
	elif mode == "results":
		if _confirm(event):
			selected_course = mini(selected_course + 1, unlocked_courses - 1) if simulation.finished else selected_course
			mode = "briefing"
		elif back:
			mode = "briefing"
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, frame_size), Color("#101820"))
	if mode == "briefing":
		_draw_briefing()
	elif mode == "drive" or mode == "paused":
		_draw_drive()
		if mode == "paused":
			draw_rect(Rect2(400, 320, 480, 150), Color("#07111fee"))
			draw_string(ThemeDB.fallback_font, Vector2(500, 380), "TRUCK STOPPED", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#75ead7"))
			draw_string(ThemeDB.fallback_font, Vector2(450, 425), "A / ENTER resume  ·  B / ESC course select", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	elif mode == "results":
		_draw_results()

func _draw_briefing() -> void:
	var font := ThemeDB.fallback_font
	var course: Dictionary = SimulationScript.COURSES[selected_course]
	draw_string(font, Vector2(74, 84), "TRUCK TRIAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color("#ffd36f"))
	draw_string(font, Vector2(76, 122), "HEAVY RIG  ·  EIGHT AUTHORED OBSTACLE COURSES", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#d3e0e6"))
	draw_string(font, Vector2(76, 191), "COURSE %02d / 08  ·  UNLOCKED %02d" % [selected_course + 1, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#75ead7"))
	draw_string(font, Vector2(76, 243), str(course.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
	draw_string(font, Vector2(76, 280), "DISTANCE %d m  ·  TERRAIN LOAD %d%%" % [int(course.length), int(float(course.roughness) * 100.0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#b9c9d4"))
	draw_string(font, Vector2(76, 342), "MISSION", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffd36f"))
	draw_string(font, Vector2(76, 373), "Reach the finish without exceeding the 48° rollover limit.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(font, Vector2(76, 403), "Slow before obstacles. Braking settles the cab; speed creates impact and body roll.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#b9c9d4"))
	if bool(course.get("crane", false)):
		draw_string(font, Vector2(76, 444), "CRANE COURSE  ·  Raise the arm before the marked lift obstacle.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffbb69"))
	draw_string(font, Vector2(76, 510), "KEYBOARD  W / ↑ throttle  ·  S / ↓ brake  ·  T / G crane  ·  ← / → course", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#75ead7"))
	draw_string(font, Vector2(76, 542), "GAMEPAD  RT throttle  ·  LT brake  ·  right stick up/down crane  ·  D-pad select  ·  A start", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c7d5de"))
	draw_string(font, Vector2(76, 604), "CAREER  %d finishes  ·  best stage %02d" % [completed_courses, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9bb7c5"))
	draw_rect(Rect2(430, 660, 420, 68), Color("#197d75"), false, 3.0)
	draw_string(font, Vector2(494, 702), "START COURSE  ·  A / ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(font, Vector2(76, 760), "ESC / B returns to the 100-game hub  ·  Only completed stages unlock", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#869eaa"))

func _draw_drive() -> void:
	var font := ThemeDB.fallback_font
	var course: Dictionary = SimulationScript.COURSES[simulation.course_index]
	draw_rect(Rect2(0, 0, 1280, 560), Color("#1a2c35"))
	draw_circle(Vector2(1030, 120), 55, Color("#ffcb67"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 455), Vector2(170, 300), Vector2(310, 450), Vector2(480, 260), Vector2(675, 455), Vector2(860, 320), Vector2(1030, 460), Vector2(1280, 280), Vector2(1280, 570), Vector2(0, 570)]), Color("#263e42"))
	var ground_y := 518.0 + sin(simulation.progress * 0.036) * 18.0
	draw_rect(Rect2(0, ground_y + 18.0, 1280, 282), Color("#584b36"))
	draw_line(Vector2(0, ground_y + 18.0), Vector2(1280, ground_y + 18.0), Color("#a38a58"), 5.0)
	var truck_x := 340.0
	var pitch := deg_to_rad(simulation.tilt)
	var cab := PackedVector2Array([Vector2(-72, -72), Vector2(55, -72), Vector2(74, -26), Vector2(70, 0), Vector2(-76, 0)])
	var body := PackedVector2Array()
	for point in cab:
		body.append(Vector2(truck_x, ground_y - 18.0) + point.rotated(pitch))
	draw_colored_polygon(body, Color("#e1a942"))
	draw_polyline(body + PackedVector2Array([body[0]]), Color("#fff0be"), 3.0)
	draw_rect(Rect2(truck_x + 9, ground_y - 80, 33, 30), Color("#8fd5dc"))
	draw_circle(Vector2(truck_x - 42, ground_y + 8), 25, Color("#15191d"))
	draw_circle(Vector2(truck_x + 46, ground_y + 8), 25, Color("#15191d"))
	draw_circle(Vector2(truck_x - 42, ground_y + 8), 11, Color("#bdc5c8"))
	draw_circle(Vector2(truck_x + 46, ground_y + 8), 11, Color("#bdc5c8"))
	if bool(course.get("crane", false)):
		var arm_start := Vector2(truck_x + 40, ground_y - 70)
		var arm_end := arm_start + Vector2(110.0 * simulation.crane_angle, -110.0 * simulation.crane_angle)
		draw_line(arm_start, arm_end, Color("#ffbf65"), 9.0)
		draw_line(arm_end, arm_end + Vector2(0, 24), Color("#f4f4e8"), 4.0)
	var next_hazard: Dictionary = course.obstacles[mini(simulation.obstacle_index, course.obstacles.size() - 1)]
	var hazard_dx := float(next_hazard.at) - simulation.progress
	if simulation.obstacle_index < course.obstacles.size() and hazard_dx < 460.0:
		var hazard_x := truck_x + maxf(65.0, hazard_dx * 0.58)
		draw_rect(Rect2(hazard_x - 25, ground_y - 48, 50, 48), Color("#d66c55"))
		draw_string(font, Vector2(hazard_x - 120, ground_y - 58), str(next_hazard.kind), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffe9bd"))
	draw_rect(Rect2(36, 26, 1208, 126), Color("#061019e8"))
	draw_string(font, Vector2(62, 62), "%s  ·  %04d / %04d m" % [str(course.name).to_upper(), int(simulation.progress), int(course.length)], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffd36f"))
	draw_string(font, Vector2(62, 99), "SPEED %02d km/h" % int(simulation.speed), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(font, Vector2(292, 99), "BODY ROLL %02d° / 48°" % int(absf(simulation.tilt)), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ff9e75") if absf(simulation.tilt) > 28 else Color("#75ead7"))
	draw_string(font, Vector2(590, 99), "CRANE %02d%%" % int(simulation.crane_angle * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffbf65"))
	draw_string(font, Vector2(890, 99), "OBSTACLES %d / %d" % [simulation.obstacle_index, course.obstacles.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(font, Vector2(62, 202), simulation.last_event, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffd36f"))
	if simulation.obstacle_index < course.obstacles.size():
		var warning: Dictionary = course.obstacles[simulation.obstacle_index]
		var remaining := maxf(0.0, float(warning.at) - simulation.progress)
		draw_string(font, Vector2(62, 238), "NEXT %s  ·  %03d m  ·  TARGET %02d km/h" % [str(warning.kind), int(remaining), int(warning.safe_speed)], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffbf65"))
	draw_string(font, Vector2(62, 748), "RT / W throttle  ·  LT / S brake  ·  right stick / T-G crane  ·  START / ESC pause", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#e3e8e5"))

func _draw_results() -> void:
	var won := simulation.finished
	draw_rect(Rect2(110, 90, 1060, 620), Color("#09151fee"))
	draw_string(ThemeDB.fallback_font, Vector2(170, 170), "STAGE COMPLETE" if won else "ROLLOVER · STAGE FAILED", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("#ffd36f") if won else Color("#ff806f"))
	draw_string(ThemeDB.fallback_font, Vector2(174, 222), "%s  ·  %s" % [str(SimulationScript.COURSES[simulation.course_index].name).to_upper(), simulation.result_rating()], HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#75ead7"))
	draw_string(ThemeDB.fallback_font, Vector2(174, 282), "TIME %0.1f s  ·  MAX ROLL %0.1f°" % [simulation.elapsed, absf(simulation.tilt)], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(174, 326), "OBSTACLES CLEARED %d / %d" % [simulation.obstacle_index, SimulationScript.COURSES[simulation.course_index].obstacles.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#c3d3dc"))
	draw_string(ThemeDB.fallback_font, Vector2(174, 397), "CAREER  %d finishes  ·  %d courses unlocked" % [completed_courses, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#a9c1cd"))
	draw_string(ThemeDB.fallback_font, Vector2(174, 560), "A / ENTER continue to course select  ·  B / ESC retry or return", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

func _record_finish() -> void:
	completed_courses += 1
	best_times[simulation.course_index] = minf(best_times[simulation.course_index], simulation.elapsed)
	unlocked_courses = maxi(unlocked_courses, mini(SimulationScript.COURSES.size(), simulation.course_index + 2))
	_save_progress()

func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save Truck Trial progress: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({"version": 1, "unlocked_courses": unlocked_courses, "completed_courses": completed_courses, "best_times": best_times}, "\t"))

func _load_progress() -> void:
	best_times.resize(SimulationScript.COURSES.size())
	best_times.fill(999999.0)
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or int(data.get("version", 0)) != 1:
		push_warning("Truck Trial career file is invalid; a new career will start.")
		return
	unlocked_courses = clampi(int(data.get("unlocked_courses", 1)), 1, SimulationScript.COURSES.size())
	completed_courses = maxi(0, int(data.get("completed_courses", 0)))
	var saved: Array = data.get("best_times", [])
	for index in range(mini(saved.size(), best_times.size())):
		best_times[index] = maxf(0.0, float(saved[index]))



