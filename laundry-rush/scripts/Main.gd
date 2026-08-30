extends Node2D

const PLAYER_SPEED=310.0
const INTERACT_DISTANCE=115.0
const PAYOUT=180
const FUEL_MAX=100.0
const FUEL_DRAIN=2.2
const FUEL_COST=100
const DRAG_DEADZONE=14.0
const DRAG_MAX=120.0
const DOUBLE_TAP_WINDOW=0.34
const TAP_MOVE_TOLERANCE=24.0
const STATION_TAP_RADIUS=95.0
const SHOP_LEFT=36.0
const SHOP_TOP=150.0
const SHOP_RIGHT=684.0
const SHOP_BOTTOM=1070.0
const DROP_OFF=Vector2(120,280)
const WASHER=Vector2(185,500)
const DRYER=Vector2(535,500)
const IRON=Vector2(185,735)
const COLLECTION=Vector2(535,735)
const GENERATOR=Vector2(115,955)
const FUEL_POINT=Vector2(605,955)

var player_pos=Vector2(360,850)
var move_vector=Vector2.ZERO
var drag_touch=-1
var drag_origin=Vector2.ZERO
var drag_current=Vector2.ZERO
var last_tap_time=-10.0
var last_tap_pos=Vector2.ZERO
var carry_stage=""
var processing_station=""
var process_left=0.0
var process_total=1.0
var washer_output=""
var dryer_output=""
var iron_output=""
var dirty_waiting=true
var customer_present=true
var payment_ready=false
var next_customer_timer=-1.0
var cash=0
var served=0
var grid_on=true
var grid_timer=24.0
var generator_on=false
var fuel=65.0
var cash_label
var power_label
var fuel_label
var status_label
var objective_label

func _ready():
 randomize(); grid_timer=randf_range(20.0,30.0); build_hud(); set_status("Welcome! Serve the waiting customer."); refresh_hud(); queue_redraw()

func _process(delta):
 update_power(delta); update_processing(delta); update_customer(delta); update_player(delta); refresh_hud(); queue_redraw()

func update_player(delta):
 var keyboard=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
 if Input.is_key_pressed(KEY_A): keyboard.x-=1.0
 if Input.is_key_pressed(KEY_D): keyboard.x+=1.0
 if Input.is_key_pressed(KEY_W): keyboard.y-=1.0
 if Input.is_key_pressed(KEY_S): keyboard.y+=1.0
 var direction=keyboard.normalized() if keyboard.length()>0.05 else move_vector
 player_pos+=direction*PLAYER_SPEED*delta
 player_pos.x=clamp(player_pos.x,SHOP_LEFT+24.0,SHOP_RIGHT-24.0); player_pos.y=clamp(player_pos.y,SHOP_TOP+24.0,SHOP_BOTTOM-24.0)

func update_power(delta):
 grid_timer-=delta
 if grid_timer<=0.0:
  grid_on=not grid_on
  grid_timer=randf_range(22.0,34.0) if grid_on else randf_range(14.0,22.0)
  set_status("NEPA/PHCN is back. Switch generator off to save fuel." if grid_on else "BLACKOUT! Tap the generator to start backup power.")
 if generator_on:
  fuel=max(0.0,fuel-FUEL_DRAIN*delta)
  if fuel<=0.0: generator_on=false; set_status("Generator fuel finished. Buy fuel when you can afford it.")

func has_power(): return grid_on or (generator_on and fuel>0.0)

func update_processing(delta):
 if processing_station=="" or not has_power(): return
 process_left-=delta
 if process_left>0.0: return
 if processing_station=="washer": washer_output="washed"
 elif processing_station=="dryer": dryer_output="dried"
 elif processing_station=="iron": iron_output="ironed"
 set_status(station_title(processing_station)+" finished. Follow the READY marker."); processing_station=""; process_left=0.0

func update_customer(delta):
 if next_customer_timer<0.0: return
 next_customer_timer-=delta
 if next_customer_timer<=0.0: next_customer_timer=-1.0; customer_present=true; dirty_waiting=true; set_status("New customer at reception.")

