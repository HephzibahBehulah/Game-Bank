extends RefCounted
class_name TruckTrialSimulation

const COURSES: Array[Dictionary] = [
	{"name":"Quarry Approach","length":950.0,"roughness":0.24,"obstacles":[{"at":245.0,"kind":"RUTS","safe_speed":43.0},{"at":580.0,"kind":"ROCK STEP","safe_speed":31.0}]},
	{"name":"Pine Ridge","length":1080.0,"roughness":0.38,"obstacles":[{"at":280.0,"kind":"LOG BRIDGE","safe_speed":30.0},{"at":690.0,"kind":"SHELF DROP","safe_speed":34.0}]},
	{"name":"Floodplain","length":1120.0,"roughness":0.31,"obstacles":[{"at":315.0,"kind":"MUD BOG","safe_speed":29.0},{"at":780.0,"kind":"WASHOUT","safe_speed":32.0}]},
	{"name":"Crane Yard","length":1180.0,"roughness":0.28,"crane":true,"obstacles":[{"at":330.0,"kind":"LIFT GATE","safe_speed":24.0,"crane":true,"angle":0.48},{"at":810.0,"kind":"CONCRETE BLOCK","safe_speed":30.0}]},
	{"name":"Basalt Steps","length":1260.0,"roughness":0.46,"obstacles":[{"at":365.0,"kind":"BROKEN ROCK","safe_speed":27.0},{"at":860.0,"kind":"NARROW CREST","safe_speed":29.0}]},
	{"name":"Glacier Run","length":1320.0,"roughness":0.35,"obstacles":[{"at":390.0,"kind":"ICE RUT","safe_speed":26.0},{"at":930.0,"kind":"SNOW RIDGE","safe_speed":28.0}]},
	{"name":"Canyon Haul","length":1420.0,"roughness":0.42,"obstacles":[{"at":420.0,"kind":"CANYON RUT","safe_speed":25.0},{"at":1010.0,"kind":"LOOSE BOULDERS","safe_speed":27.0}]},
	{"name":"Timber Recovery","length":1500.0,"roughness":0.4,"crane":true,"obstacles":[{"at":430.0,"kind":"FALLEN PINE","safe_speed":24.0,"crane":true,"angle":0.6},{"at":1090.0,"kind":"SLOPE BREAK","safe_speed":25.0}]}
]
const MAX_TILT := 48.0
var course_index := 0
var progress := 0.0
var speed := 0.0
var tilt := 0.0
var crane_angle := 0.0
var obstacle_index := 0
var elapsed := 0.0
var finished := false
var rolled_over := false
var last_event := ""

func reset(course: int) -> void:
	course_index = posmod(course, COURSES.size())
	progress = 0.0
	speed = 0.0
	tilt = 0.0
	crane_angle = 0.0
	obstacle_index = 0
	elapsed = 0.0
	finished = false
	rolled_over = false
	last_event = ""

func step(controls: Dictionary, delta: float) -> void:
	if finished or rolled_over:
		return
	var dt := clampf(delta, 0.0, 0.05)
	var previous := progress
	elapsed += dt
	var throttle := clampf(float(controls.get("throttle", 0.0)), 0.0, 1.0)
	var brake := clampf(float(controls.get("brake", 0.0)), 0.0, 1.0)
	var crane := clampf(float(controls.get("crane", 0.0)), -1.0, 1.0)
	var course: Dictionary = COURSES[course_index]
	crane_angle = clampf(crane_angle + crane * dt * 0.95, 0.0, 1.0)
	var max_speed := 54.0 * (1.0 - float(course.roughness) * 0.2)
	speed = move_toward(speed, max_speed * throttle, (7.2 + 14.0 * brake) * dt)
	if throttle < 0.05 and brake < 0.05:
		speed = move_toward(speed, 0.0, 1.2 * dt)
	progress += speed * dt
	var terrain_pitch := sin(progress * 0.036) * float(course.roughness) * 5.5
	tilt = move_toward(tilt, terrain_pitch, (1.25 + brake * 2.1) * dt)
	last_event = ""
	var hazards: Array = course.obstacles
	if obstacle_index < hazards.size():
		var hazard: Dictionary = hazards[obstacle_index]
		if previous < float(hazard.at) and progress >= float(hazard.at):
			var safe_speed := float(hazard.safe_speed)
			if bool(hazard.get("crane", false)) and crane_angle >= float(hazard.angle):
				last_event = "CRANE CLEAR · %s" % hazard.kind
				crane_angle = maxf(0.0, crane_angle - 0.24)
			else:
				var excess := maxf(0.0, speed - safe_speed)
				var impact := 7.0 + excess * 0.92
				tilt += impact * (1.0 + float(course.roughness))
				speed *= 0.56 if excess > 0.0 else 0.78
				last_event = "HARD IMPACT · %s" % hazard.kind if excess > 0.0 else "CONTROLLED · %s" % hazard.kind
			obstacle_index += 1
	if absf(tilt) >= MAX_TILT:
		rolled_over = true
		last_event = "ROLLOVER · RECOVERY REQUIRED"
	elif progress >= float(course.length):
		progress = float(course.length)
		finished = true
		speed = 0.0
		last_event = "STAGE COMPLETE · TRUCK STAYED UPRIGHT"

func result_rating() -> String:
	if rolled_over:
		return "ROLLOVER"
	if elapsed < float(COURSES[course_index].length) / 32.0:
		return "GOLD"
	if elapsed < float(COURSES[course_index].length) / 20.0:
		return "SILVER"
	return "BRONZE"
