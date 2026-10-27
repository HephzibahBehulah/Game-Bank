extends RefCounted
class_name KartSimulation

const KARTS: Array[Dictionary] = [
    {"name":"Pulse", "max":310.0, "accel":390.0, "grip":1.00, "color":Color("#57f2df")},
    {"name":"Comet", "max":322.0, "accel":360.0, "grip":0.93, "color":Color("#ff77c8")},
    {"name":"Vector", "max":300.0, "accel":420.0, "grip":1.08, "color":Color("#ffd064")},
    {"name":"Warden", "max":292.0, "accel":440.0, "grip":1.12, "color":Color("#8c9dff")},
    {"name":"Nova", "max":316.0, "accel":380.0, "grip":0.98, "color":Color("#a5ff80")},
    {"name":"Rift", "max":330.0, "accel":340.0, "grip":0.90, "color":Color("#ff785a")},
    {"name":"Atlas", "max":296.0, "accel":430.0, "grip":1.10, "color":Color("#72c7ff")},
    {"name":"Mistral", "max":305.0, "accel":405.0, "grip":1.04, "color":Color("#e0a2ff")}
]
const TRACKS: Array[Dictionary] = [
    {"name":"Neon Harbor", "width":92.0, "points":[Vector2(175,135),Vector2(430,100),Vector2(710,150),Vector2(855,320),Vector2(760,535),Vector2(495,595),Vector2(210,520),Vector2(115,330)]},
    {"name":"Cinder Loop", "width":84.0, "points":[Vector2(180,155),Vector2(440,105),Vector2(690,165),Vector2(820,285),Vector2(720,375),Vector2(850,510),Vector2(590,590),Vector2(340,545),Vector2(135,425),Vector2(250,315)]},
    {"name":"Cloudline Run", "width":88.0, "points":[Vector2(150,210),Vector2(270,115),Vector2(525,95),Vector2(780,175),Vector2(865,310),Vector2(740,390),Vector2(835,515),Vector2(560,595),Vector2(310,560),Vector2(125,430)]},
    {"name":"Tidal Switchback", "width":82.0, "points":[Vector2(155,155),Vector2(445,105),Vector2(825,175),Vector2(700,285),Vector2(835,440),Vector2(585,580),Vector2(205,540),Vector2(350,410),Vector2(135,320)]},
    {"name":"Glass Canyon", "width":90.0, "points":[Vector2(155,180),Vector2(400,100),Vector2(690,140),Vector2(845,285),Vector2(720,365),Vector2(835,515),Vector2(540,595),Vector2(275,520),Vector2(120,370)]},
    {"name":"Aurora Ring", "width":96.0, "points":[Vector2(175,145),Vector2(465,100),Vector2(770,165),Vector2(850,350),Vector2(720,535),Vector2(460,595),Vector2(190,520),Vector2(105,325)]},
    {"name":"Foundry Run", "width":80.0, "points":[Vector2(135,165),Vector2(400,100),Vector2(705,135),Vector2(855,240),Vector2(675,330),Vector2(840,445),Vector2(700,565),Vector2(420,585),Vector2(155,500),Vector2(300,360)]},
    {"name":"Skybridge GP", "width":88.0, "points":[Vector2(135,235),Vector2(300,110),Vector2(590,100),Vector2(835,200),Vector2(790,350),Vector2(860,485),Vector2(600,590),Vector2(335,555),Vector2(120,425),Vector2(265,335)]}
]
const POINTS_BY_PLACE: Array[int] = [15,12,10,8,6,4,2,1]
const DIFFICULTY_MULTIPLIERS: Array[float] = [0.88,1.0,1.10]
var track_index := 0
var difficulty := 1
var track_length := 0.0
var racers: Array[Dictionary] = []
var finished := false
var elapsed := 0.0
var drift_time: Array[float] = [0.0,0.0]

func reset(track: int, tier: int, kart_one: int = 0, kart_two: int = 1) -> void:
    track_index = posmod(track, TRACKS.size())
    difficulty = clampi(tier, 0, 2)
    track_length = _path_length(TRACKS[track_index].points)
    finished = false
    elapsed = 0.0
    drift_time = [0.0,0.0]
    racers.clear()
    for i in range(8):
        var kart_index := kart_one if i == 0 else kart_two if i == 1 else i
        var kart: Dictionary = KARTS[kart_index]
        racers.append({
            "id":i,"name":kart.name if i < 2 else "Rival %02d" % (i-1),
            "kart":kart_index,"color":kart.color,"progress":-float(i)*24.0,
            "lane":-10.0 if i % 2 == 0 else 10.0,"speed":0.0,
            "max":float(kart.max),"accel":float(kart.accel),"grip":float(kart.grip),
            "items":1 if i < 2 else 0,"boost":0.0,"finished":false
        })

