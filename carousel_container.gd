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

var focused : bool =false # if one of the children or this node has focus

enum DIRECTION {
	VERTICAL,
	HORIZONTAL,
}

@export var direction : DIRECTION = DIRECTION.VERTICAL :
	set(val):
		if val == direction:
			return
		direction = val
		update_all_children()

@export var speed : float = 0.5 :
	set(val):
		if val == speed:
			return
		speed = val

@export var opacity_factor : float = 3.0:
	set(val):
		if val == opacity_factor:
			return
		val = clamp(val, 1, 10)
		opacity_factor = val
		update_all_children()


@export var scale_factor : float = 3.0:
	set(val):
		if val == scale_factor:
			return
		val = clamp(val, 1, 10)
		scale_factor = val
		update_all_children()


@export var seperation : int = 80 : # in px
	set(val):
		if val == seperation:
			return
		seperation = val
		update_all_children()

@export var base_x_position : X_POSITION  : # if the selected should be at top left or
	set(val):
		if val == base_x_position:
			return
		base_x_position = val
		update_all_children()

@export var base_y_position : Y_POSITION  : # if the selected should be at top left or
	set(val):
		if val == base_y_position:
			return
		base_y_position = val
		update_all_children()

@export var selected_index : int :
	set(val):
		if val == selected_index:
			return
		val = clamp(val, 0, get_child_count() - 1)
		selected_index = val
		get_child(val).grab_focus()
		update_all_children()


var p_s_tweens : Array[Tween]
var opacity_tweens : Array[Tween]


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
		var s : Vector2 = get_child_scale(c)
		var p : Vector2 = get_child_pos(c, s) #Position
		p_s_tweens[c.get_index()].tween_method(foo.bind(c), c.get_rect(), Rect2(p,s) , speed ).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		c.z_index = -abs(child_distance_from_selected(c)) ## Set Z index
		opacity_tweens[c.get_index()].tween_property(c, "self_modulate:a", clamp( (1 - abs(child_distance_from_selected(c))/opacity_factor) , 0, 1) , speed)


func get_child_scale(c : Control) -> Vector2:
	var s : Vector2

	match direction:
		DIRECTION.VERTICAL:
			s =  Vector2(size.x, c.get_combined_minimum_size().y)
		DIRECTION.HORIZONTAL:
			s = Vector2(c.get_combined_minimum_size().x, size.y)

	s *= clamp(1 - (abs(child_distance_from_selected(c)) / scale_factor), 0, 100)
	return s


func get_child_pos(c : Control, s : Vector2) -> Vector2:
	var p : Vector2
	match direction:
		DIRECTION.VERTICAL:
			p = get_child_pos_vertical(c, s)
		DIRECTION.HORIZONTAL:
			p = get_child_pos_horizontal(c, s)
	return p


func get_child_pos_vertical(c : Control, s : Vector2) -> Vector2: ## used when the direction is vertical
	var p : Vector2
	match base_x_position:
		X_POSITION.LEFT:
			p.x = 0
		X_POSITION.MIDDLE:
			p.x = (size.x / 2) - (s.x / 2)
		X_POSITION.RIGHT:
			p.x = (size.x) - s.x
	match base_y_position:
		Y_POSITION.TOP:
			p.y = 0 + (seperation * child_distance_from_selected(c))
		Y_POSITION.MIDDLE:
			p.y = (size.y / 2) + (seperation * child_distance_from_selected(c)) - (s.y / 2)
		Y_POSITION.BOTTOM:
			p.y = size.y + (seperation * child_distance_from_selected(c)) - (s.y)
	return p


func get_child_pos_horizontal(c : Control, s : Vector2) -> Vector2: ## used when the direction is horizontal
	var p : Vector2
	match base_x_position:
		X_POSITION.LEFT:
			p.x = 0 + (seperation * child_distance_from_selected(c))
		X_POSITION.MIDDLE:
			p.x = (size.x / 2) - (c.size.x / 2) + (seperation * child_distance_from_selected(c))
		X_POSITION.RIGHT:
			p.x = (size.x) - c.size.x + (seperation * child_distance_from_selected(c))
	match base_y_position:
		Y_POSITION.TOP:
			p.y = 0
		Y_POSITION.MIDDLE:
			p.y = (size.y / 2) - (s.y / 2)
		Y_POSITION.BOTTOM:
			p.y = size.y - (s.y)
	return p


func foo(rect : Rect2, child : Control) -> void:
	fit_child_in_rect(child , rect)


func child_distance_from_selected(child : Control) -> int:
	return child.get_index() - selected_index



func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				selected_index += 1
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				selected_index -= 1
