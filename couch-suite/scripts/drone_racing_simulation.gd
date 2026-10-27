extends RefCounted

const LAPS:=3
const TRACKS: Array[Dictionary]=[
	{"name":"Skyline Circuit","wind":0.12,"gates":[Vector2(-310,-160),Vector2(0,-225),Vector2(310,-140),Vector2(280,160),Vector2(-60,220),Vector2(-330,120)],"hazards":[Vector2(110,-5),Vector2(-205,20)]},
	{"name":"Canyon Relay","wind":0.28,"gates":[Vector2(-330,-190),Vector2(-70,-225),Vector2(270,-190),Vector2(330,70),Vector2(70,220),Vector2(-270,180)],"hazards":[Vector2(95,-15),Vector2(-150,10)]},
	{"name":"Neon Harbor","wind":0.2,"gates":[Vector2(-300,-200),Vector2(20,-190),Vector2(320,-120),Vector2(260,150),Vector2(-20,210),Vector2(-330,100)],"hazards":[Vector2(140,30),Vector2(-175,-20)]},
	{"name":"Alpine Airway","wind":0.42,"gates":[Vector2(-340,-160),Vector2(-150,-230),Vector2(200,-190),Vector2(340,60),Vector2(140,210),Vector2(-220,190)],"hazards":[Vector2(20,-20),Vector2(-175,35)]},
	{"name":"World Final","wind":0.34,"gates":[Vector2(-320,-205),Vector2(-20,-230),Vector2(300,-165),Vector2(330,110),Vector2(20,220),Vector2(-330,110)],"hazards":[Vector2(135,-10),Vector2(-175,10)]}
]
const COLORS: Array[Color]=[Color("#67f1df"),Color("#ffc46e"),Color("#ff6878"),Color("#a3a0ff"),Color("#8adf7c"),Color("#ec8ce3")]
const NAMES:=["HB Vector","Blue Comet","Redline FPV","Night Kite","Pine Arrow","Coastal Lift"]
var track_index:=0
var drones:Array[Dictionary]=[]
var elapsed:=0.0
var finished:=false
var winner:=-1
var crashes:=0

func reset(track:int)->void:
	track_index=posmod(track,TRACKS.size())
	elapsed=0.0
	finished=false
	winner=-1
	crashes=0
	drones.clear()
	for i in range(6):
		drones.append({"id":i,"name":NAMES[i],"color":COLORS[i],"pos":Vector2(-400.0+float(i)*35.0,245.0-float(i%2)*35.0),"velocity":Vector2.ZERO,"heading":-0.5,"gate":0,"lap":0,"score":0,"battery":100.0,"damage":0.0,"finished":false})

func step(one:Dictionary,two:Dictionary,delta:float)->void:
	if finished:return
	var dt:=clampf(delta,0.0,0.05)
	elapsed+=dt
	var track:Dictionary=TRACKS[track_index]
	for i in range(drones.size()):
		var drone:Dictionary=drones[i]
		if bool(drone.finished):continue
		var controls:Dictionary=one if i==0 else two if i==1 else _ai(drone,track)
		_fly(drone,controls,dt,track)
		_cross_gate(drone,track)
	for i in range(2):
		if int(drones[i].lap)>=LAPS:
			drones[i].finished=true
			if winner<0:winner=i
	if winner>=0:finished=true

func _fly(drone:Dictionary,controls:Dictionary,dt:float,track:Dictionary)->void:
	var steer:=clampf(float(controls.get("steer",0.0)),-1.0,1.0)
	var throttle:=clampf(float(controls.get("throttle",0.0)),0.0,1.0)
	var brake:=clampf(float(controls.get("brake",0.0)),0.0,1.0)
	var boost:=bool(controls.get("boost",false)) and float(drone.battery)>1.0
	var speed:=Vector2(drone.velocity).length()
	drone.heading=float(drone.heading)+steer*(0.9+speed*0.012)*dt
	var forward:=Vector2(cos(float(drone.heading)),sin(float(drone.heading)))
	var course_wind:=Vector2(cos(float(drone.pos.y)*0.002),sin(float(drone.pos.x)*0.002))*float(track.wind)
	var accel:=92.0*throttle+ (65.0 if boost else 0.0)-speed*0.16-brake*105.0
	var velocity:Vector2=drone.velocity
	velocity+=(forward*accel+course_wind*18.0)*dt
	velocity=velocity.move_toward(Vector2.ZERO,4.0*dt)
	if velocity.length()>155.0:velocity=velocity.normalized()*155.0
	drone.velocity=velocity
	drone.pos=Vector2(drone.pos)+velocity*dt
	drone.battery=maxf(0.0,float(drone.battery)-(18.0*dt if boost else throttle*0.45*dt))
	if not boost:drone.battery=minf(100.0,float(drone.battery)+3.2*dt)
	var pos:Vector2=drone.pos
	if absf(pos.x)>450.0 or absf(pos.y)>300.0:
		drone.pos=Vector2(clampf(pos.x,-450.0,450.0),clampf(pos.y,-300.0,300.0))
		drone.velocity=Vector2(velocity)*-0.4
		drone.damage=minf(100.0,float(drone.damage)+4.0)
	for hazard in track.hazards:
		if Vector2(drone.pos).distance_to(Vector2(hazard))<24.0:
			drone.velocity=Vector2(drone.velocity)*0.6
			drone.damage=minf(100.0,float(drone.damage)+0.8)
			drone.pos=Vector2(drone.pos)+Vector2(drone.pos-hazard).normalized()*3.0
			crashes+=1

func _cross_gate(drone:Dictionary,track:Dictionary)->void:
	var gates:Array=track.gates
	var index:int=int(drone.gate)
	var target:Vector2=gates[index]
	if Vector2(drone.pos).distance_to(target)<42.0:
		drone.score=int(drone.score)+500
		index+=1
		if index>=gates.size():
			index=0
			drone.lap=int(drone.lap)+1
		drone.gate=index

func _ai(drone:Dictionary,track:Dictionary)->Dictionary:
	var target:Vector2=track.gates[int(drone.gate)]
	var delta:Vector2=target-Vector2(drone.pos)
	var diff:=wrapf(delta.angle()-float(drone.heading),-PI,PI)
	return {"steer":clampf(diff*1.7,-1.0,1.0),"throttle":0.86,"brake":0.0,"boost":delta.length()>180.0 and float(drone.battery)>55.0}

func standings()->Array:
	var order:=drones.duplicate()
	order.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if int(a.lap)!=int(b.lap):return int(a.lap)>int(b.lap)
		if int(a.gate)!=int(b.gate):return int(a.gate)>int(b.gate)
		return int(a.score)>int(b.score))
	return order

