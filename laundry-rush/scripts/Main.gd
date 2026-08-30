extends Node2D

const SHIFT_LENGTH = 150.0
const PLAYER_SPEED = 280.0
const INTERACT_DISTANCE = 105.0
const PAYOUT = 180
const FUEL_MAX = 100.0
const FUEL_START = 65.0
const FUEL_DRAIN = 2.2
const FUEL_BUY = 50.0
const FUEL_COST = 100

const SHOP_LEFT = 36.0
const SHOP_TOP = 150.0
const SHOP_RIGHT = 684.0
const SHOP_BOTTOM = 975.0

const DROP_OFF = Vector2(120, 270)
const WASHER = Vector2(185, 485)
const DRYER = Vector2(535, 485)
const IRON = Vector2(185, 720)
const COLLECTION = Vector2(535, 720)
const GENERATOR = Vector2(115, 900)
const FUEL_POINT = Vector2(605, 900)
const JOYSTICK_CENTER = Vector2(145, 1135)
const JOYSTICK_RADIUS = 86.0

var player_pos = Vector2(360, 825)
var move_vector = Vector2.ZERO
var joystick_touch = -1
var joystick_knob = Vector2.ZERO

var carry_stage = ""
var processing_station = ""
var process_left = 0.0
var process_total = 1.0
var washer_output = ""
var dryer_output = ""
var iron_output = ""

var dirty_waiting = true
var customer_present = true
var payment_ready = false
var next_customer_timer = -1.0

var cash = 0
var gross_earned = 0
var fuel_spent = 0
var served = 0
var time_left = SHIFT_LENGTH
var shift_over = false

var grid_on = true
var grid_timer = 24.0
var generator_on = false
var fuel = FUEL_START

var cash_label
var timer_label
var power_label
var fuel_label
var status_label
var objective_label
var result_panel
var result_label

func _ready():
	randomize()
	grid_timer = randf_range(20.0, 30.0)
	build_hud()
	set_status("Customer waiting at DROP-OFF. Walk over and collect the laundry.")
	refresh_hud()
	queue_redraw()

func _process(delta):
	if shift_over:
		return

	time_left = max(0.0, time_left - delta)
	update_power(delta)
	update_processing(delta)
	update_customer(delta)
	update_player(delta)
	refresh_hud()
	queue_redraw()

	if time_left <= 0.0:
		end_shift()

