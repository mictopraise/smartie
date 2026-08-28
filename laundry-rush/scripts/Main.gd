extends Control

const SHIFT_LENGTH := 90.0
const PROCESS_TIME := {"wash": 2.5, "dry": 2.2, "iron": 1.8}
const PAYOUT := 120

var cash := 0
var served := 0
var missed := 0
var time_left := SHIFT_LENGTH
var power_on := true
var shift_over := false
var load_stage := "waiting"
var processing := false
var process_left := 0.0
var process_stage := ""
var queue_count := 3
var spawn_left := 7.0

var cash_label: Label
var timer_label: Label
var queue_label: Label
var status_label: Label
var progress: ProgressBar
var wash_button: Button
var dry_button: Button
var iron_button: Button
var power_button: Button
var result_panel: PanelContainer
var result_label: Label

func _ready() -> void:
	build_ui()
	refresh_ui()

func _process(delta: float) -> void:
	if shift_over:
		return
	time_left = maxf(0.0, time_left - delta)
	spawn_left -= delta
	if spawn_left <= 0.0:
		queue_count = mini(queue_count + 1, 6)
		spawn_left = randf_range(5.5, 8.5)
	if processing and power_on:
		process_left -= delta
		progress.value = 100.0 * (1.0 - process_left / PROCESS_TIME[process_stage])
		if process_left <= 0.0:
			finish_stage()
	if time_left <= 0.0:
		end_shift()
	refresh_ui()

func build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0e1624")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	root.offset_left = 28
	root.offset_right = -28
	root.offset_top = 30
	root.offset_bottom = -30
	add_child(root)

	var title := Label.new()
	title.text = "🧺 LAUNDRY RUSH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	root.add_child(title)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 24)
	root.add_child(top)
	cash_label = Label.new(); cash_label.add_theme_font_size_override("font_size", 22); top.add_child(cash_label)
	timer_label = Label.new(); timer_label.add_theme_font_size_override("font_size", 22); top.add_child(timer_label)

	var customer_panel := PanelContainer.new()
	customer_panel.custom_minimum_size = Vector2(0, 160)
	root.add_child(customer_panel)
	var customer_box := VBoxContainer.new()
	customer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	customer_panel.add_child(customer_box)
	var customer_title := Label.new(); customer_title.text = "CUSTOMER QUEUE"; customer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; customer_title.add_theme_font_size_override("font_size", 20); customer_box.add_child(customer_title)
	queue_label = Label.new(); queue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; queue_label.add_theme_font_size_override("font_size", 34); customer_box.add_child(queue_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 70)
	status_label.add_theme_font_size_override("font_size", 20)
	root.add_child(status_label)

	progress = ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.value = 0
	progress.custom_minimum_size = Vector2(0, 28)
	root.add_child(progress)

	var stations := HBoxContainer.new()
	stations.alignment = BoxContainer.ALIGNMENT_CENTER
	stations.add_theme_constant_override("separation", 12)
	root.add_child(stations)
	wash_button = make_station("🫧\nWASH", "wash"); stations.add_child(wash_button)
	dry_button = make_station("💨\nDRY", "dry"); stations.add_child(dry_button)
	iron_button = make_station("♨️\nIRON", "iron"); stations.add_child(iron_button)

	power_button = Button.new()
	power_button.custom_minimum_size = Vector2(0, 76)
	power_button.add_theme_font_size_override("font_size", 22)
	power_button.pressed.connect(toggle_power)
	root.add_child(power_button)

	var hint := Label.new()
	hint.text = "Complete the clothes in order: WASH → DRY → IRON → PAYMENT"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint)

	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.position = Vector2(80, 390)
	result_panel.size = Vector2(560, 360)
	add_child(result_panel)
	var result_box := VBoxContainer.new(); result_box.alignment = BoxContainer.ALIGNMENT_CENTER; result_box.add_theme_constant_override("separation", 18); result_panel.add_child(result_box)
	result_label = Label.new(); result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; result_label.add_theme_font_size_override("font_size", 24); result_box.add_child(result_label)
	var restart := Button.new(); restart.text = "PLAY ANOTHER SHIFT"; restart.custom_minimum_size = Vector2(360, 70); restart.pressed.connect(restart_game); result_box.add_child(restart)

func make_station(text: String, stage: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(190, 150)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func(): start_stage(stage))
	return b

func start_stage(stage: String) -> void:
	if shift_over or processing:
		return
	if not power_on:
		status_label.text = "⚡ No power! Start the generator first."
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
			served += 1
			status_label.text = "💵 Customer served! +₦%d" % PAYOUT
	process_stage = ""

func toggle_power() -> void:
	if shift_over:
		return
	power_on = not power_on
	status_label.text = "⚡ Generator ON — machines running." if power_on else "🌑 Power OFF — machines paused."
	refresh_ui()

func refresh_ui() -> void:
	cash_label.text = "💰 ₦%d" % cash
	timer_label.text = "⏱ %02d:%02d" % [int(time_left) / 60, int(time_left) % 60]
	queue_label.text = "👤 " + "👤 ".repeat(queue_count)
	power_button.text = "⚡ GENERATOR: ON" if power_on else "🌑 GENERATOR: OFF"
	wash_button.disabled = processing or shift_over
	dry_button.disabled = processing or shift_over
	iron_button.disabled = processing or shift_over

func end_shift() -> void:
	shift_over = true
	processing = false
	result_panel.visible = true
	result_label.text = "SHIFT COMPLETE!\n\nCustomers served: %d\nCash earned: ₦%d\nQueue remaining: %d" % [served, cash, queue_count]

func restart_game() -> void:
	cash = 0
	served = 0
	missed = 0
	time_left = SHIFT_LENGTH
	power_on = true
	shift_over = false
	load_stage = "waiting"
	processing = false
	process_left = 0.0
	process_stage = ""
	queue_count = 3
	spawn_left = 7.0
	progress.value = 0
	result_panel.visible = false
	status_label.text = "A customer is ready. Start with WASH!"
	refresh_ui()
