extends RefCounted


const COURSES: Array[Dictionary] = [
	{"name":"Harbor Hill","length":1200.0,"grade":0.18,"grip":0.91,"roughness":0.12,"gates":[{"at":220.0,"lane":-0.55},{"at":480.0,"lane":0.52},{"at":760.0,"lane":-0.4},{"at":1030.0,"lane":0.45}],"hazards":[{"at":365.0,"lane":0.0,"name":"FORKLIFT CROSSING","safe_speed":24.0},{"at":875.0,"lane":0.0,"name":"WET COBBLES","safe_speed":26.0}]},
	{"name":"Pine Switchbacks","length":1320.0,"grade":0.16,"grip":0.78,"roughness":0.25,"gates":[{"at":240.0,"lane":0.55},{"at":515.0,"lane":-0.55},{"at":815.0,"lane":0.45},{"at":1100.0,"lane":-0.45}],"hazards":[{"at":390.0,"lane":0.0,"name":"PINE NEEDLES","safe_speed":21.0},{"at":930.0,"lane":0.0,"name":"TIGHT HAIRPIN","safe_speed":19.0}]},
	{"name":"Old Quarry Drop","length":1450.0,"grade":0.23,"grip":0.7,"roughness":0.34,"gates":[{"at":260.0,"lane":-0.5},{"at":590.0,"lane":0.5},{"at":900.0,"lane":-0.5},{"at":1220.0,"lane":0.5}],"hazards":[{"at":440.0,"lane":0.0,"name":"GRAVEL FAN","safe_speed":18.0},{"at":1060.0,"lane":0.0,"name":"BROKEN PAVING","safe_speed":20.0}]},
	{"name":"Vineyard S Bend","length":1500.0,"grade":0.15,"grip":0.94,"roughness":0.15,"gates":[{"at":280.0,"lane":0.55},{"at":610.0,"lane":-0.55},{"at":960.0,"lane":0.55},{"at":1280.0,"lane":-0.45}],"hazards":[{"at":470.0,"lane":0.0,"name":"IRRIGATION RUNOFF","safe_speed":22.0},{"at":1110.0,"lane":0.0,"name":"HARVEST CART","safe_speed":25.0}]},
	{"name":"Lighthouse Road","length":1580.0,"grade":0.2,"grip":0.85,"roughness":0.28,"gates":[{"at":300.0,"lane":-0.55},{"at":660.0,"lane":0.55},{"at":1030.0,"lane":-0.5},{"at":1370.0,"lane":0.5}],"hazards":[{"at":500.0,"lane":0.0,"name":"WIND GUST","safe_speed":21.0},{"at":1200.0,"lane":0.0,"name":"COAST ROAD DIP","safe_speed":22.0}]},
	{"name":"Alpine Promenade","length":1680.0,"grade":0.17,"grip":0.81,"roughness":0.31,"gates":[{"at":320.0,"lane":0.5},{"at":700.0,"lane":-0.55},{"at":1110.0,"lane":0.5},{"at":1470.0,"lane":-0.5}],"hazards":[{"at":535.0,"lane":0.0,"name":"MELT WATER","safe_speed":20.0},{"at":1290.0,"lane":0.0,"name":"CATTLE GRID","safe_speed":19.0}]},
	{"name":"City Stairway","length":1770.0,"grade":0.21,"grip":0.75,"roughness":0.4,"gates":[{"at":340.0,"lane":-0.55},{"at":740.0,"lane":0.55},{"at":1170.0,"lane":-0.5},{"at":1540.0,"lane":0.5}],"hazards":[{"at":570.0,"lane":0.0,"name":"DRAIN CHANNEL","safe_speed":17.0},{"at":1370.0,"lane":0.0,"name":"MARKET SQUARE","safe_speed":18.0}]},
	{"name":"Championship Descent","length":1900.0,"grade":0.19,"grip":0.88,"roughness":0.24,"gates":[{"at":360.0,"lane":0.55},{"at":790.0,"lane":-0.55},{"at":1240.0,"lane":0.55},{"at":1660.0,"lane":-0.5}],"hazards":[{"at":610.0,"lane":0.0,"name":"ROLLING CHICANE","safe_speed":20.0},{"at":1470.0,"lane":0.0,"name":"FINISH S CURVE","safe_speed":18.0}]}
]
const MAX_LANE := 1.0
const MIN_STABILITY := 0.0

