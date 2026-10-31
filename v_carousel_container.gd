@tool
extends Container
class_name CarouselContainer

enum X_POSITION {
	LEFT,
	MIDDLE,
	RIGHT,
}
 
enum Y_POSITION {
	TOP,
	MIDDLE,
	BOTTOM,
}

var focused : bool =false ## if one of the children or this node has focus, for mouse scroll

@export var speed : float = 0.5 : ## How fast it tweens from one child to another
	set(val):
		if val == speed:
			return
		speed = val

@export var opacity_factor : float = 3.0: ## How much nonselected chlidren will have their opacity lowered by. 3 = a third. Higher values means more things seen
	set(val):
		if val == opacity_factor:
			return
		val = clamp(val, 1, 10)
		opacity_factor = val
		update_all_children() 


@export var scale_factor : float = 3.0: ## How much nonselected chlidren will be smaller. 3 = a third. Higher values means more things are bigger
	set(val):
		if val == scale_factor:
			return
		val = clamp(val, 1, 10)
		scale_factor = val
		update_all_children() 


@export var seperation : int = 80 : ## In pixels, the space between two children
	set(val):
		if val == seperation:
			return
		seperation = val
		update_all_children() 

@export var x_alignment : X_POSITION  : ## The alignment of all children in the x axis
	set(val):
		if val == x_alignment:
			return
		x_alignment = val
		update_all_children()

@export var y_alignment : Y_POSITION  : ## The alignment of all children in the y axis
	set(val):
		if val == y_alignment:
			return
		y_alignment = val
		update_all_children()

var selected_index : int : ## The index of selected child
	set(val):
		if val == selected_index:
			return
		val = clamp(val, 0, get_child_count() - 1)
		selected_index = val
		get_child(val).grab_focus()
		update_all_children()


var p_s_tweens : Array[Tween] # position and scale tweens
var opacity_tweens : Array[Tween] # opacity tweens


func _process(_delta: float) -> void:
	focused = false
	if has_focus():
		focused = true
	for i in get_children():
		if i.has_focus():
			focused = true
			selected_index = i.get_index()
			break


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			update_all_children()


func update_all_children() -> void:
	p_s_tweens.clear()
	opacity_tweens.clear()
	for c in get_children():
		opacity_tweens.append(create_tween())
		p_s_tweens.append(create_tween())
		var s : Vector2 = Vector2(size.x, c.get_combined_minimum_size().y) # Scale
		s *= clamp(1 - (abs(child_distance_from_selected(c)) / scale_factor), 0, 100)
		var p : Vector2 = get_child_pos(c, s) #Position
		p_s_tweens[c.get_index()].tween_method(foo.bind(c), c.get_rect(), Rect2(p,s) , speed ).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		c.z_index = -abs(child_distance_from_selected(c)) ## Set Z index
		opacity_tweens[c.get_index()].tween_property(c, "self_modulate:a", clamp( (1 - abs(child_distance_from_selected(c))/opacity_factor) , 0, 1) , speed)


func get_child_pos(c : Control, s : Vector2) -> Vector2:
	var p : Vector2
	match x_alignment:
		X_POSITION.LEFT:
			p.x = 0
		X_POSITION.MIDDLE:
			p.x = (size.x / 2) - (s.x / 2)
		X_POSITION.RIGHT:
			p.x = (size.x) - s.x
	match y_alignment:
		Y_POSITION.TOP:
			p.y = 0 + (seperation * child_distance_from_selected(c))
		Y_POSITION.MIDDLE:
			p.y = (size.y / 2) + (seperation * child_distance_from_selected(c)) - (c.size.y / 2)
		Y_POSITION.BOTTOM:
			p.y = size.y + (seperation * child_distance_from_selected(c)) - (c.size.y)
	return p


func foo(rect : Rect2, child : Control) -> void: ## this is here for tweening the fit_cihld_in_rect method. I had to swap the order because i have no clue how to do it otherwise
	fit_child_in_rect(child , rect)


func child_distance_from_selected(child : Control) -> int:
	return child.get_index() - selected_index


func _input(event: InputEvent) -> void:
	# mouse wheel scrolling
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				selected_index += 1
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				selected_index -= 1