func build_hud():
 var canvas=CanvasLayer.new(); add_child(canvas)
 var top=ColorRect.new(); top.color=Color("123047"); top.position=Vector2.ZERO; top.size=Vector2(720,145); canvas.add_child(top)
 var title=Label.new(); title.text="LAUNDRY RUSH"; title.position=Vector2(20,10); title.size=Vector2(680,42); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",30); canvas.add_child(title)
 cash_label=Label.new(); cash_label.position=Vector2(25,58); cash_label.size=Vector2(210,30); cash_label.add_theme_font_size_override("font_size",19); canvas.add_child(cash_label)
 power_label=Label.new(); power_label.position=Vector2(245,58); power_label.size=Vector2(230,30); power_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; power_label.add_theme_font_size_override("font_size",17); canvas.add_child(power_label)
 fuel_label=Label.new(); fuel_label.position=Vector2(480,58); fuel_label.size=Vector2(210,30); fuel_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; fuel_label.add_theme_font_size_override("font_size",17); canvas.add_child(fuel_label)
 objective_label=Label.new(); objective_label.position=Vector2(20,104); objective_label.size=Vector2(680,32); objective_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; objective_label.add_theme_font_size_override("font_size",16); canvas.add_child(objective_label)
 var bottom=ColorRect.new(); bottom.color=Color(0.04,0.12,0.16,0.94); bottom.position=Vector2(0,1075); bottom.size=Vector2(720,205); canvas.add_child(bottom)
 status_label=Label.new(); status_label.position=Vector2(35,1100); status_label.size=Vector2(650,78); status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; status_label.add_theme_font_size_override("font_size",18); canvas.add_child(status_label)
 var hint=Label.new(); hint.text="DRAG TO MOVE  •  DOUBLE-TAP STATIONS  •  TAP GENERATOR"; hint.position=Vector2(25,1200); hint.size=Vector2(670,35); hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_font_size_override("font_size",14); canvas.add_child(hint)

func _input(event):
 if event is InputEventKey:
  if event.pressed and event.keycode==KEY_SPACE: try_interact_near_player()
  return
 if event is InputEventScreenTouch:
  if event.pressed:
   if event.position.y<1075.0 and drag_touch==-1: drag_touch=event.index; drag_origin=event.position; drag_current=event.position; move_vector=Vector2.ZERO
  elif event.index==drag_touch:
   var release_pos=event.position; var travelled=release_pos.distance_to(drag_origin); drag_touch=-1; move_vector=Vector2.ZERO
   if travelled<=TAP_MOVE_TOLERANCE: handle_tap(release_pos)
 elif event is InputEventScreenDrag and event.index==drag_touch:
  drag_current=event.position; var d=drag_current-drag_origin; move_vector=Vector2.ZERO if d.length()<DRAG_DEADZONE else d.limit_length(DRAG_MAX)/DRAG_MAX

func handle_tap(pos):
 var target=station_at_screen_pos(pos)
 if target=="generator": interact_generator(); last_tap_time=-10.0; return
 var now=Time.get_ticks_msec()/1000.0
 if now-last_tap_time<=DOUBLE_TAP_WINDOW and pos.distance_to(last_tap_pos)<=80.0:
  if target!="": interact_named_station(target)
  else: try_interact_near_player()
  last_tap_time=-10.0
 else: last_tap_time=now; last_tap_pos=pos

func station_at_screen_pos(pos):
 var best=""; var best_dist=STATION_TAP_RADIUS
 for name in ["dropoff","washer","dryer","iron","collection","generator","fuel"]:
  var d=pos.distance_to(interaction_position(name))
  if d<best_dist: best_dist=d; best=name
 return best

func interact_named_station(target):
 if target!="generator" and player_pos.distance_to(interaction_position(target))>INTERACT_DISTANCE: set_status("Move closer before using this station."); return
 if target=="dropoff": interact_dropoff()
 elif target=="washer": interact_machine("washer")
 elif target=="dryer": interact_machine("dryer")
 elif target=="iron": interact_machine("iron")
 elif target=="collection": interact_collection()
 elif target=="generator": interact_generator()
 elif target=="fuel": interact_fuel()

