extends RefCounted
class_name FormulaSprintSimulation

const TRACKS: Array[Dictionary] = [
    {"name":"Meridian GP", "width":88.0, "points":[Vector2(140,160),Vector2(420,105),Vector2(760,135),Vector2(890,260),Vector2(850,470),Vector2(670,585),Vector2(360,575),Vector2(125,455),Vector2(90,290)]},
    {"name":"Coastal Ring", "width":84.0, "points":[Vector2(120,130),Vector2(410,100),Vector2(750,135),Vector2(875,255),Vector2(790,355),Vector2(900,505),Vector2(650,590),Vector2(350,550),Vector2(115,420),Vector2(180,275)]},
    {"name":"Copper Canyon", "width":92.0, "points":[Vector2(145,145),Vector2(445,105),Vector2(795,175),Vector2(840,305),Vector2(710,385),Vector2(865,505),Vector2(605,590),Vector2(310,530),Vector2(105,380)]},
    {"name":"Pine Circuit", "width":82.0, "points":[Vector2(120,190),Vector2(330,105),Vector2(640,115),Vector2(855,210),Vector2(770,350),Vector2(885,490),Vector2(665,590),Vector2(390,540),Vector2(145,430),Vector2(210,300)]},
    {"name":"Crownstone 500", "width":96.0, "points":[Vector2(130,155),Vector2(405,95),Vector2(735,125),Vector2(890,265),Vector2(805,450),Vector2(590,585),Vector2(315,560),Vector2(115,425),Vector2(105,265)]}
]
const DRIVER_COLORS: Array[Color] = [Color("#64f3dc"),Color("#ffbd65"),Color("#ee7180"),Color("#9b9dff"),Color("#84db72"),Color("#ff8fd1"),Color("#68baff"),Color("#e7e8f0")]
const PIT_TARGETS: Array[float] = [0.18,0.43,0.68,0.93]
const RACE_LAPS := 10
const PIT_ZONE_FRACTION := 0.09

var circuit_index := 0
var track_length := 0.0
var racers: Array[Dictionary] = []
var finished := false
var elapsed := 0.0

func reset(circuit: int, kart_one: int = 0, kart_two: int = 1) -> void:
    circuit_index = posmod(circuit, TRACKS.size())
    track_length = _closed_path_length(TRACKS[circuit_index].points)
    racers.clear()
    finished = false
    elapsed = 0.0
    for i in range(8):
        var name := "Pulse" if i == 0 else "Comet" if i == 1 else "Rival %d" % (i-1)
        racers.append({
            "id":i,"name":name,"color":DRIVER_COLORS[i],"progress":-float(i)*23.0,
            "lane":-12.0 if i % 2 == 0 else 12.0,"speed":0.0,"max_speed":238.0-float((i*11)%33),
            "acceleration":118.0+float((i*17)%35),"fuel":100.0,"wear":0.0,
            "pit_queue":false,"pit_state":"track","pit_elapsed":0.0,"pit_step":0,
            "pit_good":0,"pit_missed":0,"pit_services":0,"pit_held":false,"service_left":0.0
        })
        if i == 0:
            racers[i].kart = kart_one
        elif i == 1:
            racers[i].kart = kart_two

func step(controls_one: Dictionary, controls_two: Dictionary, delta: float) -> void:
    if finished:
        return
    var dt := clampf(delta, 0.0, 0.05)
    elapsed += dt
    _step_player(racers[0], controls_one, dt)
    _step_player(racers[1], controls_two, dt)
    for i in range(2, racers.size()):
        _step_ai(racers[i], dt)
    finished = racers.any(func(racer: Dictionary) -> bool: return float(racer.progress) >= track_length * RACE_LAPS)

func _step_player(car: Dictionary, controls: Dictionary, dt: float) -> void:
    var pit_pressed := bool(controls.get("pit", false))
    var pit_edge := pit_pressed and not bool(car.pit_held)
    car.pit_held = pit_pressed
    if str(car.pit_state) == "lugs":
        _step_wheel_gun(car, pit_edge, dt)
        return
    if str(car.pit_state) == "service":
        _step_service(car, dt)
        return
    if pit_edge:
        car.pit_queue = true
    if bool(car.pit_queue) and _at_pit_lane(float(car.progress)):
        car.pit_queue = false
        car.pit_state = "lugs"
        car.pit_elapsed = 0.0
        car.pit_step = 0
        car.pit_good = 0
        car.pit_missed = 0
        car.speed = 0.0
        return
    var throttle := clampf(float(controls.get("throttle", 0.0)),0.0,1.0)
    var brake := clampf(float(controls.get("brake", 0.0)),0.0,1.0)
    var steer := clampf(float(controls.get("steer", 0.0)),-1.0,1.0)
    var turn := tangent_at(float(car.progress)).cross(tangent_at(float(car.progress)+85.0))
    var pressure := -turn * float(car.speed) * 0.28
    var width := float(TRACKS[circuit_index].width)
    car.lane = clampf(float(car.lane)+(steer*92.0+pressure)*dt,-width*0.82,width*0.82)
    if absf(steer)<0.08:
        car.lane=move_toward(float(car.lane),0.0,4.0*dt)
    var grip_factor := 1.0-float(car.wear)*0.0045
    var fuel_factor := 0.82+float(car.fuel)*0.0018
    var target := float(car.max_speed)*throttle*grip_factor*fuel_factor
    car.speed=move_toward(float(car.speed),target,float(car.acceleration)*dt)
    car.speed=maxf(0.0,float(car.speed)-brake*300.0*dt)
    car.speed=move_toward(float(car.speed),0.0,6.0*dt)
    if absf(float(car.lane))>width*0.47:
        car.speed=move_toward(float(car.speed),100.0,65.0*dt)
    var advance := maxf(0.0,float(car.speed))*dt
    car.progress=float(car.progress)+advance
    _consume_race_resources(car,advance)

