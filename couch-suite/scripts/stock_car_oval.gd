extends Node2D
const Sim = preload("res://scripts/stock_car_oval_simulation.gd")
const SAVE = "user://stock_car_oval_progress.json"
var sim
var mode = "briefing"
var track = 0
var unlocked = 1
var starts = 0
var wins = 0

func _ready():
	_load()
	sim = Sim.new()
	sim.reset(track)
	queue_redraw()

func _process(dt):
	if mode != "race": return
	sim.step(_controls(0), _controls(1), dt)
	if sim.finished:
		mode = "results"
		starts += 1
		if sim.winner == 0:
			wins += 1
			if track == unlocked - 1 and unlocked < Sim.TRACKS.size(): unlocked += 1
		_save()
	queue_redraw()

func _controls(player):
	var steer = (float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A))) if player == 0 else (float(Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_LEFT)))
	var throttle = float(Input.is_key_pressed(KEY_W)) if player == 0 else float(Input.is_key_pressed(KEY_UP))
	var brake = float(Input.is_key_pressed(KEY_S)) if player == 0 else float(Input.is_key_pressed(KEY_DOWN))
	var pads = Input.get_connected_joypads()
	pads.sort()
	if player < pads.size():
		var pad = pads[player]
		var axis = Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
		if absf(axis) > 0.14: steer = signf(axis)*(absf(axis)-0.14)/0.86
		throttle = maxf(throttle, clampf(Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT),0.0,1.0))
		brake = maxf(brake, clampf(Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT),0.0,1.0))
	return {"steer":steer,"throttle":throttle,"brake":brake}

func _confirm(event):
	return event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A)

func _unhandled_input(event):
	var left = event.is_action_pressed("ui_left") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_LEFT)
	var right = event.is_action_pressed("ui_right") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_RIGHT)
	var back = event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
	var start = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
	if mode == "briefing":
		if left: track = posmod(track-1,unlocked)
		elif right: track = posmod(track+1,unlocked)
		elif _confirm(event): sim.reset(track); mode = "race"
		elif back: get_tree().change_scene_to_file("res://scenes/hub.tscn")
	elif mode == "race" and (back or start): mode = "paused"
	elif mode == "paused":
		if _confirm(event) or start: mode = "race"
		elif back: mode = "briefing"
	elif mode == "results":
		if _confirm(event): get_tree().change_scene_to_file("res://scenes/hub.tscn")
		elif back: mode = "briefing"
	queue_redraw()

