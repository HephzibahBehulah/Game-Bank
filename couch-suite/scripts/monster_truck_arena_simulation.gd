extends RefCounted

const ROUND_SECONDS := 90.0
const ARENAS: Array[Dictionary] = [
	{"name":"Iron Yard","traction":0.88,"objects":[["CRUSH CAR",Vector2(-260,-100),36,220,18],["STEEL DRUMS",Vector2(220,-180),25,120,12],["BUS HULK",Vector2(40,80),52,340,26],["RAMP",Vector2(-120,170),48,0,0],["CONCRETE WALL",Vector2(290,100),45,250,25],["SCRAP STACK",Vector2(-350,70),42,210,20]]},
	{"name":"Desert Bowl","traction":0.75,"objects":[["SAND BUGGY",Vector2(-280,-80),34,180,16],["BARREL LINE",Vector2(200,-190),32,160,18],["SCHOOL BUS",Vector2(30,90),50,330,28],["DUNE RAMP",Vector2(-110,175),50,0,0],["TIRE WALL",Vector2(300,105),42,220,24],["CARGO CRATE",Vector2(-350,65),38,175,18]]},
	{"name":"Harbor Breaker","traction":0.69,"objects":[["CONTAINER CART",Vector2(-260,-100),38,220,22],["FORKLIFT",Vector2(210,-180),32,190,18],["FERRY VAN",Vector2(35,85),48,300,27],["DOCK RAMP",Vector2(-120,175),48,0,0],["MOORING PILE",Vector2(295,95),40,210,25],["NET CRATE",Vector2(-350,65),36,160,17]]},
	{"name":"Frostbite Arena","traction":0.57,"objects":[["ICE RESCUE SLED",Vector2(-260,-105),36,220,20],["SNOW PLOW",Vector2(210,-180),42,280,30],["CABIN HULK",Vector2(35,80),48,310,26],["ICE KICKER",Vector2(-120,175),50,0,0],["FROZEN DRUMS",Vector2(295,100),28,145,16],["TIMBER STACK",Vector2(-350,65),38,200,24]]},
	{"name":"Championship Stadium","traction":0.92,"objects":[["RACE CAR PACK",Vector2(-260,-100),40,280,22],["OBSTACLE BUS",Vector2(210,-180),52,350,30],["TANKER SHELL",Vector2(35,85),54,400,34],["MEGA RAMP",Vector2(-120,175),54,0,0],["CRUSH WALL",Vector2(295,100),45,300,29],["SCRAP MOUNTAIN",Vector2(-350,65),48,280,25]]}
]
const COLORS: Array[Color] = [Color("#67f1df"),Color("#ffc46e"),Color("#ff6878"),Color("#a3a0ff"),Color("#8adf7c"),Color("#ec8ce3")]
const NAMES := ["HB Thunder","Blue Ox","Redline Rex","Night Crusher","Pine Mauler","Coastal King"]
var arena_index := 0
var trucks: Array[Dictionary] = []
var objects: Array[Dictionary] = []
var elapsed := 0.0
var finished := false
var winner := -1
var hits := 0

func reset(arena: int) -> void:
	arena_index=posmod(arena,ARENAS.size())
	elapsed=0.0
	finished=false
	winner=-1
	hits=0
	trucks.clear()
	objects.clear()
	var defs: Array=ARENAS[arena_index].objects
	for i in range(defs.size()):
		var d: Array=defs[i]
		objects.append({"name":d[0],"pos":d[1],"radius":float(d[2]),"hp":float(d[3]),"points":int(d[4]),"ramp":d[3]==0,"active":true})
	for i in range(6):
		trucks.append({"id":i,"name":NAMES[i],"color":COLORS[i],"pos":Vector2(-360.0+float(i)*140.0,260.0 if i%2==0 else -250.0),"velocity":Vector2.ZERO,"heading":0.0 if i%2==0 else PI,"damage":0.0,"score":0,"air_time":0.0,"boost":100.0})

func step(one: Dictionary,two: Dictionary,delta: float) -> void:
	if finished:return
	var dt:=clampf(delta,0.0,0.05)
	elapsed+=dt
	for i in range(6):
		var truck: Dictionary=trucks[i]
		if i<2:
			_drive(truck,one if i==0 else two,dt)
		else:
			_drive(truck,_ai(truck),dt)
		_collide_objects(truck,dt)
	_collide_trucks(dt)
	if elapsed>=ROUND_SECONDS:
		finished=true
		var order:=standings()
		winner=int(order[0].id)

