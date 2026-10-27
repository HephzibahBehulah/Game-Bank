extends Node2D

const Sim=preload("res://scripts/drone_racing_simulation.gd")
const SAVE="user://drone_racing_progress.json"
var sim
var mode="briefing"
var track=0
var unlocked=1
var races=0
var wins=0

func _ready():
	_load()
	sim=Sim.new()
	sim.reset(track)
	queue_redraw()

func _process(dt):
	if mode!="race":return
	sim.step(_controls(0),_controls(1),dt)
	if sim.finished:
		mode="results"
		races+=1
		if sim.winner==0:
			wins+=1
			if track==unlocked-1 and unlocked<Sim.TRACKS.size():unlocked+=1
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
		if left:track=posmod(track-1,unlocked)
		elif right:track=posmod(track+1,unlocked)
		elif _confirm(event):sim.reset(track);mode="race"
		elif back:get_tree().change_scene_to_file("res://scenes/hub.tscn")
	elif mode=="race" and (back or start):mode="paused"
	elif mode=="paused":
		if _confirm(event) or start:mode="race"
		elif back:mode="briefing"
	elif mode=="results":
		if _confirm(event):get_tree().change_scene_to_file("res://scenes/hub.tscn")
		elif back:mode="briefing"
	queue_redraw()

