extends CharacterBody2D

# ======================
# MOVEMENT SETTINGS
# ======================
const SPEED := 300.0
const JUMP_VELOCITY := -350.0
const STOP_THRESHOLD := 5.0
const IDLE_DELAY := 0.12

# ======================
# HEALTH SETTINGS
# ======================
@export var max_health := 3
@export var invincible_time := 0.6

var health := 0
var can_take_damage := true
var is_dead := false
var is_hurt := false

signal health_changed(current, max_value)

# ======================
# ATTACK SETTINGS
# ======================
@export var attack_damage := 1
@export var attack_cooldown := 0.4

var can_attack := true
var is_attacking := false

# ======================
# JUMP SETTINGS
# ======================
@export var max_jumps := 4
var jump_count := 0

# ======================
# NODES
# ======================
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

# ======================
# STATE
# ======================
var idle_timer := 0.0
var was_on_floor := false
var needs_reinput := false

# ======================
# READY
# ======================
func _ready():
	add_to_group("player")
	attack_area.monitoring = false

	# ⭐ Restore saved health
	if GameManager.player_health <= 0:
		GameManager.player_health = max_health

	health = GameManager.player_health
	GameManager.player_max_health = max_health

	emit_signal("health_changed", health, max_health)


# ======================
# PHYSICS PROCESS
# ======================
func _physics_process(delta):

	if is_dead or is_hurt:
		apply_gravity(delta)
		move_and_slide()
		return

	if is_attacking:
		apply_gravity(delta)
		move_and_slide()
		return

	if is_on_floor():
		jump_count = 0

	apply_gravity(delta)

	# -------- JUMP --------
	if Input.is_action_just_pressed("ui_accept") and jump_count < max_jumps:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		needs_reinput = true

	# -------- ATTACK --------
	if Input.is_action_just_pressed("attack") and can_attack:
		attack()
		return

	var direction := Input.get_axis("ui_left", "ui_right")

	# -------- MOVEMENT --------
	if is_on_floor():
		if needs_reinput:
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
		if direction != 0:
			velocity.x = direction * SPEED

	move_and_slide()
	update_animation(direction, delta)


# ======================
# GRAVITY
# ======================
func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta


# ======================
# ANIMATION
# ======================
func update_animation(direction, delta):
	if is_hurt or is_dead or is_attacking:
		return

	var on_floor := is_on_floor()
	var stopped := absf(velocity.x) < STOP_THRESHOLD

	if on_floor and not was_on_floor:
		play_anim("Idle", anim.flip_h)
		was_on_floor = true
		return

	if not on_floor:
		if velocity.y < 0:
			play_anim("jump", anim.flip_h)
		else:
			play_anim("fall", anim.flip_h)
		was_on_floor = false
		return

	if direction != 0:
		play_anim("walk", direction < 0)
	elif stopped:
		idle_timer += delta
		if idle_timer >= IDLE_DELAY:
			play_anim("Idle", anim.flip_h)


func play_anim(name: String, flip: bool):
	if anim.sprite_frames.has_animation(name):
		if anim.animation != name:
			anim.play(name)
	anim.flip_h = flip


# ======================
# ATTACK
# ======================
func attack():
	can_attack = false
	is_attacking = true

	velocity.x = 0
	attack_area.monitoring = true
	play_anim("Attack", anim.flip_h)

	await anim.animation_finished

	attack_area.monitoring = false
	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func _on_attack_area_body_entered(body):
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(attack_damage)


# ======================
# DAMAGE
# ======================
func take_damage(amount: int):
	if is_dead or not can_take_damage:
		return

	can_take_damage = false
	is_hurt = true

	health = max(health - amount, 0)
	GameManager.player_health = health

	print("Player HP:", health)
	emit_signal("health_changed", health, max_health)

	if anim.sprite_frames.has_animation("Hurt"):
		anim.play("Hurt")

	if health <= 0:
		die()
		return

	await get_tree().create_timer(invincible_time).timeout

	is_hurt = false
	can_take_damage = true


# ======================
# HEAL
# ======================
func heal(amount: int):
	if is_dead:
		return

	var old_health = health
	health = min(health + amount, max_health)
	GameManager.player_health = health

	if health != old_health:
		print("Player healed →", health)
		emit_signal("health_changed", health, max_health)


# ======================
# DIE
# ======================
func die():
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)

	print("PLAYER DIED")

	if anim.sprite_frames.has_animation("Dead"):
		anim.play("Dead")

	await get_tree().create_timer(0.8).timeout
	get_tree().reload_current_scene()


# ======================
# OPTIONAL DOOR SIGNAL CLEANUP
# ======================
func _on_door_body_entered(_body: Node2D) -> void:
	pass


func _on_door_body_exited(_body: Node2D) -> void:
	pass