func step(controls_one: Dictionary, controls_two: Dictionary, dt: float) -> void:
    if finished:
        return
    var tick := clampf(dt, 0.0, 0.05)
    elapsed += tick
    _drive_player(racers[0], controls_one, 0, tick)
    _drive_player(racers[1], controls_two, 1, tick)
    for i in range(2, racers.size()):
        _drive_ai(racers[i], tick)
    for racer in racers:
        if float(racer.progress) >= track_length * 3.0:
            racer.finished = true
    finished = racers.any(func(r: Dictionary) -> bool: return r.finished)

func _drive_player(car: Dictionary, input: Dictionary, player: int, dt: float) -> void:
    var throttle := clampf(float(input.get("throttle", 0.0)), 0.0, 1.0)
    var brake := clampf(float(input.get("brake", 0.0)), 0.0, 1.0)
    var steer := clampf(float(input.get("steer", 0.0)), -1.0, 1.0)
    var drifting := bool(input.get("drift", false))
    car.speed = move_toward(car.speed, float(car.max) * (1.0 + float(car.boost)), (float(car.accel) * throttle - 520.0 * brake - 32.0) * dt)
    if drifting:
        drift_time[player] += dt
        car.lane = clampf(float(car.lane) + steer * 130.0 * dt / maxf(.6, float(car.grip)), -145.0, 145.0)
        car.speed *= 1.0 - .06 * dt
    else:
        if drift_time[player] >= .65:
            car.boost = .16
            car.items = mini(2, int(car.items) + 1)
        drift_time[player] = 0.0
        car.lane = move_toward(float(car.lane), steer * 38.0, float(car.grip) * 170.0 * dt)
    if bool(input.get("item", false)) and int(car.items) > 0 and float(car.boost) <= 0.0:
        car.items = int(car.items) - 1
        car.boost = .24
    if absf(float(car.lane)) > float(TRACKS[track_index].width) * .53:
        car.speed *= 1.0 - 1.2 * dt
    car.boost = move_toward(float(car.boost), 0.0, .42 * dt)
    car.progress = float(car.progress) + maxf(0.0, float(car.speed)) * dt

func _drive_ai(car: Dictionary, dt: float) -> void:
    var human_lead := maxf(float(racers[0].progress), float(racers[1].progress))
    var gap := human_lead - float(car.progress)
    var band_strength: float = [0.08,0.15,0.23][difficulty]
    var catchup := clampf(1.0 + gap / 1800.0 * band_strength, .86, 1.18)
    var target := float(car.max) * DIFFICULTY_MULTIPLIERS[difficulty] * catchup
    var curve_index := int(floor(fposmod(float(car.progress), track_length) / track_length * TRACKS[track_index].points.size()))
    var turn_slow := 1.0 if curve_index % 2 == 0 else .84
    target *= turn_slow
    car.speed = move_toward(float(car.speed), target, (float(car.accel) * .78 + 20.0) * dt)
    car.progress = float(car.progress) + maxf(0.0, float(car.speed)) * dt
    car.lane = move_toward(float(car.lane), 0.0, 30.0 * dt)

func place_on_track(progress: float, lane: float = 0.0) -> Vector2:
    var pts: Array = TRACKS[track_index].points
    var d := fposmod(progress, track_length)
    for i in range(pts.size()):
        var a: Vector2 = pts[i]
        var b: Vector2 = pts[(i+1)%pts.size()]
        var segment := a.distance_to(b)
        if d <= segment:
            var tangent := (b-a).normalized()
            return a.lerp(b, d/maxf(segment,.001)) + tangent.orthogonal() * lane
        d -= segment
    return pts[0]

func standings() -> Array[Dictionary]:
    var order := racers.duplicate()
    order.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return float(a.progress) > float(b.progress))
    return order

static func points_for_order(order: Array[Dictionary]) -> Array[int]:
    var result: Array[int] = []
    result.resize(KARTS.size())
    result.fill(0)
    for place in range(order.size()):
        var racer_id := int(order[place].get("id", -1))
        if racer_id >= 0 and racer_id < result.size():
            result[racer_id] = POINTS_BY_PLACE[place] if place < POINTS_BY_PLACE.size() else 0
    return result

static func _path_length(points: Array) -> float:
    var total := 0.0
    for i in range(points.size()):
        total += (points[(i+1)%points.size()] as Vector2).distance_to(points[i])
    return total