func _draw():
	draw_rect(Rect2(0,0,1280,800),Color("#07121d"))
	if mode=="briefing":_draw_briefing()
	elif mode=="race" or mode=="paused":
		_draw_race()
		if mode=="paused":
			draw_rect(Rect2(390,320,500,160),Color("#06111eee"))
			draw_string(ThemeDB.fallback_font,Vector2(535,385),"FLIGHT PAUSED",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("#67f1df"))
			draw_string(ThemeDB.fallback_font,Vector2(460,430),"A / ENTER resume  ·  B / ESC exit",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
	elif mode=="results":_draw_results()

func _draw_briefing():
	var t=Sim.TRACKS[track]
	var f=ThemeDB.fallback_font
	draw_string(f,Vector2(74,88),"DRONE RACING",HORIZONTAL_ALIGNMENT_LEFT,-1,42,Color("#67f1df"))
	draw_string(f,Vector2(76,130),"SIX FPV PILOTS  ·  TWO LOCAL DRIVERS  ·  GATE-TO-GATE BATTERY RACING",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#bdcad5"))
	draw_string(f,Vector2(76,220),"COURSE %02d / 05  ·  %s" % [track+1,str(t.name).to_upper()],HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#ffc46e"))
	draw_string(f,Vector2(76,276),"GATES %d  ·  LAPS %d  ·  CROSSWIND %d%%" % [t.gates.size(),Sim.LAPS,int(float(t.wind)*100.0)],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
	draw_string(f,Vector2(76,350),"FLY THROUGH EACH CYAN GATE IN ORDER. MISSED GATES DO NOT COUNT.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#67f1df"))
	draw_string(f,Vector2(76,390),"BOOST ON LONG STRAIGHTS, SAVE BATTERY, AND AVOID RED HAZARD ZONES.",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
	draw_string(f,Vector2(76,500),"PLAYER 1  W throttle · A/D yaw · S brake · SHIFT boost",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#67f1df"))
	draw_string(f,Vector2(76,536),"PLAYER 2  ↑ throttle · ←/→ yaw · ↓ brake · ENTER boost",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#ffc46e"))
	draw_string(f,Vector2(76,580),"GAMEPAD  left stick yaw · RT throttle · LT brake · RB boost · A start",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#bdcad5"))
	draw_string(f,Vector2(76,640),"CAREER  %d races  ·  %d wins  ·  %d courses unlocked" % [races,wins,unlocked],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#9ab7c4"))
	draw_rect(Rect2(430,680,420,64),Color("#315a68"),false,3.0)
	draw_string(f,Vector2(500,720),"START FLIGHT  ·  A / ENTER",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE)
	draw_string(f,Vector2(76,773),"ESC / B returns to the hub  ·  Win to unlock the next circuit",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#849ba9"))

func _draw_race():
	var f=ThemeDB.fallback_font
	var t=Sim.TRACKS[sim.track_index]
	draw_rect(Rect2(48,145,850,530),Color("#102b39"))
	draw_rect(Rect2(62,159,822,502),Color("#163544"),false,3.0)
	for i in range(t.gates.size()):
		var gate=_screen(Vector2(t.gates[i]))
		var next_gate=(i==int(sim.drones[0].gate))
		draw_circle(gate,29.0,Color("#67f1df33"))
		draw_arc(gate,28.0,0,TAU,40,Color("#67f1df") if next_gate else Color("#62a8b8"),3.0,true)
		draw_string(f,gate+Vector2(-6,5),str(i+1),HORIZONTAL_ALIGNMENT_CENTER,12,13,Color.WHITE)
	for hazard in t.hazards:
		var pos=_screen(Vector2(hazard))
		draw_circle(pos,22.0,Color("#ff657844"))
		draw_arc(pos,21.0,0,TAU,32,Color("#ff6578"),2.0,true)
	for drone in sim.drones:
		var pos=_screen(Vector2(drone.pos))
		var forward=Vector2(cos(float(drone.heading)),sin(float(drone.heading)))
		var side=Vector2(-forward.y,forward.x)
		var points=PackedVector2Array([pos+forward*15.0,pos-forward*9.0+side*8.0,pos-forward*6.0,pos-forward*9.0-side*8.0])
		draw_colored_polygon(points,drone.color)
	draw_rect(Rect2(26,20,1228,96),Color("#06111eec"))
	draw_string(f,Vector2(48,55),"DRONE RACING  ·  %s" % str(t.name).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#67f1df"))
	draw_string(f,Vector2(48,94),"P1 LAP %d/%d  GATE %d/%d  BATTERY %d%%" % [sim.drones[0].lap+1,Sim.LAPS,sim.drones[0].gate+1,t.gates.size(),int(sim.drones[0].battery)],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#67f1df"))
	draw_string(f,Vector2(460,94),"P2 LAP %d/%d  GATE %d/%d  BATTERY %d%%" % [sim.drones[1].lap+1,Sim.LAPS,sim.drones[1].gate+1,t.gates.size(),int(sim.drones[1].battery)],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffc46e"))
	var order=sim.standings()
	draw_string(f,Vector2(935,190),"LIVE FLIGHT ORDER",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffc46e"))
	for i in range(order.size()):
		draw_string(f,Vector2(935,230+i*35),"%d  %s  ·  %d/%d" % [i+1,str(order[i].name),order[i].lap,int(order[i].gate)+1],HORIZONTAL_ALIGNMENT_LEFT,-1,15,order[i].color)
	draw_string(f,Vector2(50,744),"W/↑ throttle  ·  A/D or ←/→ yaw  ·  S/↓ airbrake  ·  SHIFT/ENTER or RB boost",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#b9d5dd"))

func _screen(world):
	return Vector2(473,410)+world*0.9

func _draw_results():
	var f=ThemeDB.fallback_font
	draw_string(f,Vector2(74,95),"RACE COMPLETE",HORIZONTAL_ALIGNMENT_LEFT,-1,40,Color("#67f1df"))
	var order=sim.standings()
	for i in range(order.size()):
		var drone=order[i]
		draw_string(f,Vector2(84,185+i*48),"%02d   %s   lap %d   %d gates   %d points" % [i+1,str(drone.name),drone.lap,drone.gate,int(drone.score)],HORIZONTAL_ALIGNMENT_LEFT,-1,20,drone.color)
	draw_string(f,Vector2(84,600),"WINNER  %s" % str(sim.drones[sim.winner].name),HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#67f1df"))
	draw_string(f,Vector2(84,660),"CAREER  %d races  ·  %d wins" % [races,wins],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#bdcad5"))
	draw_string(f,Vector2(84,730),"A / ENTER  return to hub   ·   B / ESC  course briefing",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)

func _load():
	if not FileAccess.file_exists(SAVE):return
	var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if data is Dictionary:
		races=maxi(0,int(data.get("races",0)))
		wins=maxi(0,int(data.get("wins",0)))
		unlocked=clampi(int(data.get("unlocked",1)),1,Sim.TRACKS.size())
	track=mini(track,unlocked-1)

func _save():
	var file=FileAccess.open(SAVE,FileAccess.WRITE)
	if file:file.store_string(JSON.stringify({"races":races,"wins":wins,"unlocked":unlocked}))

