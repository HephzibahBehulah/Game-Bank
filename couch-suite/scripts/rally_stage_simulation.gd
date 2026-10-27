extends RefCounted
class_name RallyStageSimulation

const STAGES: Array[Dictionary] = [
    {"name":"Gravel Ridge", "width":100.0, "target":15.5, "points":[Vector2(80,585),Vector2(195,555),Vector2(285,430),Vector2(420,390),Vector2(510,445),Vector2(650,330),Vector2(815,300),Vector2(945,180),Vector2(1190,205)], "notes":[{"at":0.16,"text":"LEFT 3 TIGHTENS"},{"at":0.38,"text":"RIGHT 2 OVER CREST"},{"at":0.62,"text":"LEFT 4, LATE APEX"},{"at":0.82,"text":"RIGHT 3 OPENS"}]},
    {"name":"Pine Needle Run", "width":88.0, "target":17.0, "points":[Vector2(80,160),Vector2(210,200),Vector2(330,310),Vector2(430,240),Vector2(565,360),Vector2(720,435),Vector2(820,330),Vector2(970,465),Vector2(1190,560)], "notes":[{"at":0.14,"text":"RIGHT 4 INTO LEFT 3"},{"at":0.35,"text":"LEFT 2, KEEP TIGHT"},{"at":0.58,"text":"RIGHT 3 OVER DIP"},{"at":0.79,"text":"LEFT 4 OPENS"}]},
    {"name":"Alpine Switchback", "width":94.0, "target":18.0, "points":[Vector2(90,630),Vector2(210,530),Vector2(155,410),Vector2(350,330),Vector2(290,205),Vector2(520,155),Vector2(650,275),Vector2(880,215),Vector2(1030,105),Vector2(1190,120)], "notes":[{"at":0.12,"text":"LEFT 2 HAIRPIN"},{"at":0.34,"text":"RIGHT 3 TIGHTENS"},{"at":0.57,"text":"LEFT 2, DOWNHILL"},{"at":0.78,"text":"RIGHT 4 INTO FINISH"}]},
    {"name":"Redstone Quarry", "width":108.0, "target":16.0, "points":[Vector2(80,475),Vector2(205,390),Vector2(360,445),Vector2(500,315),Vector2(650,390),Vector2(790,275),Vector2(920,335),Vector2(1055,210),Vector2(1190,265)], "notes":[{"at":0.15,"text":"RIGHT 3, LOOSE GRAVEL"},{"at":0.39,"text":"LEFT 4 OVER ROCKS"},{"at":0.63,"text":"RIGHT 2 TIGHTENS"},{"at":0.84,"text":"LEFT 4 TO FINISH"}]},
    {"name":"Frostline Pass", "width":90.0, "target":18.5, "points":[Vector2(80,135),Vector2(220,115),Vector2(350,225),Vector2(290,350),Vector2(475,420),Vector2(620,335),Vector2(750,475),Vector2(890,420),Vector2(980,535),Vector2(1190,565)], "notes":[{"at":0.13,"text":"RIGHT 2 ON ICE"},{"at":0.36,"text":"LEFT 3, SLIPPERY EXIT"},{"at":0.61,"text":"RIGHT 3 TIGHTENS"},{"at":0.83,"text":"LEFT 4, EASY TO FINISH"}]},
    {"name":"Cedar Valley", "width":104.0, "target":17.5, "points":[Vector2(80,605),Vector2(205,500),Vector2(345,515),Vector2(435,390),Vector2(580,335),Vector2(690,425),Vector2(825,290),Vector2(930,240),Vector2(1080,280),Vector2(1190,155)], "notes":[{"at":0.12,"text":"LEFT 3 THROUGH TREES"},{"at":0.34,"text":"RIGHT 4 OPENS"},{"at":0.56,"text":"LEFT 2, SHORT CREST"},{"at":0.81,"text":"RIGHT 3 TO FINISH"}]},
    {"name":"Dust Devil Sprint", "width":82.0, "target":16.5, "points":[Vector2(80,320),Vector2(205,245),Vector2(325,300),Vector2(440,180),Vector2(555,240),Vector2(675,365),Vector2(790,295),Vector2(910,410),Vector2(1050,350),Vector2(1190,455)], "notes":[{"at":0.13,"text":"RIGHT 3, BLIND ENTRY"},{"at":0.35,"text":"LEFT 4 OVER CREST"},{"at":0.58,"text":"RIGHT 2 TIGHTENS"},{"at":0.82,"text":"LEFT 3, SAND OUTSIDE"}]},
    {"name":"Blackwater Forest", "width":96.0, "target":18.0, "points":[Vector2(80,145),Vector2(220,205),Vector2(320,155),Vector2(435,275),Vector2(385,405),Vector2(560,500),Vector2(700,425),Vector2(805,545),Vector2(965,475),Vector2(1190,580)], "notes":[{"at":0.12,"text":"LEFT 4 UNDER CANOPY"},{"at":0.35,"text":"RIGHT 2, NARROW"},{"at":0.59,"text":"LEFT 3 OVER BRIDGE"},{"at":0.83,"text":"RIGHT 4 OPENS"}]},
    {"name":"Sunbreak Coast", "width":112.0, "target":19.0, "points":[Vector2(80,565),Vector2(215,525),Vector2(335,415),Vector2(465,440),Vector2(590,320),Vector2(730,275),Vector2(830,350),Vector2(960,215),Vector2(1070,185),Vector2(1190,95)], "notes":[{"at":0.15,"text":"LEFT 3, CLIFF EDGE"},{"at":0.37,"text":"RIGHT 4 OPENS"},{"at":0.61,"text":"LEFT 2 TIGHTENS"},{"at":0.82,"text":"RIGHT 3 TO COAST"}]},
    {"name":"Summit Finale", "width":86.0, "target":20.0, "points":[Vector2(80,635),Vector2(180,520),Vector2(310,575),Vector2(400,430),Vector2(355,295),Vector2(520,205),Vector2(665,270),Vector2(740,145),Vector2(900,115),Vector2(1010,220),Vector2(1190,125)], "notes":[{"at":0.10,"text":"RIGHT 2 HAIRPIN"},{"at":0.31,"text":"LEFT 3, LATE BRAKE"},{"at":0.53,"text":"RIGHT 2 OVER SUMMIT"},{"at":0.74,"text":"LEFT 4 OPENS"},{"at":0.88,"text":"RIGHT 3, FULL COMMIT"}]}
]

