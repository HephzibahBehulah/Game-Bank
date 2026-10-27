extends RefCounted

const LAPS := 6
const CAR_COUNT := 6
const TRACKS: Array[Dictionary] = [
	{"name":"Meridian Superspeedway","length":1600.0,"bank":0.82,"grip":0.92,"draft":1.0},
	{"name":"Copper Bowl","length":1320.0,"bank":0.74,"grip":0.83,"draft":0.88},
	{"name":"Pine County Oval","length":1180.0,"bank":0.58,"grip":0.9,"draft":0.75},
	{"name":"Coastal 400","length":1740.0,"bank":0.9,"grip":0.87,"draft":1.12},
	{"name":"Crownstone Night 500","length":1880.0,"bank":0.94,"grip":0.95,"draft":1.18}
]
const COLORS: Array[Color] = [Color("#68f1d8"),Color("#ffc66e"),Color("#ff7180"),Color("#9d9cff"),Color("#8de17a"),Color("#ed8af1")]
const NAMES := ["HB Motors","Blue Comet","Redline Works","Night Shift","Pine Racing","Coastal Arrow"]
var track_index := 0
var cars: Array[Dictionary] = []
var elapsed := 0.0
var finished := false
var winner := -1
var incidents := 0

func reset(track: int) -> void:
	track_index = posmod(track, TRACKS.size())
	elapsed = 0.0
	finished = false
	winner = -1
	incidents = 0
	cars.clear()
	for i in range(CAR_COUNT):
		cars.append({"id":i,"name":NAMES[i],"color":COLORS[i],"progress":-float(i)*34.0,"speed":0.0,"lane":-0.35 if i%2==0 else 0.35,"temp":72.0,"damage":0.0,"best_lap":0.0,"lap_started":0.0,"last_lap":0.0,"finished":false,"finish_time":0.0})

func step(one: Dictionary, two: Dictionary, dt: float) -> void:
	if finished: return
	dt = clampf(dt,0.0,0.05)
	elapsed += dt
	var t: Dictionary = TRACKS[track_index]
	for i in range(CAR_COUNT):
		var car: Dictionary = cars[i]
		if bool(car.finished): continue
		var control: Dictionary = one if i==0 else two if i==1 else _ai_controls(car,i)
		_step_car(car,control,dt,t,i)
	_check_incidents(dt,t)
	for i in range(2):
		if float(cars[i].progress) >= float(t.length)*LAPS and not bool(cars[i].finished):
			cars[i].finished=true
			cars[i].finish_time=elapsed
			if winner<0: winner=i
		if bool(cars[i].finished) and winner<0: winner=i
	if winner>=0: finished=true

func _step_car(car: Dictionary, control: Dictionary, dt: float, track: Dictionary, index: int) -> void:
	var throttle:=clampf(float(control.get("throttle",0.0)),0.0,1.0)
	var brake:=clampf(float(control.get("brake",0.0)),0.0,1.0)
	var steer:=clampf(float(control.get("steer",0.0)),-1.0,1.0)
	var speed:=float(car.speed)
	var turn:=sin(float(car.progress)/float(track.length)*TAU)
	var grip:=float(track.grip)*(1.0-float(car.damage)*0.006)
	var corner_limit:=48.0+float(track.bank)*15.0+grip*8.0
	var over_speed:=maxf(0.0,speed-corner_limit)
	var lane:=float(car.lane)
	lane=clampf(lane+steer*(0.62+speed*0.006)*dt,-1.0,1.0)
	var draft_bonus:=0.0
	for other in cars:
		if int(other.id)!=index and float(other.progress)>float(car.progress) and float(other.progress)-float(car.progress)<46.0 and absf(float(other.lane)-lane)<0.42:
			draft_bonus=float(track.draft)*8.0
			break
	var accel:=throttle*(17.0+draft_bonus)-1.2-brake*34.0-over_speed*0.55-float(car.damage)*0.08
	speed=clampf(speed+accel*dt,0.0,82.0)
	var slip:=absf(steer)*over_speed*(1.0-float(track.bank))*0.065
	car.temp=clampf(float(car.temp)+(2.4 if speed>corner_limit*0.8 and absf(turn)>0.58 else -0.7)*dt+slip*0.1,55.0,145.0)
	if float(car.temp)>124.0:
		speed=maxf(0.0,speed-(float(car.temp)-124.0)*0.018*dt)
	car.speed=speed
	car.lane=lane
	var old_laps:=int(floor(maxf(0.0,float(car.progress))/float(track.length)))
	car.progress=float(car.progress)+speed*dt
	var new_laps:=int(floor(maxf(0.0,float(car.progress))/float(track.length)))
	if new_laps>old_laps:
		car.last_lap=elapsed-float(car.lap_started)
		car.best_lap=car.last_lap if float(car.best_lap)==0.0 else minf(float(car.best_lap),float(car.last_lap))
		car.lap_started=elapsed

func _ai_controls(car: Dictionary, index: int) -> Dictionary:
	var progress:=float(car.progress)
	var phase:=sin(progress*0.003+float(index))
	var lane_target:=0.28 if index%2==0 else -0.28
	var steer:=clampf((lane_target-float(car.lane))*1.6-phase*0.06,-0.45,0.45)
	var throttle:=0.82+0.12*sin(progress*0.001+float(index)*1.7)
	var brake:=0.18 if absf(phase)>0.91 else 0.0
	return {"throttle":throttle,"brake":brake,"steer":steer}

func _check_incidents(dt: float, track: Dictionary) -> void:
	for a in range(CAR_COUNT):
		for b in range(a+1,CAR_COUNT):
			var one: Dictionary=cars[a]
			var two: Dictionary=cars[b]
			var gap:=absf(float(one.progress)-float(two.progress))
			if gap<13.0 and absf(float(one.lane)-float(two.lane))<0.16 and (a==0 or b==0):
				if float(one.damage)<60.0 and float(two.damage)<60.0:
					one.damage=minf(100.0,float(one.damage)+12.0*dt)
					two.damage=minf(100.0,float(two.damage)+12.0*dt)
					one.speed=maxf(0.0,float(one.speed)-18.0*dt)
					two.speed=maxf(0.0,float(two.speed)-18.0*dt)
					incidents+=1

func standings() -> Array:
	var ranking:=cars.duplicate()
	ranking.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		if bool(a.finished)!=bool(b.finished): return bool(a.finished)
		return float(a.progress)>float(b.progress))
	return ranking

func completed_laps(car_id: int) -> int:
	return mini(LAPS,int(floor(maxf(0.0,float(cars[car_id].progress))/float(TRACKS[track_index].length))))

