extends Node2D

const Sim=preload("res://scripts/monster_truck_arena_simulation.gd")
const SAVE="user://monster_truck_arena_progress.json"
var sim
var mode="briefing"
var arena=0
var unlocked=1
var matches=0
var wins=0

func _ready():
	_load()
	sim=Sim.new()
	sim.reset(arena)
	queue_redraw()

func _process(dt):
	if mode!="arena":return
	sim.step(_controls(0),_controls(1),dt)
	if sim.finished:
		mode="results"
		matches+=1
		if sim.winner==0:
			wins+=1
			if arena==unlocked-1 and unlocked<Sim.ARENAS.size():unlocked+=1
		_save()
	queue_redraw()

func _controls(player):
	var steer=(float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A))) if player==0 else (float(Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_LEFT)))
	var throttle=float(Input.is_key_pressed(KEY_W)) if player==0 else float(Input.is_key_pressed(KEY_UP))
	var brake=float(Input.is_key_pressed(KEY_S)) if player==0 else float(Input.is_key_pressed(KEY_DOWN))
	var boost=Input.is_key_pressed(KEY_SHIFT) if player==0 else Input.is_key_pressed(KEY_ENTER)
	var pads=Input.get_connected_joypads()
	pads.sort()
	if player<pads.size():
		var pad=pads[player]
		var axis=Input.get_joy_axis(pad,JOY_AXIS_LEFT_X)
		if absf(axis)>0.14:steer=signf(axis)*(absf(axis)-0.14)/0.86
		throttle=maxf(throttle,clampf(Input.get_joy_axis(pad,JOY_AXIS_TRIGGER_RIGHT),0.0,1.0))
		brake=maxf(brake,clampf(Input.get_joy_axis(pad,JOY_AXIS_TRIGGER_LEFT),0.0,1.0))
		boost=boost or Input.is_joy_button_pressed(pad,JOY_BUTTON_RIGHT_SHOULDER)
	return {"steer":steer,"throttle":throttle,"brake":brake,"boost":boost}

func _confirm(event):
	return event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_A)

func _unhandled_input(event):
	var left=event.is_action_pressed("ui_left") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_DPAD_LEFT)
	var right=event.is_action_pressed("ui_right") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_DPAD_RIGHT)
	var back=event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_B)
	var start=event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START
	if mode=="briefing":
		if left:arena=posmod(arena-1,unlocked)
		elif right:arena=posmod(arena+1,unlocked)
		elif _confirm(event):sim.reset(arena);mode="arena"
		elif back:get_tree().change_scene_to_file("res://scenes/hub.tscn")
	elif mode=="arena" and (back or start):mode="paused"
	elif mode=="paused":
		if _confirm(event) or start:mode="arena"
		elif back:mode="briefing"
	elif mode=="results":
		if _confirm(event):get_tree().change_scene_to_file("res://scenes/hub.tscn")
		elif back:mode="briefing"
	queue_redraw()