func _drive(truck: Dictionary,controls: Dictionary,dt: float) -> void:
	var arena: Dictionary=ARENAS[arena_index]
	var throttle:=clampf(float(controls.get("throttle",0.0)),0.0,1.0)
	var brake:=clampf(float(controls.get("brake",0.0)),0.0,1.0)
	var steer:=clampf(float(controls.get("steer",0.0)),-1.0,1.0)
	var boosting:=bool(controls.get("boost",false)) and float(truck.boost)>0.0
	var velocity: Vector2=truck.velocity
	var speed:=velocity.length()
	var turn_rate: float=1.9*clampf(speed/65.0,0.18,1.0)*float(arena.traction)
	truck.heading+=steer*turn_rate*dt
	var forward:=Vector2(cos(float(truck.heading)),sin(float(truck.heading)))
	var power:=105.0+(55.0 if boosting else 0.0)
	velocity+=forward*(throttle*power-brake*150.0)*dt
	velocity=velocity.move_toward(Vector2.ZERO,(13.0+(1.0-float(arena.traction))*8.0)*dt)
	var max_speed:=112.0 if boosting else 82.0
	if velocity.length()>max_speed: velocity=velocity.normalized()*max_speed
	truck.velocity=velocity
	truck.pos=Vector2(truck.pos)+velocity*dt
	if boosting: truck.boost=maxf(0.0,float(truck.boost)-42.0*dt)
	else: truck.boost=minf(100.0,float(truck.boost)+13.0*dt)
	var radius:=Vector2(truck.pos)
	if radius.length()>520.0:
		truck.pos=radius.normalized()*520.0
		truck.velocity=velocity.bounce(-radius.normalized())*0.42
		truck.damage=minf(100.0,float(truck.damage)+6.0)

func _ai(truck: Dictionary) -> Dictionary:
	var target: Dictionary={}
	var nearest:=INF
	for obstacle in objects:
		if not bool(obstacle.active):continue
		var distance: float=Vector2(truck.pos).distance_to(Vector2(obstacle.pos))
		if distance<nearest:
			nearest=distance
			target=obstacle
	var desired:=Vector2(truck.pos)
	if not target.is_empty():desired=Vector2(target.pos)
	var direction:=desired-Vector2(truck.pos)
	var desired_heading:=direction.angle() if direction.length()>2.0 else float(truck.heading)
	var delta_angle:=wrapf(desired_heading-float(truck.heading),-PI,PI)
	var brake:=1.0 if nearest<70.0 and absf(delta_angle)>1.25 else 0.0
	return {"throttle":0.88,"steer":clampf(delta_angle*1.4,-1.0,1.0),"brake":brake,"boost":nearest>180.0 and float(truck.boost)>60.0}

func _collide_objects(truck: Dictionary,dt: float) -> void:
	for obstacle in objects:
		if not bool(obstacle.active):continue
		var offset:=Vector2(truck.pos)-Vector2(obstacle.pos)
		var distance:=offset.length()
		if distance<float(obstacle.radius)+18.0:
			if bool(obstacle.ramp):
				if float(truck.velocity.length())>38.0:
					truck.air_time=0.7
					truck.score=int(truck.score)+int(truck.velocity.length()*4.0)
				truck.velocity=Vector2(truck.velocity).bounce(Vector2(0,-1))*0.85
				obstacle.active=false
				continue
			var impact:=float(truck.velocity.length())
			var damage:=maxf(1.0,(impact-18.0)*0.18+float(obstacle.points)*0.025)
			obstacle.hp=maxf(0.0,float(obstacle.hp)-impact*dt*0.7)
			truck.damage=minf(100.0,float(truck.damage)+damage*dt)
			truck.score=int(truck.score)+int(damage)
			if float(obstacle.hp)<=0.0:
				obstacle.active=false
				truck.score=int(truck.score)+int(obstacle.points)
				hits+=1
			if distance>0.1:
				truck.pos=Vector2(obstacle.pos)+offset.normalized()*(float(obstacle.radius)+19.0)
			truck.velocity=Vector2(truck.velocity).bounce(offset.normalized())*0.48

func _collide_trucks(dt: float) -> void:
	for a in range(6):
		for b in range(a+1,6):
			var one: Dictionary=trucks[a]
			var two: Dictionary=trucks[b]
			var offset:=Vector2(one.pos)-Vector2(two.pos)
			if offset.length()<34.0:
				var normal:=offset.normalized() if offset.length()>0.01 else Vector2.RIGHT
				one.velocity=(Vector2(one.velocity)+normal*15.0)*0.72
				two.velocity=(Vector2(two.velocity)-normal*15.0)*0.72
				one.damage=minf(100.0,float(one.damage)+9.0*dt)
				two.damage=minf(100.0,float(two.damage)+9.0*dt)

func standings() -> Array:
	var order:=trucks.duplicate()
	order.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		return int(a.score)>int(b.score))
	return order