func _draw():
	draw_rect(Rect2(0,0,1280,800),Color("#07121d"))
	if mode == "briefing": _draw_briefing()
	elif mode == "race" or mode == "paused":
		_draw_race()
		if mode == "paused":
			draw_rect(Rect2(390,320,500,160),Color("#06111eee"))
			draw_string(ThemeDB.fallback_font,Vector2(530,385),"RACE PAUSED",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("#70f0e5"))
			draw_string(ThemeDB.fallback_font,Vector2(460,430),"A / ENTER resume  ·  B / ESC exit",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
	elif mode == "results": _draw_results()

func _draw_briefing():
	var t = Sim.TRACKS[track]
	var f = ThemeDB.fallback_font
	draw_string(f,Vector2(74,90),"STOCK CAR OVAL",HORIZONTAL_ALIGNMENT_LEFT,-1,42,Color("#ffc66e"))
	draw_string(f,Vector2(76,132),"SIX-CAR RACING  ·  TWO LOCAL DRIVERS  ·  DRAFT & TYRE MANAGEMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#bdcad5"))
	draw_string(f,Vector2(76,215),"TRACK %02d / 05  ·  %s" % [track+1,str(t.name).to_upper()],HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#68f1d8"))
	draw_string(f,Vector2(76,270),"LENGTH %d m  ·  BANKING %d%%  ·  GRIP %d%%  ·  %d LAPS" % [int(t.length),int(float(t.bank)*100.0),int(float(t.grip)*100.0),Sim.LAPS],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
	draw_string(f,Vector2(76,350),"HOLD THE THROTTLE ON STRAIGHTS. BRAKE WHEN TIRE TEMPERATURE RISES.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ffc66e"))
	draw_string(f,Vector2(76,390),"DRAFT BEHIND TRAFFIC, PROTECT YOUR LINE, AND AVOID CLOSE-CONTACT DAMAGE.",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
	draw_string(f,Vector2(76,500),"PLAYER 1  W throttle · A/D steer · S brake",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#68f1d8"))
	draw_string(f,Vector2(76,536),"PLAYER 2  ↑ throttle · ←/→ steer · ↓ brake",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#ffc66e"))
	draw_string(f,Vector2(76,580),"GAMEPAD  left stick steer · RT throttle · LT brake · A / Cross start",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#bdcad5"))
	draw_string(f,Vector2(76,640),"CAREER  %d starts  ·  %d wins  ·  %d tracks unlocked" % [starts,wins,unlocked],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#9ab7c4"))
	draw_rect(Rect2(430,680,420,64),Color("#315f68"),false,3.0)
	draw_string(f,Vector2(500,720),"START RACE  ·  A / ENTER",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE)
	draw_string(f,Vector2(76,773),"ESC / B returns to the hub  ·  Win to unlock the next oval",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#849ba9"))

func _draw_race():
	var f = ThemeDB.fallback_font
	var t = Sim.TRACKS[sim.track_index]
	draw_circle(Vector2(640,405),302,Color("#718591"))
	draw_circle(Vector2(640,405),251,Color("#254838"))
	draw_circle(Vector2(640,405),185,Color("#07121d"))
	draw_arc(Vector2(640,405),276,0,TAU,128,Color("#f0dca5"),3.0,true)
	draw_arc(Vector2(640,405),226,0,TAU,128,Color("#f0dca5"),3.0,true)
	draw_string(f,Vector2(525,401),str(t.name).to_upper(),HORIZONTAL_ALIGNMENT_CENTER,230,17,Color("#70f0e5"))
	draw_string(f,Vector2(548,430),"OVAL · %d LAPS" % Sim.LAPS,HORIZONTAL_ALIGNMENT_CENTER,180,14,Color("#9ab7c4"))
	for car in sim.cars:
		var progress = fposmod(maxf(0.0,float(car.progress)),float(t.length))/float(t.length)
		var angle = progress*TAU-PI/2.0
		var radius = 251.0+float(car.lane)*23.0
		var pos = Vector2(640+cos(angle)*radius,405+sin(angle)*radius*0.68)
		draw_circle(pos,13.0,Color("#07121d"))
		draw_circle(pos,9.0,car.color)
		if int(car.id)<2: draw_string(f,pos+Vector2(-6,5),str(int(car.id)+1),HORIZONTAL_ALIGNMENT_CENTER,12,11,Color("#06121b"))
	draw_rect(Rect2(28,24,1224,94),Color("#06111ee8"))
	draw_string(f,Vector2(52,57),"STOCK CAR OVAL  ·  %s" % str(t.name).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#70f0e5"))
	draw_string(f,Vector2(52,95),"P1 LAP %d/%d  SPEED %02d  TYRES %d°C" % [sim.completed_laps(0),Sim.LAPS,int(sim.cars[0].speed),int(sim.cars[0].temp)],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#68f1d8"))
	draw_string(f,Vector2(650,95),"P2 LAP %d/%d  SPEED %02d  TYRES %d°C" % [sim.completed_laps(1),Sim.LAPS,int(sim.cars[1].speed),int(sim.cars[1].temp)],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffc66e"))
	var board = sim.standings()
	draw_string(f,Vector2(915,220),"LIVE RUNNING ORDER",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffc66e"))
	for i in range(board.size()):
		var car = board[i]
		draw_string(f,Vector2(915,580+float(i)*27.0),"%d  %s  ·  LAP %d  ·  %02d" % [i+1,str(car.name),sim.completed_laps(int(car.id)),int(car.speed)],HORIZONTAL_ALIGNMENT_LEFT,-1,14,car.color)
	draw_string(f,Vector2(58,744),"W/↑ throttle  ·  A/D or ←/→ steer  ·  S/↓ brake  ·  START pause",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#b9d5dd"))

func _draw_results():
	var f = ThemeDB.fallback_font
	draw_string(f,Vector2(72,100),"CHECKERED FLAG",HORIZONTAL_ALIGNMENT_LEFT,-1,40,Color("#ffc66e"))
	var order = sim.standings()
	for i in range(order.size()):
		var car = order[i]
		draw_string(f,Vector2(84,190+float(i)*48.0),"%02d   %s   %d laps   best lap %.2f s" % [i+1,str(car.name),sim.completed_laps(int(car.id)),float(car.best_lap)],HORIZONTAL_ALIGNMENT_LEFT,-1,20,car.color)
	draw_string(f,Vector2(84,585),"WINNER  %s" % str(sim.cars[sim.winner].name),HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#70f0e5"))
	draw_string(f,Vector2(84,645),"CAREER  %d starts  ·  %d wins" % [starts,wins],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#bdcad5"))
	draw_string(f,Vector2(84,720),"A / ENTER  return to hub   ·   B / ESC  track briefing",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)

func _load():
	if not FileAccess.file_exists(SAVE): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if data is Dictionary:
		starts = maxi(0,int(data.get("starts",0)))
		wins = maxi(0,int(data.get("wins",0)))
		unlocked = clampi(int(data.get("unlocked",1)),1,Sim.TRACKS.size())
	track = mini(track,unlocked-1)

func _save():
	var file = FileAccess.open(SAVE,FileAccess.WRITE)
	if file: file.store_string(JSON.stringify({"starts":starts,"wins":wins,"unlocked":unlocked}))

