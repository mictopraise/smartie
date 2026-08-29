extends Control

const SHIFT_LENGTH := 90.0
const PROCESS_TIME := {"wash": 2.5, "dry": 2.2, "iron": 1.8}
const PAYOUT := 120
const FUEL_MAX := 100.0
const FUEL_START := 65.0
const FUEL_DRAIN_PER_SECOND := 2.5
const FUEL_REFILL_AMOUNT := 50.0
const FUEL_REFILL_COST := 100

var cash := 0
var gross_earned := 0
var fuel_spent := 0
var served := 0
var missed := 0
var time_left := SHIFT_LENGTH
var shift_over := false
var load_stage := "waiting"
var processing := false
var process_left := 0.0
var process_stage := ""
var queue_count := 3
var spawn_left := 7.0

var grid_power_on := true
var grid_timer := 24.0
var generator_on := false
var fuel := FUEL_START

var cash_label: Label
var timer_label: Label
var queue_label: Label
var grid_label: Label
var fuel_label: Label
var status_label: Label
var progress: ProgressBar
var wash_button: Button
var dry_button: Button
var iron_button: Button
var generator_button: Button
var fuel_button: Button
var result_panel: PanelContainer
var result_label: Label

func _ready() -> void:
	randomize()
	grid_timer = randf_range(20.0, 32.0)
	build_ui()
	status_label.text = "NEPA light is ON. A customer is ready — start with WASH!"
	refresh_ui()

func _process(delta: float) -> void:
	if shift_over:
		return

	time_left = maxf(0.0, time_left - delta)
	spawn_left -= delta
	if spawn_left <= 0.0:
		queue_count = mini(queue_count + 1, 6)
		spawn_left = randf_range(5.5, 8.5)

	update_grid_power(delta)
	update_generator(delta)

	if processing and has_machine_power():
		process_left -= delta
		progress.value = 100.0 * (1.0 - process_left / PROCESS_TIME[process_stage])
		if process_left <= 0.0:
			finish_stage()

	if time_left <= 0.0:
		end_shift()

	refresh_ui()

func update_grid_power(delta: float) -> void:
	grid_timer -= delta
	if grid_timer > 0.0:
		return

	grid_power_on = not grid_power_on
	if grid_power_on:
		grid_timer = randf_range(20.0, 34.0)
		status_label.text = "💡 NEPA light is back! Switch generator OFF to save fuel."
	else:
		grid_timer = randf_range(12.0, 22.0)
		if generator_on and fuel > 0.0:
			status_label.text = "🌑 NEPA light OFF — generator is keeping the shop running."
		else:
			status_label.text = "🌑 NEPA light OFF! Start the generator to continue working."

func update_generator(delta: float) -> void:
	if not generator_on:
		return

	fuel = maxf(0.0, fuel - FUEL_DRAIN_PER_SECOND * delta)
	if fuel <= 0.0:
		fuel = 0.0
		generator_on = false
		if not grid_power_on:
			status_label.text = "⛽ Generator fuel finished! Buy fuel or wait for NEPA light."
		else:
			status_label.text = "⛽ Generator fuel finished. NEPA light is still available."

func has_machine_power() -> bool:
	return grid_power_on or (generator_on and fuel > 0.0)