func _step_ai(car: Dictionary, dt: float) -> void:
    if str(car.pit_state)=="service":
        _step_service(car,dt)
        return
    if float(car.fuel)<48.0 or float(car.wear)>48.0:
        car.pit_queue=true
    if bool(car.pit_queue) and _at_pit_lane(float(car.progress)):
        car.pit_queue=false
        car.pit_state="service"
        car.service_left=3.4
        car.speed=0.0
        return
    var turn := tangent_at(float(car.progress)).cross(tangent_at(float(car.progress)+85.0))
    var desired_lane := -turn*float(car.speed)*0.22
    car.lane=move_toward(float(car.lane),clampf(desired_lane,-25.0,25.0),75.0*dt)
    var width := float(TRACKS[circuit_index].width)
    var wear_factor := 1.0-float(car.wear)*0.0045
    var fuel_factor := 0.82+float(car.fuel)*0.0018
    var corner_factor := 0.92 if absf(turn)>0.44 else 1.0
    var target := float(car.max_speed)*0.91*wear_factor*fuel_factor*corner_factor
    car.speed=move_toward(float(car.speed),target,float(car.acceleration)*0.78*dt)
    if absf(float(car.lane))>width*0.48:
        car.speed=move_toward(float(car.speed),105.0,55.0*dt)
    var advance := maxf(0.0,float(car.speed))*dt
    car.progress=float(car.progress)+advance
    _consume_race_resources(car,advance)

func _consume_race_resources(car: Dictionary, advance: float) -> void:
    var lap_fraction := advance/maxf(track_length,0.001)
    car.fuel=maxf(0.0,float(car.fuel)-lap_fraction*9.0)
    car.wear=minf(100.0,float(car.wear)+lap_fraction*9.0)

func _step_wheel_gun(car: Dictionary, pressed: bool, dt: float) -> void:
    car.pit_elapsed=float(car.pit_elapsed)+dt
    if pressed:
        var phase := pit_gauge(car)
        var target := PIT_TARGETS[int(car.pit_step)]
        var difference := minf(absf(phase-target),1.0-absf(phase-target))
        if difference<=0.075:
            car.pit_good=int(car.pit_good)+1
        else:
            car.pit_missed=int(car.pit_missed)+1
        car.pit_step=int(car.pit_step)+1
        if int(car.pit_step)>=PIT_TARGETS.size():
            car.pit_state="service"
            car.service_left=1.6+float(car.pit_missed)*0.7+float(PIT_TARGETS.size()-int(car.pit_good))*0.18

func pit_gauge(car: Dictionary) -> float:
    return fposmod(float(car.pit_elapsed)*0.72,1.0)

func _step_service(car: Dictionary, dt: float) -> void:
    car.service_left=maxf(0.0,float(car.service_left)-dt)
    if float(car.service_left)<=0.0:
        car.fuel=100.0
        car.wear=0.0
        car.pit_services=int(car.pit_services)+1
        car.pit_state="track"
        car.speed=0.0

func _at_pit_lane(progress: float) -> bool:
    if progress < 0.0:
        return false
    var fraction := fposmod(progress,maxf(track_length,0.001))/maxf(track_length,0.001)
    return fraction <= PIT_ZONE_FRACTION

func standings() -> Array[Dictionary]:
    var order := racers.duplicate()
    order.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return float(a.progress)>float(b.progress))
    return order

func position_on_track(progress: float, lane: float = 0.0) -> Vector2:
    var points: Array=TRACKS[circuit_index].points
    var remaining := fposmod(progress,track_length)
    for i in range(points.size()):
        var a: Vector2=points[i]
        var b: Vector2=points[(i+1)%points.size()]
        var segment := a.distance_to(b)
        if remaining<=segment:
            var tangent := (b-a).normalized()
            return a.lerp(b,remaining/maxf(segment,0.001))+tangent.orthogonal()*lane
        remaining-=segment
    return points[0]

func tangent_at(progress: float) -> Vector2:
    var points: Array=TRACKS[circuit_index].points
    var remaining := fposmod(progress,track_length)
    for i in range(points.size()):
        var a: Vector2=points[i]
        var b: Vector2=points[(i+1)%points.size()]
        var segment := a.distance_to(b)
        if remaining<=segment:
            return (b-a).normalized()
        remaining-=segment
    return (points[1]-points[0]).normalized()

static func _closed_path_length(points: Array) -> float:
    var total := 0.0
    for i in range(points.size()):
        total+=(points[(i+1)%points.size()] as Vector2).distance_to(points[i])
    return total