func update_player(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0

	if direction.length() < 0.05:
		direction = move_vector
	else:
		direction = direction.normalized()

	player_pos += direction * PLAYER_SPEED * delta
	player_pos.x = clamp(player_pos.x, SHOP_LEFT + 24.0, SHOP_RIGHT - 24.0)
	player_pos.y = clamp(player_pos.y, SHOP_TOP + 24.0, SHOP_BOTTOM - 24.0)

func update_power(delta):
	grid_timer -= delta
	if grid_timer <= 0.0:
		grid_on = not grid_on
		if grid_on:
			grid_timer = randf_range(22.0, 34.0)
			set_status("NEPA/PHCN is back. Switch generator OFF to save fuel.")
		else:
			grid_timer = randf_range(14.0, 22.0)
			set_status("BLACKOUT! Walk to the generator and switch it ON.")

	if generator_on:
		fuel = max(0.0, fuel - FUEL_DRAIN * delta)
		if fuel <= 0.0:
			fuel = 0.0
			generator_on = false
			set_status("Generator fuel finished. Buy fuel or wait for NEPA/PHCN.")

func has_power():
	return grid_on or (generator_on and fuel > 0.0)

func update_processing(delta):
	if processing_station == "":
		return
	if not has_power():
		return

	process_left -= delta
	if process_left > 0.0:
		return

	if processing_station == "washer":
		washer_output = "washed"
	elif processing_station == "dryer":
		dryer_output = "dried"
	elif processing_station == "iron":
		iron_output = "ironed"

	set_status(station_title(processing_station) + " finished. Walk back and collect the basket.")
	processing_station = ""
	process_left = 0.0

func update_customer(delta):
	if next_customer_timer < 0.0:
		return
	next_customer_timer -= delta
	if next_customer_timer <= 0.0:
		next_customer_timer = -1.0
		customer_present = true
		dirty_waiting = true
		set_status("A new customer has arrived at DROP-OFF.")

func build_hud():
	var canvas = CanvasLayer.new()
	add_child(canvas)

	var top_bg = ColorRect.new()
	top_bg.color = Color("111827")
	top_bg.position = Vector2(0, 0)
	top_bg.size = Vector2(720, 145)
	canvas.add_child(top_bg)

	var title = Label.new()
	title.text = "LAUNDRY RUSH - V0.2 SHOP"
	title.position = Vector2(20, 12)
	title.size = Vector2(680, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	canvas.add_child(title)

	cash_label = Label.new()
	cash_label.position = Vector2(28, 58)
	cash_label.size = Vector2(210, 30)
	cash_label.add_theme_font_size_override("font_size", 19)
	canvas.add_child(cash_label)

	timer_label = Label.new()
	timer_label.position = Vector2(255, 58)
	timer_label.size = Vector2(190, 30)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 19)
	canvas.add_child(timer_label)

	power_label = Label.new()
	power_label.position = Vector2(462, 55)
	power_label.size = Vector2(230, 30)
	power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	power_label.add_theme_font_size_override("font_size", 17)
	canvas.add_child(power_label)

	fuel_label = Label.new()
	fuel_label.position = Vector2(462, 84)
	fuel_label.size = Vector2(230, 30)
	fuel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fuel_label.add_theme_font_size_override("font_size", 17)
	canvas.add_child(fuel_label)

	objective_label = Label.new()
	objective_label.position = Vector2(22, 106)
	objective_label.size = Vector2(676, 30)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 16)
	canvas.add_child(objective_label)

	var bottom_bg = ColorRect.new()
	bottom_bg.color = Color(0.05, 0.08, 0.12, 0.92)
	bottom_bg.position = Vector2(0, 990)
	bottom_bg.size = Vector2(720, 290)
	canvas.add_child(bottom_bg)

	status_label = Label.new()
	status_label.position = Vector2(230, 1008)
	status_label.size = Vector2(455, 72)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 17)
	canvas.add_child(status_label)

	var interact_button = Button.new()
	interact_button.text = "INTERACT"
	interact_button.position = Vector2(500, 1100)
	interact_button.size = Vector2(185, 105)
	interact_button.add_theme_font_size_override("font_size", 22)
	interact_button.pressed.connect(try_interact)
	canvas.add_child(interact_button)

	var hint = Label.new()
	hint.text = "Move with joystick / WASD"
	hint.position = Vector2(240, 1218)
	hint.size = Vector2(445, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	canvas.add_child(hint)

	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.position = Vector2(80, 405)
	result_panel.size = Vector2(560, 390)
	canvas.add_child(result_panel)

	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	result_panel.add_child(box)

	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 24)
	box.add_child(result_label)

	var restart = Button.new()
	restart.text = "PLAY ANOTHER SHIFT"
	restart.custom_minimum_size = Vector2(390, 76)
	restart.pressed.connect(restart_game)
	box.add_child(restart)

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			try_interact()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(JOYSTICK_CENTER) <= JOYSTICK_RADIUS * 1.6 and joystick_touch == -1:
				joystick_touch = event.index
				set_joystick(event.position)
		else:
			if event.index == joystick_touch:
				joystick_touch = -1
				move_vector = Vector2.ZERO
				joystick_knob = Vector2.ZERO
				queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			set_joystick(event.position)

func set_joystick(pos):
	var delta = pos - JOYSTICK_CENTER
	joystick_knob = delta.limit_length(JOYSTICK_RADIUS)
	move_vector = joystick_knob / JOYSTICK_RADIUS
	queue_redraw()

func try_interact():
	if shift_over:
		return
	var target = nearest_interaction()
	if target == "dropoff":
		interact_dropoff()
	elif target == "washer":
		interact_machine("washer")
	elif target == "dryer":
		interact_machine("dryer")
	elif target == "iron":
		interact_machine("iron")
	elif target == "collection":
		interact_collection()
	elif target == "generator":
		interact_generator()
	elif target == "fuel":
		interact_fuel()
	else:
		set_status("Move closer to a station, customer counter, generator or fuel point.")

func nearest_interaction():
	var best = ""
	var best_dist = INTERACT_DISTANCE
	var names = ["dropoff", "washer", "dryer", "iron", "collection", "generator", "fuel"]
	for name in names:
		var p = interaction_position(name)
		var d = player_pos.distance_to(p)
		if d < best_dist:
			best_dist = d
			best = name
	return best

func interact_dropoff():
	if carry_stage != "":
		set_status("Your hands are full. Take the basket to the correct station.")
		return
	if dirty_waiting:
		dirty_waiting = false
		carry_stage = "dirty"
		set_status("DIRTY laundry collected. Take it to the WASHER.")
	else:
		set_status("No laundry is waiting at drop-off.")