func build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0e1624")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	root.offset_left = 28
	root.offset_right = -28
	root.offset_top = 24
	root.offset_bottom = -24
	add_child(root)

	var title := Label.new()
	title.text = "🧺 LAUNDRY RUSH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 24)
	root.add_child(top)
	cash_label = Label.new(); cash_label.add_theme_font_size_override("font_size", 21); top.add_child(cash_label)
	timer_label = Label.new(); timer_label.add_theme_font_size_override("font_size", 21); top.add_child(timer_label)

	var customer_panel := PanelContainer.new()
	customer_panel.custom_minimum_size = Vector2(0, 130)
	root.add_child(customer_panel)
	var customer_box := VBoxContainer.new()
	customer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	customer_panel.add_child(customer_box)
	var customer_title := Label.new(); customer_title.text = "CUSTOMER QUEUE"; customer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; customer_title.add_theme_font_size_override("font_size", 19); customer_box.add_child(customer_title)
	queue_label = Label.new(); queue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; queue_label.add_theme_font_size_override("font_size", 30); customer_box.add_child(queue_label)

	var power_panel := PanelContainer.new()
	root.add_child(power_panel)
	var power_box := VBoxContainer.new()
	power_box.add_theme_constant_override("separation", 6)
	power_panel.add_child(power_box)
	var power_title := Label.new(); power_title.text = "⚡ POWER & FUEL"; power_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; power_title.add_theme_font_size_override("font_size", 18); power_box.add_child(power_title)
	grid_label = Label.new(); grid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; grid_label.add_theme_font_size_override("font_size", 18); power_box.add_child(grid_label)
	fuel_label = Label.new(); fuel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; fuel_label.add_theme_font_size_override("font_size", 18); power_box.add_child(fuel_label)

	var power_buttons := HBoxContainer.new()
	power_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	power_buttons.add_theme_constant_override("separation", 10)
	power_box.add_child(power_buttons)
	generator_button = Button.new()
	generator_button.custom_minimum_size = Vector2(300, 62)
	generator_button.add_theme_font_size_override("font_size", 18)
	generator_button.pressed.connect(toggle_generator)
	power_buttons.add_child(generator_button)
	fuel_button = Button.new()
	fuel_button.custom_minimum_size = Vector2(300, 62)
	fuel_button.add_theme_font_size_override("font_size", 18)
	fuel_button.pressed.connect(buy_fuel)
	power_buttons.add_child(fuel_button)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 70)
	status_label.add_theme_font_size_override("font_size", 18)
	root.add_child(status_label)

	progress = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.value = 0
	progress.custom_minimum_size = Vector2(0, 24)
	root.add_child(progress)

	var stations := HBoxContainer.new()
	stations.alignment = BoxContainer.ALIGNMENT_CENTER
	stations.add_theme_constant_override("separation", 10)
	root.add_child(stations)
	wash_button = make_station("🫧\nWASH", "wash"); stations.add_child(wash_button)
	dry_button = make_station("💨\nDRY", "dry"); stations.add_child(dry_button)
	iron_button = make_station("♨️\nIRON", "iron"); stations.add_child(iron_button)

	var hint := Label.new()
	hint.text = "WASH → DRY → IRON → PAYMENT\nWhen NEPA goes off, use generator. Fuel costs money."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)

	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.position = Vector2(80, 390)
	result_panel.size = Vector2(560, 380)
	add_child(result_panel)
	var result_box := VBoxContainer.new(); result_box.alignment = BoxContainer.ALIGNMENT_CENTER; result_box.add_theme_constant_override("separation", 18); result_panel.add_child(result_box)
	result_label = Label.new(); result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; result_label.add_theme_font_size_override("font_size", 23); result_box.add_child(result_label)
	var restart := Button.new(); restart.text = "PLAY ANOTHER SHIFT"; restart.custom_minimum_size = Vector2(360, 70); restart.pressed.connect(restart_game); result_box.add_child(restart)