func try_interact_near_player():
 var target=""; var best=INTERACT_DISTANCE
 for name in ["dropoff","washer","dryer","iron","collection","fuel"]:
  var d=player_pos.distance_to(interaction_position(name))
  if d<best: best=d; target=name
 if target=="": set_status("Move closer to a station.")
 else: interact_named_station(target)

func interact_dropoff():
 if carry_stage!="": set_status("Your hands are full."); return
 if dirty_waiting: dirty_waiting=false; carry_stage="dirty"; set_status("Laundry collected. Take it to the washer.")
 else: set_status("No laundry is waiting here.")

func interact_machine(machine):
 var output=get_machine_output(machine)
 if output!="":
  if carry_stage!="": set_status("Your hands are full."); return
  carry_stage=output; set_machine_output(machine,""); set_status("Basket collected. Next: "+next_destination(carry_stage)); return
 if processing_station==machine: set_status(station_title(machine)+" is still processing."); return
 if processing_station!="": set_status("Finish the current machine cycle first."); return
 if carry_stage=="": set_status("You are not carrying laundry."); return
 var required=""; var duration=4.0
 if machine=="washer": required="dirty"; duration=5.0
 elif machine=="dryer": required="washed"; duration=4.5
 elif machine=="iron": required="dried"; duration=4.0
 if carry_stage!=required: set_status("Wrong station. Go to "+next_destination(carry_stage)); return
 if not has_power(): set_status("No electricity. Tap generator for backup power."); return
 carry_stage=""; processing_station=machine; process_total=duration; process_left=duration; set_status(station_title(machine)+" started.")

func get_machine_output(m):
 if m=="washer": return washer_output
 if m=="dryer": return dryer_output
 if m=="iron": return iron_output
 return ""
func set_machine_output(m,v):
 if m=="washer": washer_output=v
 elif m=="dryer": dryer_output=v
 elif m=="iron": iron_output=v
func interact_collection():
 if payment_ready: cash+=PAYOUT; served+=1; payment_ready=false; customer_present=false; next_customer_timer=3.0; set_status("Payment collected: +N%d"%PAYOUT); return
 if carry_stage=="ironed": carry_stage=""; payment_ready=true; set_status("Order delivered. Collect payment."); return
 set_status("Bring finished laundry to collection.")
func interact_generator():
 if generator_on: generator_on=false; set_status("Generator switched OFF."); return
 if fuel<=0.0: set_status("No generator fuel."); return
 generator_on=true; set_status("Generator ON - fuel is being wasted." if grid_on else "Generator ON. Backup power restored.")
func interact_fuel():
 if fuel>=FUEL_MAX-0.1: set_status("Fuel tank is full."); return
 if cash<FUEL_COST: set_status("You need N%d to buy fuel."%FUEL_COST); return
 cash-=FUEL_COST; fuel=min(FUEL_MAX,fuel+50.0); set_status("Fuel purchased for N%d."%FUEL_COST)
func next_destination(s):
 if s=="dirty": return "WASHER"
 if s=="washed": return "DRYER"
 if s=="dried": return "IRONING"
 if s=="ironed": return "COLLECTION"
 return "DROP-OFF"
func station_title(m): return "IRONING" if m=="iron" else m.to_upper()
func process_progress(): return 0.0 if processing_station=="" else clamp(1.0-process_left/process_total,0.0,1.0)
func set_status(t):
 if status_label!=null: status_label.text=t
func refresh_hud():
 if cash_label==null:return
 cash_label.text="CASH  N%d"%cash; power_label.text="NEPA/PHCN: ON" if grid_on else "NEPA/PHCN: OFF"; fuel_label.text="GEN: %s  FUEL: %d%%"%[("ON" if generator_on else "OFF"),int(fuel)]; objective_label.text=objective_text()