var stage_index := 0
var route_length := 0.0
var distance := 0.0
var elapsed := 0.0
var speed := 0.0
var lane := 0.0
var finished := false
var offroad_time := 0.0

func reset(selected_stage: int) -> void:
    stage_index = clampi(selected_stage, 0, STAGES.size() - 1)
    route_length = _path_length(STAGES[stage_index].points)
    distance = 0.0
    elapsed = 0.0
    speed = 0.0
    lane = 0.0
    finished = false
    offroad_time = 0.0

func step(controls: Dictionary, delta: float) -> void:
    if finished:
        return
    var dt := clampf(delta, 0.0, 0.05)
    elapsed += dt
    var throttle := clampf(float(controls.get("throttle", 0.0)), 0.0, 1.0)
    var brake := clampf(float(controls.get("brake", 0.0)), 0.0, 1.0)
    var steer := clampf(float(controls.get("steer", 0.0)), -1.0, 1.0)
    var handbrake := bool(controls.get("handbrake", false))
    var width := float(STAGES[stage_index].width)
    var turn := tangent_at(distance).cross(tangent_at(distance + 90.0))
    var corner_drift := -turn * speed * 0.30
    lane = clampf(lane + (steer * (125.0 if handbrake else 82.0) + corner_drift) * dt, -width * 0.9, width * 0.9)
    if absf(steer) < 0.08:
        lane = move_toward(lane, 0.0, 7.0 * dt)
    var target_speed := 232.0 * throttle
    speed = move_toward(speed, target_speed, 118.0 * dt)
    speed = maxf(0.0, speed - brake * (390.0 if handbrake else 300.0) * dt)
    speed = move_toward(speed, 0.0, 7.5 * dt)
    if absf(lane) > width * 0.48:
        offroad_time += dt
        speed = move_toward(speed, 92.0, (65.0 + 35.0 * absf(steer)) * dt)
    distance += speed * dt
    finished = distance >= route_length

func position_on_route(route_distance: float, lateral_offset: float = 0.0) -> Vector2:
    var points: Array = STAGES[stage_index].points
    var remaining := clampf(route_distance, 0.0, route_length)
    for i in range(points.size() - 1):
        var a: Vector2 = points[i]
        var b: Vector2 = points[i + 1]
        var segment := a.distance_to(b)
        if remaining <= segment:
            var tangent := (b - a).normalized()
            return a.lerp(b, remaining / maxf(segment, 0.001)) + tangent.orthogonal() * lateral_offset
        remaining -= segment
    return points[points.size() - 1]

func tangent_at(route_distance: float) -> Vector2:
    var points: Array = STAGES[stage_index].points
    var remaining := clampf(route_distance, 0.0, route_length)
    for i in range(points.size() - 1):
        var a: Vector2 = points[i]
        var b: Vector2 = points[i + 1]
        var segment := a.distance_to(b)
        if remaining <= segment:
            return (b - a).normalized()
        remaining -= segment
    return (points[points.size() - 1] - points[points.size() - 2]).normalized()

func current_note_index() -> int:
    var notes: Array = STAGES[stage_index].notes
    var progress := distance / maxf(route_length, 0.001)
    for i in range(notes.size()):
        if progress < float(notes[i].at):
            return i
    return notes.size() - 1

static func _path_length(points: Array) -> float:
    var total := 0.0
    for i in range(points.size() - 1):
        total += (points[i] as Vector2).distance_to(points[i + 1])
    return total
