extends Node2D

const SHIFT_LENGTH := 150.0
const PLAYER_SPEED := 280.0
const INTERACT_DISTANCE := 105.0
const PROCESS_TIME := {"washer": 5.0, "dryer": 4.5, "iron": 4.0}
const PAYOUT := 180
const FUEL_MAX := 100.0
const FUEL_START := 65.0
const FUEL_DRAIN_PER_SECOND := 2.2
const FUEL_REFILL_AMOUNT := 50.0
const FUEL_REFILL_COST := 100

const SHOP_RECT := Rect2(36, 150, 648, 825)
const DROP_OFF := Vector2(120, 270)
const WASHER := Vector2(185, 485)
const DRYER := Vector2(535, 485)
const IRON := Vector2(185, 720)
const COLLECTION := Vector2(535, 720)
const GENERATOR := Vector2(115, 900)
const FUEL_POINT := Vector2(605, 900)
const JOYSTICK_CENTER := Vector2(145, 1135)
const JOYSTICK_RADIUS := 86.0

var player_pos := Vector2(360, 825)
var move_vector := Vector2.ZERO
var carry_stage := ""
var station_output := {"washer": "", "dryer": "", "iron": ""}
var processing_station := ""
var process_left := 0.0
var process_total := 1.0

var customer_present := true
var dirty_order_waiting := true
var payment_ready := false
var next_customer_timer := -1.0

var cash := 0
var gross_earned := 0
var fuel_spent := 0
var served := 0
var time_left := SHIFT_LENGTH
var shift_over := false

var grid_power_on := true
var grid_timer := 22.0
var generator_on := false
var fuel := FUEL_START

var joystick_touch := -1
var joystick_knob := Vector2.ZERO

var cash_label: Label
var timer_label: Label
var power_label: Label
var fuel_label: Label
var status_label: Label
var objective_label: Label
var interact_button: Button
var result_panel: PanelContainer
var result_label: Label

func _ready() -> void:
	randomize()
	grid_timer = randf_range(20.0, 30.0)
	build_hud()
	set_status("Customer waiting at DROP-OFF. Walk over and collect the laundry.")
	queue_redraw()

func _process(delta: float) -> void:
	if shift_over:
		return

	time_left = maxf(0.0, time_left - delta)
	update_grid_power(delta)
	update_generator(delta)
	update_processing(delta)
	update_customer_cycle(delta)
	update_player(delta)
	refresh_hud()
	queue_redraw()

	if time_left <= 0.0:
		end_shift()

func update_player(delta: float) -> void:
	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): keyboard.x -= 1.0
	if Input.is_key_pressed(KEY_D): keyboard.x += 1.0
	if Input.is_key_pressed(KEY_W): keyboard.y -= 1.0
	if Input.is_key_pressed(KEY_S): keyboard.y += 1.0
	keyboard = keyboard.limit_length(1.0)
	var direction := keyboard if keyboard.length() > 0.05 else move_vector
	player_pos += direction.limit_length(1.0) * PLAYER_SPEED * delta
	player_pos.x = clampf(player_pos.x, SHOP_RECT.position.x + 24.0, SHOP_RECT.end.x - 24.0)
	player_pos.y = clampf(player_pos.y, SHOP_RECT.position.y + 24.0, SHOP_RECT.end.y - 24.0)

func update_grid_power(delta: float) -> void:
	grid_timer -= delta
	if grid_timer > 0.0:
		return
	grid_power_on = not grid_power_on
	if grid_power_on:
		grid_timer = randf_range(22.0, 34.0)
		set_status("NEPA/PHCN is back. Switch the generator OFF if it is running.")
	else:
		grid_timer = randf_range(14.0, 22.0)
		if has_machine_power():
			set_status("NEPA/PHCN is OFF. Generator is keeping the machines running.")
		else:
			set_status("BLACKOUT! Walk to the generator and switch it ON.")

func update_generator(delta: float) -> void:
	if not generator_on:
		return
	fuel = maxf(0.0, fuel - FUEL_DRAIN_PER_SECOND * delta)
	if fuel <= 0.0:
		fuel = 0.0
		generator_on = false
		set_status("Generator fuel finished. Walk to BUY FUEL or wait for NEPA/PHCN.")