func make_station(text: String, stage: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(190, 132)
	b.add_theme_font_size_override("font_size", 21)
	b.pressed.connect(func(): start_stage(stage))
	return b

func start_stage(stage: String) -> void:
	if shift_over or processing:
		return
	if not has_machine_power():
		status_label.text = "⚡ No electricity. Start generator or wait for NEPA light."
		return
	if queue_count <= 0 and load_stage == "waiting":
		status_label.text = "No customer is waiting yet."
		return

	var expected := "wash" if load_stage == "waiting" else ("dry" if load_stage == "washed" else ("iron" if load_stage == "dried" else ""))
	if stage != expected:
		status_label.text = "Wrong station — this load needs %s next." % expected.to_upper()
		return
	if stage == "wash":
		queue_count -= 1
	processing = true
	process_stage = stage
	process_left = PROCESS_TIME[stage]
	progress.value = 0
	status_label.text = "%s in progress…" % stage.capitalize()

func finish_stage() -> void:
	processing = false
	progress.value = 100
	match process_stage:
		"wash":
			load_stage = "washed"
			status_label.text = "✅ Washed! Move it to the dryer."
		"dry":
			load_stage = "dried"
			status_label.text = "✅ Dry! Time to iron."
		"iron":
			load_stage = "waiting"
			cash += PAYOUT
			gross_earned += PAYOUT
			served += 1
			status_label.text = "💵 Customer served! +₦%d" % PAYOUT
	process_stage = ""

func toggle_generator() -> void:
	if shift_over:
		return
	if generator_on:
		generator_on = false
		status_label.text = "🛑 Generator OFF."
		refresh_ui()
		return
	if fuel <= 0.0:
		status_label.text = "⛽ No generator fuel. Buy fuel first."
		return
	generator_on = true
	if grid_power_on:
		status_label.text = "⚠️ Generator ON while NEPA light is available — fuel is being wasted."
	else:
		status_label.text = "⚡ Generator ON — machines are running again."
	refresh_ui()

func buy_fuel() -> void:
	if shift_over:
		return
	if fuel >= FUEL_MAX - 0.1:
		status_label.text = "⛽ Fuel tank is already full."
		return
	if cash < FUEL_REFILL_COST:
		status_label.text = "💸 You need ₦%d business cash to buy fuel." % FUEL_REFILL_COST
		return
	cash -= FUEL_REFILL_COST
	fuel_spent += FUEL_REFILL_COST
	fuel = minf(FUEL_MAX, fuel + FUEL_REFILL_AMOUNT)
	status_label.text = "⛽ Fuel purchased for ₦%d." % FUEL_REFILL_COST
	refresh_ui()

func refresh_ui() -> void:
	cash_label.text = "💰 ₦%d" % cash
	timer_label.text = "⏱ %02d:%02d" % [int(time_left) / 60, int(time_left) % 60]
	queue_label.text = "👤 " + "👤 ".repeat(queue_count)
	grid_label.text = "💡 NEPA/PHCN: ON" if grid_power_on else "🌑 NEPA/PHCN: OFF"
	fuel_label.text = "⛽ Fuel: %d%%" % int(fuel)
	generator_button.text = "⚡ GENERATOR: ON" if generator_on else "🛑 GENERATOR: OFF"
	fuel_button.text = "BUY FUEL +%d%%  ₦%d" % [int(FUEL_REFILL_AMOUNT), FUEL_REFILL_COST]
	wash_button.disabled = processing or shift_over
	dry_button.disabled = processing or shift_over
	iron_button.disabled = processing or shift_over
	fuel_button.disabled = shift_over or fuel >= FUEL_MAX - 0.1

func end_shift() -> void:
	shift_over = true
	processing = false
	generator_on = false
	result_panel.visible = true
	result_label.text = "SHIFT COMPLETE!\n\nCustomers served: %d\nGross earned: ₦%d\nFuel spent: ₦%d\nBusiness cash: ₦%d\nQueue remaining: %d" % [served, gross_earned, fuel_spent, cash, queue_count]

func restart_game() -> void:
	cash = 0
	gross_earned = 0
	fuel_spent = 0
	served = 0
	missed = 0
	time_left = SHIFT_LENGTH
	shift_over = false
	load_stage = "waiting"
	processing = false
	process_left = 0.0
	process_stage = ""
	queue_count = 3
	spawn_left = 7.0
	grid_power_on = true
	grid_timer = randf_range(20.0, 32.0)
	generator_on = false
	fuel = FUEL_START
	progress.value = 0
	result_panel.visible = false
	status_label.text = "NEPA light is ON. A customer is ready — start with WASH!"
	refresh_ui()