func _draw():
	draw_rect(Rect2(0,0,1280,800),Color("#08121b"))
	if mode=="briefing":_draw_briefing()
	elif mode=="arena" or mode=="paused":
		_draw_arena()
		if mode=="paused":
			draw_rect(Rect2(390,320,500,160),Color("#06111eee"))
			draw_string(ThemeDB.fallback_font,Vector2(525,385),"ARENA PAUSED",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("#ffbd67"))
			draw_string(ThemeDB.fallback_font,Vector2(460,430),"A / ENTER resume  ·  B / ESC exit",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
	elif mode=="results":_draw_results()

func _draw_briefing():
	var a=Sim.ARENAS[arena]
	var f=ThemeDB.fallback_font
	draw_string(f,Vector2(74,88),"MONSTER TRUCK ARENA",HORIZONTAL_ALIGNMENT_LEFT,-1,40,Color("#ffbd67"))
	draw_string(f,Vector2(76,130),"TWO LOCAL DRIVERS  ·  FOUR RULE-DRIVEN RIVAL TRUCKS  ·  90-SECOND DERBY",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#bdcad5"))
	draw_string(f,Vector2(76,220),"ARENA %02d / 05  ·  %s" % [arena+1,str(a.name).to_upper()],HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#68f1df"))
	draw_string(f,Vector2(76,276),"SURFACE TRACTION %d%%  ·  BREAKABLE TARGETS  %d  ·  STUNT RAMP  1" % [int(float(a.traction)*100.0),a.objects.size()-1],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
	draw_string(f,Vector2(76,350),"BUILD POINTS BY CRUSHING THE ARENA TARGETS. HEAVY IMPACTS SCORE MORE.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ffbd67"))
	draw_string(f,Vector2(76,390),"HIT THE RAMP AT SPEED FOR A STUNT BONUS. DAMAGE REDUCES CONTROL.",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
	draw_string(f,Vector2(76,500),"PLAYER 1  W throttle · A/D steer · S brake · SHIFT boost",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#68f1df"))
	draw_string(f,Vector2(76,536),"PLAYER 2  ↑ throttle · ←/→ steer · ↓ brake · ENTER boost",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#ffc46e"))
	draw_string(f,Vector2(76,580),"GAMEPAD  left stick steer · RT throttle · LT brake · RB boost · A start",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#bdcad5"))
	draw_string(f,Vector2(76,640),"CAREER  %d rounds  ·  %d wins  ·  %d arenas unlocked" % [matches,wins,unlocked],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#9ab7c4"))
	draw_rect(Rect2(430,680,420,64),Color("#674c30"),false,3.0)
	draw_string(f,Vector2(500,720),"START DERBY  ·  A / ENTER",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE)
	draw_string(f,Vector2(76,773),"ESC / B returns to the hub  ·  Win to unlock the next stadium",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#849ba9"))

func _draw_arena():
	var f=ThemeDB.fallback_font
	var a=Sim.ARENAS[sim.arena_index]
	_draw_ellipse(Vector2(560,410),Vector2(390,285),Color("#26343b"))
	_draw_ellipse(Vector2(560,410),Vector2(360,255),Color("#3b4441"))
	_draw_ellipse(Vector2(560,410),Vector2(325,220),Color("#35463d"))
	for obj in sim.objects:
		if not obj.active:continue
		var pos=_screen(Vector2(obj.pos))
		var col=Color("#f1a94f") if obj.ramp else Color("#ff626c") if float(obj.hp)<100.0 else Color("#8c9ca6")
		draw_rect(Rect2(pos-Vector2(13,13),Vector2(26,26)),col)
		draw_string(f,pos+Vector2(-27,30),str(obj.name),HORIZONTAL_ALIGNMENT_CENTER,90,10,Color("#d5e1e6"))
	for truck in sim.trucks:
		var pos=_screen(Vector2(truck.pos))
		var angle=float(truck.heading)
		draw_set_transform(pos,angle,Vector2.ONE)
		draw_rect(Rect2(-19,-12,38,24),truck.color)
		draw_rect(Rect2(1,-7,10,14),Color("#14212a"))
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		draw_circle(pos,3.0,Color.WHITE)
	draw_rect(Rect2(25,20,1230,98),Color("#06111eec"))
	draw_string(f,Vector2(49,54),"MONSTER TRUCK ARENA  ·  %s" % str(a.name).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#ffbd67"))
	draw_string(f,Vector2(49,94),"TIME %02d s  ·  TARGETS %d/%d" % [int(Sim.ROUND_SECONDS-sim.elapsed),sim.hits,a.objects.size()-1],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
	draw_string(f,Vector2(415,94),"P1  %d pts  ·  DAMAGE %d%%" % [sim.trucks[0].score,int(sim.trucks[0].damage)],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#68f1df"))
	draw_string(f,Vector2(760,94),"P2  %d pts  ·  DAMAGE %d%%" % [sim.trucks[1].score,int(sim.trucks[1].damage)],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffc46e"))
	var order=sim.standings()
	draw_string(f,Vector2(970,210),"ARENA LEADERBOARD",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#ffbd67"))
	for i in range(order.size()):
		draw_string(f,Vector2(970,248+i*30),"%d  %s  ·  %d" % [i+1,str(order[i].name),int(order[i].score)],HORIZONTAL_ALIGNMENT_LEFT,-1,14,order[i].color)
	draw_string(f,Vector2(45,755),"W/↑ throttle  ·  A/D or ←/→ steer  ·  S/↓ brake  ·  SHIFT/ENTER or RB boost  ·  START pause",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#b9d5dd"))

func _screen(world):
	return Vector2(560,410)+world*0.68

func _draw_results():
	var f=ThemeDB.fallback_font
	draw_string(f,Vector2(74,95),"ARENA CHECKERED FLAG",HORIZONTAL_ALIGNMENT_LEFT,-1,39,Color("#ffbd67"))
	var order=sim.standings()
	for i in range(order.size()):
		var car=order[i]
		draw_string(f,Vector2(84,185+i*48),"%02d   %s   %d points   damage %d%%" % [i+1,str(car.name),int(car.score),int(car.damage)],HORIZONTAL_ALIGNMENT_LEFT,-1,20,car.color)
	draw_string(f,Vector2(84,600),"WINNER  %s" % str(sim.trucks[sim.winner].name),HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#68f1df"))
	draw_string(f,Vector2(84,660),"CAREER  %d rounds  ·  %d wins" % [matches,wins],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#bdcad5"))
	draw_string(f,Vector2(84,730),"A / ENTER  return to hub   ·   B / ESC  arena briefing",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)

func _draw_ellipse(center,radius,color):
	var points=PackedVector2Array()
	for i in range(65):
		var angle=TAU*float(i)/64.0
		points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
	draw_colored_polygon(points,color)

func _load():
	if not FileAccess.file_exists(SAVE):return
	var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if data is Dictionary:
		matches=maxi(0,int(data.get("matches",0)))
		wins=maxi(0,int(data.get("wins",0)))
		unlocked=clampi(int(data.get("unlocked",1)),1,Sim.ARENAS.size())
	arena=mini(arena,unlocked-1)

func _save():
	var file=FileAccess.open(SAVE,FileAccess.WRITE)
	if file:file.store_string(JSON.stringify({"matches":matches,"wins":wins,"unlocked":unlocked}))

