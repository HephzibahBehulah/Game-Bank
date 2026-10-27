extends RefCounted
class_name MotorcycleHillSimulation

const COURSES: Array[Dictionary] = [
	{"name":"Red Ridge","length":900.0,"grip":0.94,"profile":[Vector2(0,0),Vector2(120,12),Vector2(260,28),Vector2(390,24),Vector2(540,49),Vector2(700,58),Vector2(900,80)],"jump":470.0,"jump_speed":20.0},
	{"name":"Gravel Switchbacks","length":1020.0,"grip":0.72,"profile":[Vector2(0,0),Vector2(110,18),Vector2(225,15),Vector2(350,42),Vector2(500,33),Vector2(645,61),Vector2(790,54),Vector2(1020,92)],"jump":680.0,"jump_speed":22.0},
	{"name":"Pine Needle Climb","length":1080.0,"grip":0.82,"profile":[Vector2(0,0),Vector2(160,20),Vector2(285,39),Vector2(420,34),Vector2(570,66),Vector2(720,77),Vector2(860,70),Vector2(1080,118)],"jump":510.0,"jump_speed":21.0},
	{"name":"Red Rock Steps","length":1160.0,"grip":0.88,"profile":[Vector2(0,0),Vector2(145,14),Vector2(260,37),Vector2(390,31),Vector2(525,58),Vector2(660,52),Vector2(825,88),Vector2(980,83),Vector2(1160,126)],"jump":745.0,"jump_speed":24.0},
	{"name":"Alpine Traverse","length":1250.0,"grip":0.68,"profile":[Vector2(0,0),Vector2(180,32),Vector2(305,40),Vector2(450,68),Vector2(590,61),Vector2(735,98),Vector2(875,92),Vector2(1040,129),Vector2(1250,151)],"jump":910.0,"jump_speed":23.0},
	{"name":"Volcanic Shelf","length":1320.0,"grip":0.8,"profile":[Vector2(0,0),Vector2(160,24),Vector2(290,23),Vector2(420,59),Vector2(555,72),Vector2(700,67),Vector2(845,106),Vector2(1010,101),Vector2(1160,145),Vector2(1320,162)],"jump":620.0,"jump_speed":25.0},
	{"name":"Moonstone Pass","length":1410.0,"grip":0.76,"profile":[Vector2(0,0),Vector2(175,33),Vector2(320,44),Vector2(465,78),Vector2(600,73),Vector2(745,112),Vector2(890,104),Vector2(1040,148),Vector2(1190,142),Vector2(1410,180)],"jump":1080.0,"jump_speed":26.0},
	{"name":"Summit of Storms","length":1500.0,"grip":0.64,"profile":[Vector2(0,0),Vector2(185,35),Vector2(330,30),Vector2(480,77),Vector2(625,86),Vector2(770,79),Vector2(920,128),Vector2(1070,118),Vector2(1230,164),Vector2(1360,157),Vector2(1500,205)],"jump":720.0,"jump_speed":27.0}
]
var course_index := 0
var distance := 0.0
var speed := 0.0
var pitch := 0.0
var airtime := 0.0
var elapsed := 0.0
var jump_done := false
var airborne := false
var finished := false
var crashed := false
var event := ""

func reset(index: int) -> void:
	course_index = posmod(index, COURSES.size())
	distance = 0.0
	speed = 0.0
	pitch = 0.0
	airtime = 0.0
	elapsed = 0.0
	jump_done = false
	airborne = false
	finished = false
	crashed = false
	event = ""

func terrain_height(at_distance: float) -> float:
	var points: Array = COURSES[course_index].profile
	var x := clampf(at_distance, 0.0, float(COURSES[course_index].length))
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		if x <= b.x:
			return lerpf(a.y, b.y, (x - a.x) / maxf(1.0, b.x - a.x))
	return float(points[-1].y)

func terrain_slope(at_distance: float) -> float:
	var course: Dictionary = COURSES[course_index]
	var before := terrain_height(maxf(0.0, at_distance - 8.0))
	var after := terrain_height(minf(float(course.length), at_distance + 8.0))
	return (after - before) / 16.0

func step(controls: Dictionary, delta: float) -> void:
	if finished or crashed:
		return
	var dt := clampf(delta, 0.0, 0.05)
	var throttle := clampf(float(controls.get("throttle", 0.0)), 0.0, 1.0)
	var brake := clampf(float(controls.get("brake", 0.0)), 0.0, 1.0)
	var lean := clampf(float(controls.get("lean", 0.0)), -1.0, 1.0)
	var course: Dictionary = COURSES[course_index]
	elapsed += dt
	var slope := terrain_slope(distance)
	var acceleration := throttle * 22.0 - brake * 35.0 - 2.8 - slope * 19.0
	if speed <= 0.0 and acceleration < 0.0:
		acceleration = 0.0
	speed = clampf(speed + acceleration * dt, 0.0, 42.0 * float(course.grip) + 10.0)
	var previous := distance
	distance += speed * dt
	if not airborne:
		var target_pitch := slope * 32.0 + throttle * 9.0 - brake * 12.0
		pitch = move_toward(pitch, target_pitch, 20.0 * dt)
		pitch += lean * 38.0 * dt
	else:
		airtime -= dt
		pitch += lean * 52.0 * dt
		if airtime <= 0.0:
			airborne = false
			if absf(pitch) > 47.0:
				crashed = true
				event = "HARD LANDING · RIDER DOWN"
			else:
				event = "CLEAN LANDING"
	if not jump_done and previous < float(course.jump) and distance >= float(course.jump):
		jump_done = true
		if speed < float(course.jump_speed):
			crashed = true
			event = "SHORT JUMP · GAP NOT CLEARED"
		else:
			airborne = true
			airtime = 0.78 + speed * 0.012
			event = "AIRBORNE · USE LEAN TO CONTROL PITCH"
	if absf(pitch) >= 68.0:
		crashed = true
		event = "LOOP-OUT · RIDER DOWN"
	elif distance >= float(course.length) and not crashed:
		distance = float(course.length)
		finished = true
		speed = 0.0
		event = "SUMMIT REACHED"

func rating() -> String:
	if crashed:
		return "CRASH"
	var factor := float(COURSES[course_index].length) / maxf(elapsed, 0.1)
	return "GOLD" if factor >= 14.5 else "SILVER" if factor >= 10.5 else "BRONZE"
