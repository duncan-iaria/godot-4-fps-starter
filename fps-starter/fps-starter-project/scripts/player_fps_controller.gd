class_name Player extends CharacterBody3D


@export var jump_velocity: float = 4.5
@export var crouch_animation_speed: float = 7.0;

@export var DEFAULT_MOVE_SPEED: float = 5.0;
@export var CROUCHING_MOVE_SPEED: float = 2.0;

@export var IS_CROUCH_TOGGLEABLE: bool = true;
@export var MOUSE_SENSITIVITY: float = 0.25;
@export var TILT_LOWER_LIMIT = deg_to_rad(-90.0);
@export var TILT_UPPER_LIMIT = deg_to_rad(90.0);
@export var CAMERA_CONTROLLER: Camera3D;
@export var ANIMATION_PLAYER: AnimationPlayer;
@export var CROUCH_SHAPECAST: ShapeCast3D;

var _mouse_rotation: Vector3;
var _player_rotation: Vector3;
var _camera_rotation: Vector3;
var _mouse_input: bool = false;
var _rotation_input: float;
var _tilt_input: float;
var _current_player_move_speed: float;
var _is_crouching: bool = false;


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	CROUCH_SHAPECAST.add_exception(self);
	
	_current_player_move_speed = DEFAULT_MOVE_SPEED;


func _input(event: InputEvent) -> void:
	# Quit game
	if event.is_action_pressed("quit"):
		get_tree().quit();
		
	if event.is_action_pressed("crouch") and is_on_floor() and IS_CROUCH_TOGGLEABLE:
		toggle_crouch();
	
	if event.is_action_pressed("crouch") and is_on_floor() and !IS_CROUCH_TOGGLEABLE:
		crouching(true);
	
	if event.is_action_released("crouch") and !IS_CROUCH_TOGGLEABLE:
		if CROUCH_SHAPECAST.is_colliding() == false:
			crouching(false);
		else:
			_uncrouch_check();


func _unhandled_input(event: InputEvent) -> void:
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED;
	
	if _mouse_input:
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY;
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY;
	

func _physics_process(delta: float) -> void:
	_update_camera(delta);
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and !_is_crouching:
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * _current_player_move_speed
		velocity.z = direction.z * _current_player_move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, _current_player_move_speed)
		velocity.z = move_toward(velocity.z, 0, _current_player_move_speed)

	move_and_slide()


func _update_camera(delta: float) -> void: 
	_mouse_rotation.x += _tilt_input * delta;
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT);
	
	_player_rotation = Vector3(0.0, _mouse_rotation.y, 0.0);
	_camera_rotation = Vector3(_mouse_rotation.x, 0.0, 0.0);
	
	_mouse_rotation.y += _rotation_input * delta;
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation);
	CAMERA_CONTROLLER.rotation.z = 0.0;
	
	self.global_transform.basis = Basis.from_euler(_player_rotation);
	
	_rotation_input = 0.0;
	_tilt_input = 0.0;


func toggle_crouch() -> void:
	if _is_crouching and CROUCH_SHAPECAST.is_colliding() == false:
		crouching(false);
	elif !_is_crouching:
		crouching(true);


func crouching(state: bool):
	match state:
		true:
			ANIMATION_PLAYER.play("crouch", -1, crouch_animation_speed);
			set_movement_speed("crouching");
		false:
			ANIMATION_PLAYER.play("crouch", -1, -crouch_animation_speed, true);
			set_movement_speed("default");
			

func _uncrouch_check():
	if CROUCH_SHAPECAST.is_colliding() == false:
		crouching(false);
	if CROUCH_SHAPECAST.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout;
		_uncrouch_check();
		

func set_movement_speed(state: String):
	match state:
		"default":
			_current_player_move_speed = DEFAULT_MOVE_SPEED;
		"crouching": 
			_current_player_move_speed = CROUCHING_MOVE_SPEED;


func _on_animation_player_animation_started(anim_name: StringName) -> void:
	if anim_name == "crouch":
		_is_crouching = !_is_crouching;