var course_index := 0
var distance := 0.0
var speed := 2.0
var lane := 0.0
var stability := 100.0
var elapsed := 0.0
var gate_index := 0
var hazard_index := 0
var gates_hit := 0
var gates_missed := 0
var hazards_avoided := 0
var finished := false
var crashed := false
var last_event := ""

func reset(course: int) -> void:
	course_index = posmod(course, COURSES.size())
	distance = 0.0
	speed = 2.0
	lane = 0.0
	stability = 100.0
	elapsed = 0.0
	gate_index = 0
	hazard_index = 0
	gates_hit = 0
	gates_missed = 0
	hazards_avoided = 0
	finished = false
	crashed = false
	last_event = "START · gravity run"

func step(controls: Dictionary, delta: float) -> void:
	if finished or crashed:
		return
	var dt := clampf(delta, 0.0, 0.05)
	var course: Dictionary = COURSES[course_index]
	var previous := distance
	elapsed += dt
	var steer := clampf(float(controls.get("steer", 0.0)), -1.0, 1.0)
	var brake := clampf(float(controls.get("brake", 0.0)), 0.0, 1.0)
	var grade := float(course.grade) * (0.82 + 0.18 * sin(distance * 0.004 + float(course_index)))
	var gravity_push := grade * 25.0 * float(course.grip)
	var drag := 0.018 * speed + float(course.roughness) * 1.3
	speed = clampf(speed + (gravity_push - drag - brake * 20.0) * dt, 0.0, 40.0)
	distance += speed * dt
	var steering_rate := 0.75 + speed * 0.038
	lane = clampf(lane + steer * steering_rate * dt, -MAX_LANE, MAX_LANE)
	var drift_load := maxf(0.0, absf(steer) * speed - 15.0) * float(course.roughness)
	if drift_load > 0.0:
		stability = maxf(MIN_STABILITY, stability - drift_load * 0.16 * dt)
	else:
		stability = minf(100.0, stability + (3.0 + brake * 8.0) * dt)
	last_event = ""
	var gates: Array = course.gates
	if gate_index < gates.size():
		var gate: Dictionary = gates[gate_index]
		if previous < float(gate.at) and distance >= float(gate.at):
			if absf(lane - float(gate.lane)) <= 0.28:
				gates_hit += 1
				last_event = "GATE CLEAN · %d/%d" % [gate_index + 1, gates.size()]
			else:
				gates_missed += 1
				stability = maxf(0.0, stability - 8.0)
				speed *= 0.82
				last_event = "GATE MISSED · LINE BONUS LOST"
			gate_index += 1
	var hazards: Array = course.hazards
	if hazard_index < hazards.size():
		var hazard: Dictionary = hazards[hazard_index]
		if previous < float(hazard.at) and distance >= float(hazard.at):
			if absf(lane - float(hazard.lane)) < 0.27:
				var excess := maxf(0.0, speed - float(hazard.safe_speed))
				stability = maxf(0.0, stability - 11.0 - excess * 0.65)
				speed *= 0.72
				last_event = "IMPACT · %s" % hazard.name
			else:
				hazards_avoided += 1
				last_event = "HAZARD AVOIDED · %s" % hazard.name
			hazard_index += 1
	if absf(lane) >= 0.995:
		stability = maxf(0.0, stability - 11.0 * dt)
	if stability <= 0.0:
		crashed = true
		last_event = "CRASH · stability lost"
	elif distance >= float(course.length):
		distance = float(course.length)
		finished = true
		last_event = "FINISH · derby complete"

func rating() -> String:
	if crashed:
		return "DNF"
	var gates_total := float(COURSES[course_index].gates.size())
	var clean_ratio := float(gates_hit) / maxf(gates_total, 1.0)
	var target := float(COURSES[course_index].length) / 23.0
	var pace := float(elapsed) / target
	if clean_ratio >= 0.75 and pace <= 1.2:
		return "GOLD"
	if clean_ratio >= 0.5 and pace <= 1.6:
		return "SILVER"
	return "BRONZE"

func score() -> int:
	if crashed:
		return maxi(0, int(distance * 0.3) + gates_hit * 250 - gates_missed * 80)
	return int(distance * 0.3) + gates_hit * 250 - gates_missed * 80
