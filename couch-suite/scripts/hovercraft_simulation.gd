extends RefCounted

const COURSES: Array[Dictionary] = [
	{"name":"Lagoon Sprint","length":1150.0,"thrust":15.0,"drag":1.6,"chop":0.08,"wind":0.08,"gates":[{"at":190.0,"lane":-0.55},{"at":420.0,"lane":0.55},{"at":680.0,"lane":-0.5},{"at":950.0,"lane":0.5}],"buoys":[{"at":310.0,"lane":0.0,"name":"PIER BUOYS"},{"at":760.0,"lane":0.0,"name":"SHOAL MARKER"}]},
	{"name":"Sounding Strait","length":1280.0,"thrust":15.5,"drag":1.9,"chop":0.19,"wind":0.32,"gates":[{"at":210.0,"lane":0.55},{"at":470.0,"lane":-0.55},{"at":760.0,"lane":0.5},{"at":1080.0,"lane":-0.5}],"buoys":[{"at":340.0,"lane":0.0,"name":"FERRY CHANNEL"},{"at":850.0,"lane":0.0,"name":"REEF BUOYS"}]},
	{"name":"Delta Flood Run","length":1390.0,"thrust":14.0,"drag":1.45,"chop":0.14,"wind":0.26,"gates":[{"at":230.0,"lane":-0.5},{"at":520.0,"lane":0.5},{"at":830.0,"lane":-0.55},{"at":1160.0,"lane":0.5}],"buoys":[{"at":390.0,"lane":0.0,"name":"RIVER POSTS"},{"at":940.0,"lane":0.0,"name":"FLOATING TIMBER"}]},
	{"name":"Ice Shelf Circuit","length":1470.0,"thrust":16.0,"drag":2.25,"chop":0.12,"wind":0.4,"gates":[{"at":245.0,"lane":0.55},{"at":550.0,"lane":-0.55},{"at":890.0,"lane":0.55},{"at":1230.0,"lane":-0.5}],"buoys":[{"at":410.0,"lane":0.0,"name":"ICE RIDGE"},{"at":1000.0,"lane":0.0,"name":"PRESSURE FLOE"}]},
	{"name":"Marina Night Run","length":1540.0,"thrust":15.0,"drag":1.75,"chop":0.1,"wind":0.18,"gates":[{"at":260.0,"lane":-0.55},{"at":580.0,"lane":0.55},{"at":950.0,"lane":-0.5},{"at":1300.0,"lane":0.5}],"buoys":[{"at":430.0,"lane":0.0,"name":"DOCK PILINGS"},{"at":1080.0,"lane":0.0,"name":"MOORING LINE"}]},
	{"name":"Canyon Reservoir","length":1640.0,"thrust":14.5,"drag":1.7,"chop":0.24,"wind":0.3,"gates":[{"at":280.0,"lane":0.5},{"at":630.0,"lane":-0.55},{"at":1010.0,"lane":0.55},{"at":1390.0,"lane":-0.5}],"buoys":[{"at":470.0,"lane":0.0,"name":"NARROW CUT"},{"at":1170.0,"lane":0.0,"name":"WAVE BREAK"}]},
	{"name":"Monsoon Estuary","length":1730.0,"thrust":16.0,"drag":2.0,"chop":0.3,"wind":0.48,"gates":[{"at":300.0,"lane":-0.55},{"at":680.0,"lane":0.55},{"at":1090.0,"lane":-0.5},{"at":1480.0,"lane":0.5}],"buoys":[{"at":510.0,"lane":0.0,"name":"RAIN SQUALL"},{"at":1280.0,"lane":0.0,"name":"BREAKING WAKE"}]},
	{"name":"World Cup Final Lap","length":1860.0,"thrust":16.5,"drag":1.8,"chop":0.2,"wind":0.36,"gates":[{"at":320.0,"lane":0.55},{"at":740.0,"lane":-0.55},{"at":1210.0,"lane":0.55},{"at":1610.0,"lane":-0.5}],"buoys":[{"at":550.0,"lane":0.0,"name":"CHICANE BUOYS"},{"at":1390.0,"lane":0.0,"name":"FINISH WAKE"}]}
]
const MAX_SPEED := 52.0
const TRACK_EDGE := 1.0

