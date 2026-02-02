extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -350.0
const STOP_THRESHOLD = 5.0
const IDLE_DELAY = 0.12

@onready var animated_sprite = $AnimatedSprite2D

var idle_timer := 0.0
var was_on_floor := false
var needs_reinput := false


func _physics_process(delta: float) -> void:
	# -------- GRAVITY --------
	if not is_on_floor():
		velocity += get_gravity() * delta

	# -------- JUMP --------
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		needs_reinput = true

	var direction := Input.get_axis("ui_left", "ui_right")

	# -------- HORIZONTAL MOVEMENT --------
	if is_on_floor():
		if needs_reinput:
			# Force idle after landing until key released
			if direction == 0:
				needs_reinput = false
			velocity.x = 0
		else:
			if direction != 0:
				velocity.x = direction * SPEED
				idle_timer = 0.0
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# AIR CONTROL (jump left / right)
		if direction != 0:
			velocity.x = direction * SPEED

	move_and_slide()

	# -------- ANIMATION LOGIC --------
	var on_floor := is_on_floor()
	var stopped := absf(velocity.x) < STOP_THRESHOLD

	# Landing frame → force Idle
	if on_floor and not was_on_floor:
		needs_reinput = true
		idle_timer = 0.0
		play_anim("Idle", animated_sprite.flip_h)
		was_on_floor = true
		return

	# AIR
	if not on_floor:
		if velocity.y < 0:
			play_anim("jump", animated_sprite.flip_h)
		else:
			play_anim("fall", animated_sprite.flip_h)
		was_on_floor = false
		return

	# GROUND
	if needs_reinput:
		play_anim("Idle", animated_sprite.flip_h)
	elif direction != 0:
		play_anim("walk", direction < 0)
	elif stopped:
		idle_timer += delta
		if idle_timer >= IDLE_DELAY:
			play_anim("Idle", animated_sprite.flip_h)

	was_on_floor = true


func _process(_delta):
	# Pixel-perfect look
	global_position = global_position.round()


func play_anim(name: String, flip: bool) -> void:
	if animated_sprite.sprite_frames.has_animation(name):
		if animated_sprite.animation != name:
			animated_sprite.play(name)
	animated_sprite.flip_h = flip


var is_dead := false

func die():
	if is_dead:
		return

	is_dead = true

	# Stop player movement
	velocity = Vector2.ZERO
	set_physics_process(false)

	# Play death animation
	if animated_sprite.sprite_frames.has_animation("died"):
		animated_sprite.play("died")

	# Wait so animation can be seen
	await get_tree().create_timer(0.6).timeout

	# Example: restart scene (you can change later)
	get_tree().reload_current_scene()


func _on_spike_2_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