func update_processing(delta: float) -> void:
	if processing_station == "":
		return
	if not has_machine_power():
		return
	process_left -= delta
	if process_left > 0.0:
		return

	var output := ""
	match processing_station:
		"washer": output = "washed"
		"dryer": output = "dried"
		"iron": output = "ironed"
	station_output[processing_station] = output
	set_status("%s finished. Walk back and collect the basket." % station_name(processing_station))
	processing_station = ""
	process_left = 0.0

func update_customer_cycle(delta: float) -> void:
	if next_customer_timer < 0.0:
		return
	next_customer_timer -= delta
	if next_customer_timer <= 0.0:
		customer_present = true
		dirty_order_waiting = true
		next_customer_timer = -1.0
		set_status("A new customer has arrived at DROP-OFF.")

func has_machine_power() -> bool:
	return grid_power_on or (generator_on and fuel > 0.0)

func build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var top_bg := ColorRect.new()
	top_bg.color = Color("111827")
	top_bg.position = Vector2.ZERO
	top_bg.size = Vector2(720, 145)
	canvas.add_child(top_bg)

	var title := Label.new()
	title.text = "LAUNDRY RUSH  •  V0.2 SHOP"
	title.position = Vector2(24, 14)
	title.size = Vector2(672, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	canvas.add_child(title)

	cash_label = Label.new(); cash_label.position = Vector2(28, 58); cash_label.size = Vector2(210, 30); cash_label.add_theme_font_size_override("font_size", 19); canvas.add_child(cash_label)
	timer_label = Label.new(); timer_label.position = Vector2(255, 58); timer_label.size = Vector2(190, 30); timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; timer_label.add_theme_font_size_override("font_size", 19); canvas.add_child(timer_label)
	power_label = Label.new(); power_label.position = Vector2(462, 55); power_label.size = Vector2(230, 30); power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; power_label.add_theme_font_size_override("font_size", 17); canvas.add_child(power_label)
	fuel_label = Label.new(); fuel_label.position = Vector2(462, 84); fuel_label.size = Vector2(230, 30); fuel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; fuel_label.add_theme_font_size_override("font_size", 17); canvas.add_child(fuel_label)

	objective_label = Label.new()
	objective_label.position = Vector2(26, 106)
	objective_label.size = Vector2(668, 30)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 16)
	canvas.add_child(objective_label)

	var bottom_bg := ColorRect.new()
	bottom_bg.color = Color(0.05, 0.08, 0.12, 0.92)
	bottom_bg.position = Vector2(0, 990)
	bottom_bg.size = Vector2(720, 290)
	canvas.add_child(bottom_bg)

	status_label = Label.new()
	status_label.position = Vector2(235, 1006)
	status_label.size = Vector2(450, 72)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 17)
	canvas.add_child(status_label)

	interact_button = Button.new()
	interact_button.text = "INTERACT"
	interact_button.position = Vector2(500, 1100)
	interact_button.size = Vector2(185, 105)
	interact_button.add_theme_font_size_override("font_size", 22)
	interact_button.pressed.connect(try_interact)
	canvas.add_child(interact_button)

	var hint := Label.new()
	hint.text = "Move with joystick / WASD"
	hint.position = Vector2(245, 1215)
	hint.size = Vector2(440, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 15)
	canvas.add_child(hint)

	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.position = Vector2(80, 405)
	result_panel.size = Vector2(560, 390)
	canvas.add_child(result_panel)
	var box := VBoxContainer.new(); box.alignment = BoxContainer.ALIGNMENT_CENTER; box.add_theme_constant_override("separation", 22); result_panel.add_child(box)
	result_label = Label.new(); result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; result_label.add_theme_font_size_override("font_size", 24); box.add_child(result_label)
	var restart := Button.new(); restart.text = "PLAY ANOTHER SHIFT"; restart.custom_minimum_size = Vector2(390, 76); restart.add_theme_font_size_override("font_size", 20); restart.pressed.connect(restart_game); box.add_child(restart)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		try_interact()
		return

	if event is InputEventScreenTouch:
		if event.pressed and event.position.distance_to(JOYSTICK_CENTER) <= JOYSTICK_RADIUS * 1.6 and joystick_touch == -1:
			joystick_touch = event.index
			set_joystick(event.position)
		elif not event.pressed and event.index == joystick_touch:
			joystick_touch = -1
			move_vector = Vector2.ZERO
			joystick_knob = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == joystick_touch:
		set_joystick(event.position)