func interact_machine(machine):
	var output = get_machine_output(machine)
	if output != "":
		if carry_stage != "":
			set_status("Your hands are full. Deliver your current basket first.")
			return
		carry_stage = output
		set_machine_output(machine, "")
		set_status("Basket collected. Next: " + next_destination(carry_stage) + ".")
		return

	if processing_station == machine:
		set_status(station_title(machine) + " is still processing.")
		return
	if processing_station != "":
		set_status("Another machine is processing this order.")
		return
	if carry_stage == "":
		set_status("You are not carrying any laundry.")
		return

	var required = ""
	var duration = 4.0
	if machine == "washer":
		required = "dirty"
		duration = 5.0
	elif machine == "dryer":
		required = "washed"
		duration = 4.5
	elif machine == "iron":
		required = "dried"
		duration = 4.0

	if carry_stage != required:
		set_status("Wrong station. This basket needs " + next_destination(carry_stage) + ".")
		return
	if not has_power():
		set_status("No electricity. Start the GENERATOR or wait for NEPA/PHCN.")
		return

	carry_stage = ""
	processing_station = machine
	process_total = duration
	process_left = duration
	set_status(station_title(machine) + " started. You can move while it works.")

func get_machine_output(machine):
	if machine == "washer":
		return washer_output
	if machine == "dryer":
		return dryer_output
	if machine == "iron":
		return iron_output
	return ""

func set_machine_output(machine, value):
	if machine == "washer":
		washer_output = value
	elif machine == "dryer":
		dryer_output = value
	elif machine == "iron":
		iron_output = value

func interact_collection():
	if payment_ready:
		cash += PAYOUT
		gross_earned += PAYOUT
		served += 1
		payment_ready = false
		customer_present = false
		next_customer_timer = 3.0
		set_status("Payment collected: +N%d. New customer arriving soon." % PAYOUT)
		return
	if carry_stage == "ironed":
		carry_stage = ""
		payment_ready = true
		set_status("Laundry delivered. INTERACT again to collect payment.")
		return
	set_status("Bring finished laundry here for collection.")

func interact_generator():
	if generator_on:
		generator_on = false
		set_status("Generator switched OFF.")
		return
	if fuel <= 0.0:
		set_status("Generator has no fuel. Walk to BUY FUEL.")
		return
	generator_on = true
	if grid_on:
		set_status("Generator ON while NEPA/PHCN is available - fuel is being wasted.")
	else:
		set_status("Generator ON. Machines can run again.")

func interact_fuel():
	if fuel >= FUEL_MAX - 0.1:
		set_status("Generator tank is already full.")
		return
	if cash < FUEL_COST:
		set_status("You need N%d business cash to buy fuel." % FUEL_COST)
		return
	cash -= FUEL_COST
	fuel_spent += FUEL_COST
	fuel = min(FUEL_MAX, fuel + FUEL_BUY)
	set_status("Fuel purchased for N%d." % FUEL_COST)

func next_destination(stage):
	if stage == "dirty":
		return "WASHER"
	if stage == "washed":
		return "DRYER"
	if stage == "dried":
		return "IRONING"
	if stage == "ironed":
		return "COLLECTION"
	return "DROP-OFF"

func station_title(machine):
	if machine == "washer":
		return "WASHER"
	if machine == "dryer":
		return "DRYER"
	if machine == "iron":
		return "IRONING"
	return machine.to_upper()

func process_progress():
	if processing_station == "" or process_total <= 0.0:
		return 0.0
	return clamp(1.0 - process_left / process_total, 0.0, 1.0)

func set_status(text):
	if status_label != null:
		status_label.text = text

func refresh_hud():
	if cash_label == null:
		return
	cash_label.text = "CASH  N%d" % cash
	timer_label.text = "SHIFT  %02d:%02d" % [int(time_left) / 60, int(time_left) % 60]
	if grid_on:
		power_label.text = "NEPA/PHCN: ON"
	else:
		power_label.text = "NEPA/PHCN: OFF"
	fuel_label.text = "GEN: %s  FUEL: %d%%" % [("ON" if generator_on else "OFF"), int(fuel)]
	objective_label.text = objective_text()

func objective_text():
	if payment_ready:
		return "OBJECTIVE: Collect customer payment"
	if carry_stage != "":
		return "CARRYING: " + carry_stage.to_upper() + " -> " + next_destination(carry_stage)
	if processing_station != "":
		if has_power():
			return station_title(processing_station) + ": RUNNING"
		return station_title(processing_station) + ": PAUSED - NO POWER"
	if washer_output != "":
		return "OBJECTIVE: Collect laundry from WASHER"
	if dryer_output != "":
		return "OBJECTIVE: Collect laundry from DRYER"
	if iron_output != "":
		return "OBJECTIVE: Collect laundry from IRONING"
	if dirty_waiting:
		return "OBJECTIVE: Collect dirty laundry at DROP-OFF"
	return "OBJECTIVE: Run your laundry shop"

func end_shift():
	shift_over = true
	generator_on = false
	move_vector = Vector2.ZERO
	result_panel.visible = true
	result_label.text = "SHIFT COMPLETE!\n\nCustomers served: %d\nGross earned: N%d\nFuel spent: N%d\nBusiness cash: N%d" % [served, gross_earned, fuel_spent, cash]

