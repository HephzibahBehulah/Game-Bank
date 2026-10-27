extends Node2D

const SimulationScript = preload("res://scripts/motorcycle_hill_simulation.gd")
const SAVE_PATH := "user://motorcycle_hill_progress.json"
var simulation: MotorcycleHillSimulation
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
	if mode != "ride":
		return
	simulation.step(_controls(), delta)
	if simulation.finished or simulation.crashed:
		mode = "results"
		if simulation.finished:
			_record_finish()
	queue_redraw()

func _controls() -> Dictionary:
	var throttle := 1.0 if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) else 0.0
	var brake := 1.0 if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) else 0.0
	var lean := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var devices := Input.get_connected_joypads()
	devices.sort()
	if not devices.is_empty():
		var device: int = devices[0]
		throttle = maxf(throttle, clampf(Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT), 0.0, 1.0))
		brake = maxf(brake, clampf(Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT), 0.0, 1.0))
		var stick_x := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		if absf(stick_x) > 0.14:
			lean = signf(stick_x) * (absf(stick_x) - 0.14) / 0.86
	return {"throttle": throttle, "brake": brake, "lean": lean}

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
			mode = "ride"
		elif back:
			get_tree().change_scene_to_file("res://scenes/hub.tscn")
	elif mode == "ride" and (back or start):
		mode = "paused"
	elif mode == "paused":
		if _confirm(event) or start:
			mode = "ride"
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
	draw_rect(Rect2(Vector2.ZERO, frame_size), Color("#111923"))
	if mode == "briefing":
		_draw_briefing()
	elif mode == "ride" or mode == "paused":
		_draw_track()
		if mode == "paused":
			draw_rect(Rect2(395, 320, 490, 150), Color("#07111fee"))
			draw_string(ThemeDB.fallback_font, Vector2(510, 381), "RIDE PAUSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 31, Color("#69e8da"))
			draw_string(ThemeDB.fallback_font, Vector2(450, 426), "A / ENTER resume  ·  B / ESC course select", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	elif mode == "results":
		_draw_results()

func _draw_briefing() -> void:
	var font := ThemeDB.fallback_font
	var course: Dictionary = SimulationScript.COURSES[selected_course]
	draw_string(font, Vector2(76, 86), "MOTORCYCLE HILL CLIMB", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("#ffbb68"))
	draw_string(font, Vector2(78, 124), "EIGHT AUTHORED SUMMIT ROUTES  ·  BALANCE SPEED, TRACTION AND PITCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#cfdae4"))
	draw_string(font, Vector2(78, 195), "STAGE %02d / 08  ·  UNLOCKED %02d" % [selected_course + 1, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#68e8d6"))
	draw_string(font, Vector2(78, 248), str(course.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
	draw_string(font, Vector2(78, 287), "CLIMB %d m  ·  TRACTION %d%%" % [int(course.profile[-1].y), int(float(course.grip) * 100.0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#bccbd5"))
	draw_string(font, Vector2(78, 352), "RIDE TO THE SUMMIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffbb68"))
	draw_string(font, Vector2(78, 384), "Manage throttle and brake on changing grades. Lean against pitch to stabilize the bike.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(font, Vector2(78, 416), "Clear the marked jump at speed, then control your landing pitch. A loop-out ends the run.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#bccbd5"))
	draw_string(font, Vector2(78, 515), "KEYBOARD  W / ↑ throttle  ·  S / ↓ brake  ·  A / D lean  ·  ← / → stage", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#68e8d6"))
	draw_string(font, Vector2(78, 548), "GAMEPAD  RT throttle  ·  LT brake  ·  left stick left/right lean  ·  D-pad select  ·  A start", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#cfdae4"))
	draw_string(font, Vector2(78, 611), "CAREER  %d summit finishes  ·  best stage %02d" % [completed_courses, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9ab7c4"))
	draw_rect(Rect2(430, 664, 420, 68), Color("#8a5030"), false, 3.0)
	draw_string(font, Vector2(496, 706), "START STAGE  ·  A / ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(font, Vector2(78, 760), "ESC / B returns to the game hub  ·  Complete a summit to unlock the next stage", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#849ba9"))

func _draw_track() -> void:
	var font := ThemeDB.fallback_font
	var course: Dictionary = SimulationScript.COURSES[simulation.course_index]
	draw_rect(Rect2(0, 0, 1280, 580), Color("#233644"))
	draw_circle(Vector2(1080, 118), 48, Color("#ffcf72"))
	draw_polygon(PackedVector2Array([Vector2(0, 430), Vector2(150, 260), Vector2(290, 420), Vector2(455, 225), Vector2(640, 420), Vector2(820, 270), Vector2(1000, 435), Vector2(1280, 245), Vector2(1280, 590), Vector2(0, 590)]), PackedColorArray([Color("#344e4b")]))
	var track := PackedVector2Array()
	var scale_x := 0.72
	for sample in range(36):
		var world_x := clampf(simulation.distance - 210.0 + float(sample) * 48.0, 0.0, float(course.length))
		var screen_x := 260.0 + (world_x - simulation.distance) * scale_x
		var screen_y := 520.0 - simulation.terrain_height(world_x) * 1.42
		track.append(Vector2(screen_x, screen_y))
	draw_polyline(track, Color("#bb9362"), 34.0, true)
	draw_polyline(track, Color("#63805b"), 24.0, true)
	for point in track:
		draw_circle(point, 2.5, Color("#a7bf78"))
	var jump_x := 260.0 + (float(course.jump) - simulation.distance) * scale_x
	if jump_x > 28.0 and jump_x < 1250.0:
		var jump_y := 520.0 - simulation.terrain_height(float(course.jump)) * 1.42
		draw_colored_polygon(PackedVector2Array([Vector2(jump_x - 18, jump_y - 14), Vector2(jump_x + 20, jump_y - 14), Vector2(jump_x + 2, jump_y - 54)]), Color("#ff985a"))
		draw_string(font, Vector2(jump_x - 68, jump_y - 66), "JUMP", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffe2a3"))
	var ground := 520.0 - simulation.terrain_height(simulation.distance) * 1.42
	var bike_ground := ground - (64.0 if simulation.airborne else 0.0)
	var center := Vector2(260.0, bike_ground - 22.0)
	var angle := deg_to_rad(-simulation.pitch)
	draw_line(center + Vector2(-28, 16), center + Vector2(30, 16), Color("#e7a749"), 8.0)
	draw_circle((center + Vector2(-24, 22)).rotated(angle), 18, Color("#161b22"))
	draw_circle((center + Vector2(26, 22)).rotated(angle), 18, Color("#161b22"))
	draw_circle((center + Vector2(-24, 22)).rotated(angle), 8, Color("#a6b4b8"))
	draw_circle((center + Vector2(26, 22)).rotated(angle), 8, Color("#a6b4b8"))
	var chassis := PackedVector2Array([center + Vector2(-20, 5).rotated(angle), center + Vector2(12, 0).rotated(angle), center + Vector2(24, -20).rotated(angle), center + Vector2(-5, -26).rotated(angle)])
	draw_colored_polygon(chassis, Color("#e9a742"))
	draw_line(center + Vector2(0, -24).rotated(angle), center + Vector2(-4, -55).rotated(angle), Color("#63d6cc"), 8.0)
	draw_circle(center + Vector2(-2, -60).rotated(angle), 12, Color("#f0e2c8"))
	draw_rect(Rect2(34, 24, 1212, 132), Color("#07111de8"))
	draw_string(font, Vector2(60, 62), "%s  ·  %04d / %04d m" % [str(course.name).to_upper(), int(simulation.distance), int(course.length)], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffbb68"))
	draw_string(font, Vector2(60, 102), "SPEED %02d km/h" % int(simulation.speed), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(font, Vector2(310, 102), "PITCH %02d° / 68°" % int(simulation.pitch), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ff8a75") if absf(simulation.pitch) > 44.0 else Color("#68e8d6"))
	draw_string(font, Vector2(600, 102), "TRACTION %02d%%" % int(float(course.grip) * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(font, Vector2(900, 102), "JUMP CLEARED" if simulation.jump_done else "JUMP AHEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffcf72"))
	draw_string(font, Vector2(60, 196), simulation.event, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffe2a3"))
	draw_string(font, Vector2(60, 748), "RT / W throttle  ·  LT / S brake  ·  Left stick / A-D lean  ·  START / ESC pause", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#e4e8e2"))

func _draw_results() -> void:
	var won := simulation.finished
	draw_rect(Rect2(110, 90, 1060, 620), Color("#09151fee"))
	draw_string(ThemeDB.fallback_font, Vector2(170, 170), "SUMMIT REACHED" if won else "RIDE OVER · CRASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("#ffcf72") if won else Color("#ff806f"))
	draw_string(ThemeDB.fallback_font, Vector2(174, 222), "%s  ·  %s" % [str(SimulationScript.COURSES[simulation.course_index].name).to_upper(), simulation.rating()], HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#68e8d6"))
	draw_string(ThemeDB.fallback_font, Vector2(174, 282), "TIME %0.1f s  ·  DISTANCE %d / %d m" % [simulation.elapsed, int(simulation.distance), int(SimulationScript.COURSES[simulation.course_index].length)], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(174, 365), "CAREER  %d summit finishes  ·  %d stages unlocked" % [completed_courses, unlocked_courses], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#afc5ce"))
	draw_string(ThemeDB.fallback_font, Vector2(174, 560), "A / ENTER continue to stage select  ·  B / ESC retry", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

func _record_finish() -> void:
	completed_courses += 1
	best_times[simulation.course_index] = minf(best_times[simulation.course_index], simulation.elapsed)
	unlocked_courses = maxi(unlocked_courses, mini(SimulationScript.COURSES.size(), simulation.course_index + 2))
	_save_progress()

func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save Motorcycle Hill Climb progress: %s" % error_string(FileAccess.get_open_error()))
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
		push_warning("Motorcycle Hill Climb career file is invalid; a new career will start.")
		return
	unlocked_courses = clampi(int(data.get("unlocked_courses", 1)), 1, SimulationScript.COURSES.size())
	completed_courses = maxi(0, int(data.get("completed_courses", 0)))
	var saved: Array = data.get("best_times", [])
	for index in range(mini(saved.size(), best_times.size())):
		best_times[index] = maxf(0.0, float(saved[index]))