func set_joystick(pos: Vector2) -> void:
	var delta := pos - JOYSTICK_CENTER
	joystick_knob = delta.limit_length(JOYSTICK_RADIUS)
	move_vector = joystick_knob / JOYSTICK_RADIUS
	queue_redraw()

func try_interact() -> void:
	if shift_over:
		return
	var target := nearest_interaction()
	match target:
		"dropoff": interact_dropoff()
		"washer": interact_machine("washer")
		"dryer": interact_machine("dryer")
		"iron": interact_machine("iron")
		"collection": interact_collection()
		"generator": interact_generator()
		"fuel": interact_fuel()
		_:
			set_status("Move closer to a workstation, customer counter, generator or fuel point.")

func nearest_interaction() -> String:
	var points := {
		"dropoff": DROP_OFF,
		"washer": WASHER,
		"dryer": DRYER,
		"iron": IRON,
		"collection": COLLECTION,
		"generator": GENERATOR,
		"fuel": FUEL_POINT
	}
	var best := ""
	var best_dist := INTERACT_DISTANCE
	for key in points:
		var d: float = player_pos.distance_to(points[key])
		if d < best_dist:
			best_dist = d
			best = key
	return best

func interact_dropoff() -> void:
	if payment_ready:
		set_status("Finish the current order by collecting payment first.")
		return
	if carry_stage != "":
		set_status("Your hands are full. Take this basket to the correct station.")
		return
	if dirty_order_waiting:
		dirty_order_waiting = false
		carry_stage = "dirty"
		set_status("DIRTY laundry collected. Take it to the WASHER.")
	else:
		set_status("No laundry waiting at drop-off right now.")

func interact_machine(machine: String) -> void:
	if station_output[machine] != "":
		if carry_stage != "":
			set_status("Your hands are full. Deliver your current basket first.")
			return
		carry_stage = station_output[machine]
		station_output[machine] = ""
		set_status("Basket collected from %s. Next: %s." % [station_name(machine), next_destination(carry_stage)])
		return

	if processing_station == machine:
		if has_machine_power():
			set_status("%s is still running: %d%% complete." % [station_name(machine), int(process_progress() * 100.0)])
		else:
			set_status("%s is paused because there is no electricity." % station_name(machine))
		return
	if processing_station != "":
		set_status("Another machine is currently processing this order.")
		return
	if carry_stage == "":
		set_status("You are not carrying any laundry.")
		return

	var required := {"washer": "dirty", "dryer": "washed", "iron": "dried"}[machine]
	if carry_stage != required:
		set_status("Wrong station. This basket needs %s." % next_destination(carry_stage))
		return
	if not has_machine_power():
		set_status("No electricity. Walk to the GENERATOR or wait for NEPA/PHCN.")
		return

	carry_stage = ""
	processing_station = machine
	process_total = PROCESS_TIME[machine]
	process_left = process_total
	set_status("%s started. You can move while it processes." % station_name(machine))

func interact_collection() -> void:
	if payment_ready:
		cash += PAYOUT
		gross_earned += PAYOUT
		payment_ready = false
		served += 1
		customer_present = false
		next_customer_timer = 3.0
		set_status("Payment collected: +₦%d. New customer arriving soon." % PAYOUT)
		return
	if carry_stage == "ironed":
		carry_stage = ""
		payment_ready = true
		set_status("Clean laundry delivered. INTERACT again at COLLECTION to collect payment.")
		return
	if carry_stage != "":
		set_status("This basket is not ready. It still needs %s." % next_destination(carry_stage))
	else:
		set_status("Bring the finished laundry here for customer collection.")

func interact_generator() -> void:
	if generator_on:
		generator_on = false
		set_status("Generator switched OFF.")
		return
	if fuel <= 0.0:
		set_status("Generator has no fuel. Walk to BUY FUEL.")
		return
	generator_on = true
	if grid_power_on:
		set_status("Generator ON while NEPA/PHCN is available — fuel is being wasted.")
	else:
		set_status("Generator ON. Machines can run again.")