var course_index := 0
var distance := 0.0
var speed := 8.0
var lane := 0.0
var integrity := 100.0
var boost_energy := 100.0
var elapsed := 0.0
var gate_index := 0
var buoy_index := 0
var gates_clean := 0
var gates_missed := 0
var buoys_avoided := 0
var finished := false
var wrecked := false
var last_event := ""

func reset(course: int) -> void:
	course_index = posmod(course, COURSES.size())
	distance = 0.0
	speed = 8.0
	lane = 0.0
	integrity = 100.0
	boost_energy = 100.0
	elapsed = 0.0
	gate_index = 0
	buoy_index = 0
	gates_clean = 0
	gates_missed = 0
	buoys_avoided = 0
	finished = false
	wrecked = false
	last_event = "START · twin-fan hovercraft"

func step(controls: Dictionary, delta: float) -> void:
	if finished or wrecked:
		return
	var dt := clampf(delta, 0.0, 0.05)
	var course: Dictionary = COURSES[course_index]
	var previous := distance
	elapsed += dt
	var throttle := clampf(float(controls.get("throttle", 0.0)), 0.0, 1.0)
	var brake := clampf(float(controls.get("brake", 0.0)), 0.0, 1.0)
	var steer := clampf(float(controls.get("steer", 0.0)), -1.0, 1.0)
	var boosting := bool(controls.get("boost", false)) and boost_energy > 0.0
	var push := sin(distance * 0.008 + float(course_index) * 1.7) * float(course.wind)
	var current := sin(distance * 0.003 + float(course_index)) * float(course.chop)
	var acceleration := float(course.thrust) * throttle - float(course.drag) - speed * 0.035 - brake * 23.0
	if boosting:
		acceleration += 8.0
		boost_energy = maxf(0.0, boost_energy - 26.0 * dt)
	else:
		boost_energy = minf(100.0, boost_energy + 5.0 * dt)
	speed = clampf(speed + acceleration * dt, 0.0, MAX_SPEED)
	var steering_power := (0.42 + speed * 0.026)
	lane = clampf(lane + (steer * steering_power + push + current) * dt, -TRACK_EDGE, TRACK_EDGE)
	distance += speed * dt * (1.0 - absf(lane) * 0.04)
	var stress := maxf(0.0, absf(steer) * speed - 34.0) * float(course.chop)
	integrity = clampf(integrity - stress * 0.012 * dt, 0.0, 100.0)
	if absf(lane) >= 0.985:
		integrity = maxf(0.0, integrity - (4.0 + float(course.chop) * 10.0) * dt)
	last_event = ""
	var gates: Array = course.gates
	if gate_index < gates.size():
		var gate: Dictionary = gates[gate_index]
		if previous < float(gate.at) and distance >= float(gate.at):
			if absf(lane - float(gate.lane)) <= 0.29:
				gates_clean += 1
				last_event = "GATE CLEAN · %d/%d" % [gate_index + 1, gates.size()]
			else:
				gates_missed += 1
				integrity = maxf(0.0, integrity - 6.0)
				last_event = "GATE MISSED · LINE BONUS LOST"
			gate_index += 1
	var buoys: Array = course.buoys
	if buoy_index < buoys.size():
		var buoy: Dictionary = buoys[buoy_index]
		if previous < float(buoy.at) and distance >= float(buoy.at):
			if absf(lane - float(buoy.lane)) < 0.25:
				integrity = maxf(0.0, integrity - 24.0)
				speed *= 0.55
				last_event = "BUOY STRIKE · %s" % buoy.name
			else:
				buoys_avoided += 1
				last_event = "WAKE AVOIDED · %s" % buoy.name
			buoy_index += 1
	if integrity <= 0.0:
		wrecked = true
		last_event = "HULL FAILURE · RACE OVER"
	elif distance >= float(course.length):
		distance = float(course.length)
		finished = true
		last_event = "FINISH · CLEAN WATER"

func rating() -> String:
	if wrecked:
		return "DNF"
	var clean := float(gates_clean) / maxf(float(COURSES[course_index].gates.size()), 1.0)
	var target_time := float(COURSES[course_index].length) / 32.0
	var pace := elapsed / target_time
	if clean >= 0.75 and pace <= 1.35:
		return "GOLD"
	if clean >= 0.5 and pace <= 1.85:
		return "SILVER"
	return "BRONZE"

func score() -> int:
	return int(distance * 0.28) + gates_clean * 300 + buoys_avoided * 120 - gates_missed * 100 - int(100.0 - integrity) * 8