func restart_game():
	player_pos = Vector2(360, 825)
	move_vector = Vector2.ZERO
	joystick_knob = Vector2.ZERO
	carry_stage = ""
	processing_station = ""
	process_left = 0.0
	washer_output = ""
	dryer_output = ""
	iron_output = ""
	dirty_waiting = true
	customer_present = true
	payment_ready = false
	next_customer_timer = -1.0
	cash = 0
	gross_earned = 0
	fuel_spent = 0
	served = 0
	time_left = SHIFT_LENGTH
	shift_over = false
	grid_on = true
	grid_timer = randf_range(20.0, 30.0)
	generator_on = false
	fuel = FUEL_START
	result_panel.visible = false
	set_status("Customer waiting at DROP-OFF. Walk over and collect the laundry.")
	refresh_hud()
	queue_redraw()

func _draw():
	draw_rect(Rect2(0, 145, 720, 845), Color("243142"))
	draw_rect(Rect2(SHOP_LEFT, SHOP_TOP, SHOP_RIGHT - SHOP_LEFT, SHOP_BOTTOM - SHOP_TOP), Color("d8c9ad"))
	draw_rect(Rect2(54, 175, 612, 765), Color("efe4cf"), false, 5.0)

	draw_station(DROP_OFF, Vector2(150, 92), Color("d97706"), "DROP-OFF", dirty_waiting)
	draw_station(WASHER, Vector2(160, 130), Color("2563eb"), "WASHER", washer_output != "" or processing_station == "washer")
	draw_station(DRYER, Vector2(160, 130), Color("0891b2"), "DRYER", dryer_output != "" or processing_station == "dryer")
	draw_station(IRON, Vector2(160, 130), Color("db2777"), "IRONING", iron_output != "" or processing_station == "iron")
	draw_station(COLLECTION, Vector2(160, 130), Color("16a34a"), "COLLECTION", payment_ready)
	draw_station(GENERATOR, Vector2(145, 90), Color("4b5563"), "GENERATOR", generator_on)
	draw_station(FUEL_POINT, Vector2(145, 90), Color("a16207"), "BUY FUEL", fuel < FUEL_MAX)

	if customer_present:
		draw_circle(Vector2(120, 185), 28, Color("7c3aed"))
		draw_circle(Vector2(120, 166), 13, Color("f1c7a5"))
		draw_centered_text(Vector2(120, 225), "CUSTOMER", 15, Color("3b215e"))

	draw_circle(player_pos, 28, Color("f97316"))
	draw_circle(player_pos + Vector2(0, -10), 11, Color("f8d3b4"))
	draw_centered_text(player_pos + Vector2(0, 49), "YOU", 15, Color("1f2937"))

	if carry_stage != "":
		draw_rect(Rect2(player_pos.x - 24, player_pos.y - 54, 48, 26), Color("8b5a2b"))
		draw_centered_text(player_pos + Vector2(0, -61), carry_stage.to_upper(), 12, Color("111827"))

	draw_circle(JOYSTICK_CENTER, JOYSTICK_RADIUS, Color(0.35, 0.42, 0.50, 0.25))
	draw_circle(JOYSTICK_CENTER + joystick_knob, 38, Color(0.75, 0.80, 0.86, 0.72))

func draw_station(center, size, color, label, active):
	var rect = Rect2(center - size / 2.0, size)
	draw_rect(rect, color)
	if active:
		draw_rect(rect, Color("ffffff"), false, 4.0)
	else:
		draw_rect(rect, Color("111827"), false, 4.0)
	draw_centered_text(center + Vector2(0, 5), label, 17, Color.WHITE)

	if label == "WASHER" and processing_station == "washer":
		draw_progress(center)
	elif label == "DRYER" and processing_station == "dryer":
		draw_progress(center)
	elif label == "IRONING" and processing_station == "iron":
		draw_progress(center)

func draw_progress(center):
	var bar = Rect2(center.x - 55, center.y + 36, 110, 11)
	draw_rect(bar, Color(0.1, 0.1, 0.1, 0.55))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * process_progress(), bar.size.y)), Color("facc15"))

func draw_centered_text(pos, text, font_size, color):
	var font = ThemeDB.fallback_font
	var width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, pos - Vector2(width / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func interaction_position(key):
	if key == "dropoff":
		return DROP_OFF
	if key == "washer":
		return WASHER
	if key == "dryer":
		return DRYER
	if key == "iron":
		return IRON
	if key == "collection":
		return COLLECTION
	if key == "generator":
		return GENERATOR
	if key == "fuel":
		return FUEL_POINT
	return Vector2.ZERO