func interact_fuel() -> void:
	if fuel >= FUEL_MAX - 0.1:
		set_status("Generator tank is already full.")
		return
	if cash < FUEL_REFILL_COST:
		set_status("You need ₦%d business cash to buy fuel." % FUEL_REFILL_COST)
		return
	cash -= FUEL_REFILL_COST
	fuel_spent += FUEL_REFILL_COST
	fuel = minf(FUEL_MAX, fuel + FUEL_REFILL_AMOUNT)
	set_status("Bought %d%% fuel for ₦%d." % [int(FUEL_REFILL_AMOUNT), FUEL_REFILL_COST])

func station_name(machine: String) -> String:
	match machine:
		"washer": return "WASHER"
		"dryer": return "DRYER"
		"iron": return "IRONING"
	return machine.to_upper()

func next_destination(stage: String) -> String:
	match stage:
		"dirty": return "WASHER"
		"washed": return "DRYER"
		"dried": return "IRONING"
		"ironed": return "COLLECTION"
	return "DROP-OFF"

func process_progress() -> float:
	if processing_station == "" or process_total <= 0.0:
		return 0.0
	return clampf(1.0 - process_left / process_total, 0.0, 1.0)

func set_status(text: String) -> void:
	if status_label:
		status_label.text = text

func refresh_hud() -> void:
	cash_label.text = "CASH  ₦%d" % cash
	timer_label.text = "SHIFT  %02d:%02d" % [int(time_left) / 60, int(time_left) % 60]
	power_label.text = "NEPA/PHCN: ON" if grid_power_on else "NEPA/PHCN: OFF"
	fuel_label.text = "GEN: %s   FUEL: %d%%" % ["ON" if generator_on else "OFF", int(fuel)]
	objective_label.text = objective_text()

func objective_text() -> String:
	if payment_ready:
		return "OBJECTIVE: Collect customer payment"
	if carry_stage != "":
		return "CARRYING: %s  →  %s" % [carry_stage.to_upper(), next_destination(carry_stage)]
	if processing_station != "":
		var power_note := "RUNNING" if has_machine_power() else "PAUSED — NO POWER"
		return "%s: %d%%  •  %s" % [station_name(processing_station), int(process_progress() * 100.0), power_note]
	for machine in ["washer", "dryer", "iron"]:
		if station_output[machine] != "":
			return "OBJECTIVE: Collect laundry from %s" % station_name(machine)
	if dirty_order_waiting:
		return "OBJECTIVE: Collect dirty laundry at DROP-OFF"
	if next_customer_timer >= 0.0:
		return "OBJECTIVE: New customer arriving..."
	return "OBJECTIVE: Run your laundry shop"

func end_shift() -> void:
	shift_over = true
	generator_on = false
	move_vector = Vector2.ZERO
	result_panel.visible = true
	result_label.text = "SHIFT COMPLETE!\n\nCustomers served: %d\nGross earned: ₦%d\nFuel spent: ₦%d\nBusiness cash: ₦%d" % [served, gross_earned, fuel_spent, cash]

func restart_game() -> void:
	player_pos = Vector2(360, 825)
	move_vector = Vector2.ZERO
	joystick_knob = Vector2.ZERO
	carry_stage = ""
	station_output = {"washer": "", "dryer": "", "iron": ""}
	processing_station = ""
	process_left = 0.0
	customer_present = true
	dirty_order_waiting = true
	payment_ready = false
	next_customer_timer = -1.0
	cash = 0
	gross_earned = 0
	fuel_spent = 0
	served = 0
	time_left = SHIFT_LENGTH
	shift_over = false
	grid_power_on = true
	grid_timer = randf_range(20.0, 30.0)
	generator_on = false
	fuel = FUEL_START
	result_panel.visible = false
	set_status("Customer waiting at DROP-OFF. Walk over and collect the laundry.")
	refresh_hud()
	queue_redraw()