func objective_text():
 if payment_ready:return "READY: COLLECT CUSTOMER PAYMENT"
 if carry_stage!="":return "CARRYING: "+carry_stage.to_upper()+" -> "+next_destination(carry_stage)
 if washer_output!="":return "READY: WASHER"
 if dryer_output!="":return "READY: DRYER"
 if iron_output!="":return "READY: IRONING"
 if processing_station!="":return station_title(processing_station)+(": RUNNING" if has_power() else ": PAUSED - NO POWER")
 if dirty_waiting:return "READY: CUSTOMER AT RECEPTION"
 return "RUN YOUR LAUNDRY SHOP"

func _draw():
 draw_rect(Rect2(0,145,720,930),Color("8bb8b1")); draw_rect(Rect2(36,150,648,920),Color("f3ead8"))
 # tiled shop floor
 for x in range(55,666,55): draw_line(Vector2(x,175),Vector2(x,1025),Color(0.75,0.72,0.65,0.35),1.0)
 for y in range(175,1026,55): draw_line(Vector2(55,y),Vector2(665,y),Color(0.75,0.72,0.65,0.35),1.0)
 # walls and entrance
 draw_rect(Rect2(54,174,612,14),Color("264653")); draw_rect(Rect2(54,174,14,850),Color("264653")); draw_rect(Rect2(652,174,14,850),Color("264653")); draw_rect(Rect2(54,1010,235,14),Color("264653")); draw_rect(Rect2(431,1010,235,14),Color("264653")); draw_centered_text(Vector2(360,1048),"ENTRANCE",13,Color("264653"))
 draw_reception(); draw_washer(WASHER,false); draw_washer(DRYER,true); draw_ironing(); draw_collection(); draw_generator(); draw_fuel()
 if customer_present: draw_person(Vector2(120,205),Color("7c3aed"),"CUSTOMER")
 draw_person(player_pos,Color("f97316"),"YOU")
 if carry_stage!="": draw_basket(player_pos+Vector2(0,-48),carry_stage)
 if drag_touch!=-1: draw_circle(drag_origin,30,Color(0,0,0,0.15)); draw_line(drag_origin,drag_current,Color(1,1,1,0.35),4.0)
 draw_ready_markers()

func draw_reception():
 var r=Rect2(DROP_OFF.x-75,DROP_OFF.y-42,150,84); draw_rect(r,Color("9a6337")); draw_rect(Rect2(r.position,Vector2(r.size.x,18)),Color("d9a066")); draw_centered_text(DROP_OFF+Vector2(0,8),"DROP-OFF",15,Color.WHITE); draw_basket(DROP_OFF+Vector2(48,-54),"dirty") if dirty_waiting else null
func draw_washer(p,is_dryer):
 var body=Rect2(p.x-66,p.y-58,132,116); draw_rect(body,Color("e8eef2")); draw_rect(body,Color("546e7a"),false,4.0); draw_circle(p+Vector2(0,5),38,Color("263b48")); draw_circle(p+Vector2(0,5),29,Color("91c8d8")); draw_rect(Rect2(p.x-48,p.y-45,18,8),Color("38a169" if has_power() else "d1495b")); draw_centered_text(p+Vector2(0,-70),"DRYER" if is_dryer else "WASHER",16,Color("183642"));
 if (processing_station=="dryer" and is_dryer) or (processing_station=="washer" and not is_dryer): draw_progress(p)
func draw_ironing():
 draw_rect(Rect2(IRON.x-72,IRON.y-28,144,56),Color("c6d8e4")); draw_rect(Rect2(IRON.x-58,IRON.y+28,12,46),Color("6b7280")); draw_rect(Rect2(IRON.x+46,IRON.y+28,12,46),Color("6b7280")); draw_colored_polygon(PackedVector2Array([IRON+Vector2(-12,-35),IRON+Vector2(22,-35),IRON+Vector2(32,-15),IRON+Vector2(-20,-15)]),Color("ef476f")); draw_centered_text(IRON+Vector2(0,-52),"IRONING",16,Color("183642"));
 if processing_station=="iron": draw_progress(IRON)
func draw_collection():
 draw_rect(Rect2(COLLECTION.x-72,COLLECTION.y-42,144,84),Color("2a9d8f")); draw_rect(Rect2(COLLECTION.x-72,COLLECTION.y-42,144,16),Color("78c6b8")); draw_centered_text(COLLECTION+Vector2(0,8),"COLLECTION",15,Color.WHITE)
 if payment_ready: draw_centered_text(COLLECTION+Vector2(0,-55),"N180",17,Color("15803d"))