func _draw() -> void:
	# Shop floor
	draw_rect(Rect2(0, 145, 720, 845), Color("243142"))
	draw_rect(SHOP_RECT, Color("d8c9ad"))
	draw_rect(Rect2(54, 175, 612, 765), Color("efe4cf"), false, 5.0)

	# Decorative aisle lines
	for y in [380.0, 610.0, 825.0]:
		draw_line(Vector2(70, y), Vector2(650, y), Color(0.65, 0.55, 0.42, 0.28), 3.0)

	draw_station(DROP_OFF, Vector2(150, 92), Color("d97706"), "DROP-OFF", dirty_order_waiting)
	draw_station(WASHER, Vector2(160, 130), Color("2563eb"), "WASHER", station_output["washer"] != "" or processing_station == "washer")
	draw_station(DRYER, Vector2(160, 130), Color("0891b2"), "DRYER", station_output["dryer"] != "" or processing_station == "dryer")
	draw_station(IRON, Vector2(160, 130), Color("db2777"), "IRONING", station_output["iron"] != "" or processing_station == "iron")
	draw_station(COLLECTION, Vector2(160, 130), Color("16a34a"), "COLLECTION", payment_ready)
	draw_station(GENERATOR, Vector2(145, 90), Color("4b5563"), "GENERATOR", generator_on)
	draw_station(FUEL_POINT, Vector2(145, 90), Color("a16207"), "BUY FUEL", fuel < FUEL_MAX)

	# Customer
	if customer_present:
		draw_circle(Vector2(120, 185), 28, Color("7c3aed"))
		draw_circle(Vector2(120, 166), 13, Color("f1c7a5"))
		draw_centered_text(Vector2(120, 225), "CUSTOMER", 15, Color("3b215e"))

	# Player and carried basket
	draw_circle(player_pos, 28, Color("f97316"))
	draw_circle(player_pos + Vector2(0, -10), 11, Color("f8d3b4"))
	draw_centered_text(player_pos + Vector2(0, 49), "YOU", 15, Color("1f2937"))
	if carry_stage != "":
		draw_rect(Rect2(player_pos.x - 24, player_pos.y - 54, 48, 26), Color("8b5a2b"))
		draw_centered_text(player_pos + Vector2(0, -61), carry_stage.to_upper(), 12, Color("111827"))

	# Joystick
	draw_circle(JOYSTICK_CENTER, JOYSTICK_RADIUS, Color(0.35, 0.42, 0.50, 0.25))
	draw_circle(JOYSTICK_CENTER + joystick_knob, 38, Color(0.75, 0.80, 0.86, 0.72))

	# Interaction radius hint around nearest target
	var nearest := nearest_interaction()
	if nearest != "":
		var p := interaction_position(nearest)
		draw_arc(p, 58.0, 0.0, TAU, 40, Color(1, 1, 1, 0.65), 3.0)

func draw_station(center: Vector2, size: Vector2, color: Color, label: String, active: bool) -> void:
	var rect := Rect2(center - size / 2.0, size)
	draw_rect(rect, color)
	draw_rect(rect, Color("ffffff") if active else Color("111827"), false, 4.0)
	draw_centered_text(center + Vector2(0, 5), label, 17, Color.WHITE)
	if label in ["WASHER", "DRYER", "IRONING"]:
		var machine_key := "washer" if label == "WASHER" else ("dryer" if label == "DRYER" else "iron")
		if processing_station == machine_key:
			var bar := Rect2(center.x - 55, center.y + 36, 110, 11)
			draw_rect(bar, Color(0.1, 0.1, 0.1, 0.55))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * process_progress(), bar.size.y)), Color("facc15"))
		elif station_output[machine_key] != "":
			draw_centered_text(center + Vector2(0, 42), "READY", 14, Color("fef08a"))
	if label == "GENERATOR":
		draw_centered_text(center + Vector2(0, 31), "ON" if generator_on else "OFF", 13, Color("fef08a"))
	if label == "BUY FUEL":
		draw_centered_text(center + Vector2(0, 31), "₦%d" % FUEL_REFILL_COST, 13, Color("fef08a"))

func draw_centered_text(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, pos - Vector2(width / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func interaction_position(key: String) -> Vector2:
	match key:
		"dropoff": return DROP_OFF
		"washer": return WASHER
		"dryer": return DRYER
		"iron": return IRON
		"collection": return COLLECTION
		"generator": return GENERATOR
		"fuel": return FUEL_POINT
	return Vector2.ZERO