func draw_generator():
 draw_rect(Rect2(GENERATOR.x-65,GENERATOR.y-42,130,84),Color("495057")); draw_rect(Rect2(GENERATOR.x-48,GENERATOR.y-25,58,45),Color("343a40")); draw_circle(GENERATOR+Vector2(-34,31),12,Color("1f2937")); draw_circle(GENERATOR+Vector2(36,31),12,Color("1f2937")); draw_circle(GENERATOR+Vector2(42,-18),7,Color("22c55e") if generator_on else Color("ef4444")); draw_centered_text(GENERATOR+Vector2(0,-55),"GENERATOR",14,Color("183642"))
func draw_fuel():
 draw_rect(Rect2(FUEL_POINT.x-35,FUEL_POINT.y-45,70,90),Color("d97706")); draw_rect(Rect2(FUEL_POINT.x-18,FUEL_POINT.y-55,36,14),Color("374151")); draw_centered_text(FUEL_POINT+Vector2(0,6),"FUEL",14,Color.WHITE); draw_centered_text(FUEL_POINT+Vector2(0,62),"N100",13,Color("183642"))
func draw_person(p,shirt,label):
 draw_circle(p+Vector2(5,24),27,Color(0,0,0,0.12)); draw_circle(p,25,shirt); draw_circle(p+Vector2(0,-24),15,Color("8d5524")); draw_rect(Rect2(p.x-18,p.y+16,12,26),Color("263238")); draw_rect(Rect2(p.x+6,p.y+16,12,26),Color("263238")); draw_centered_text(p+Vector2(0,60),label,13,Color("183642"))
func draw_basket(p,stage):
 draw_rect(Rect2(p.x-26,p.y-16,52,32),Color("b7791f")); draw_line(p+Vector2(-18,-16),p+Vector2(-8,-30),Color("805b10"),4.0); draw_line(p+Vector2(18,-16),p+Vector2(8,-30),Color("805b10"),4.0); draw_circle(p+Vector2(-10,-14),8,Color("ef476f")); draw_circle(p+Vector2(8,-16),9,Color("3b82f6")); draw_centered_text(p+Vector2(0,30),stage.to_upper(),10,Color("183642"))
func draw_ready_markers():
 if dirty_waiting: draw_ready_icon(DROP_OFF)
 if washer_output!="": draw_ready_icon(WASHER)
 if dryer_output!="": draw_ready_icon(DRYER)
 if iron_output!="": draw_ready_icon(IRON)
 if payment_ready: draw_ready_icon(COLLECTION)
 if not grid_on and not generator_on: draw_power_icon(GENERATOR)
func draw_ready_icon(pos):
 var p=pos+Vector2(0,-88); draw_circle(p,23,Color("22c55e")); draw_centered_text(p+Vector2(0,7),"!",27,Color.WHITE); draw_line(p+Vector2(0,24),pos+Vector2(0,-55),Color("22c55e"),4.0)
func draw_power_icon(pos):
 var p=pos+Vector2(0,-75); draw_circle(p,24,Color("facc15")); draw_centered_text(p+Vector2(0,6),"PWR",12,Color("111827"))
func draw_progress(center):
 var bar=Rect2(center.x-52,center.y+68,104,10); draw_rect(bar,Color(0.1,0.1,0.1,0.55)); draw_rect(Rect2(bar.position,Vector2(bar.size.x*process_progress(),bar.size.y)),Color("facc15"))
func draw_centered_text(pos,text,font_size,color):
 var font=ThemeDB.fallback_font; var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x; draw_string(font,pos-Vector2(width/2.0,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func interaction_position(key):
 if key=="dropoff": return DROP_OFF
 if key=="washer": return WASHER
 if key=="dryer": return DRYER
 if key=="iron": return IRON
 if key=="collection": return COLLECTION
 if key=="generator": return GENERATOR
 if key=="fuel": return FUEL_POINT
 return Vector2.ZERO
