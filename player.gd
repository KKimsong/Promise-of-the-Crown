extends CharacterBody2D

# ======================
# MOVEMENT SETTINGS
# ======================
const SPEED := 200.0
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
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var jumpsound: AudioStreamPlayer2D = $Jumpsound
@onready var fightsound: AudioStreamPlayer2D = $fightsound
@onready var deathsound: AudioStreamPlayer2D = $deathsound
@onready var hurt: AudioStreamPlayer2D = $hurt
# ======================
# STATE
# ======================
var idle_timer := 0.0
var was_on_floor := false
var needs_reinput := false
var has_key = false


# ======================
# READY
# ======================
func _ready():
	add_to_group("player")
	attack_area.monitoring = false

	# Setup timer
	invincible_timer.wait_time = invincible_time
	invincible_timer.one_shot = true
	invincible_timer.timeout.connect(_on_invincible_timer_timeout)

	if GameManager.player_health <= 0:
		GameManager.player_health = max_health

	health = GameManager.player_health
	GameManager.player_max_health = max_health

	emit_signal("health_changed", health, max_health)


# ======================
# PHYSICS PROCESS
# ======================
func _physics_process(delta):

	if is_dead:
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

	# JUMP
	if Input.is_action_just_pressed("ui_accept") and jump_count < max_jumps:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		needs_reinput = true

	# ATTACK
	if Input.is_action_just_pressed("attack") and can_attack:
		attack()
		return

	var direction := Input.get_axis("ui_left", "ui_right")

	# MOVEMENT
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
	if is_dead or is_attacking:
		return

	var on_floor := is_on_floor()
	var stopped := absf(velocity.x) < STOP_THRESHOLD

	if not on_floor:
		if velocity.y < 0:
			play_anim("jump", anim.flip_h)
			jumpsound.pitch_scale = randf_range(0.95, 1.05)
			jumpsound.play()
		else:
			play_anim("fall", anim.flip_h)
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
	fightsound.pitch_scale = randf_range(0.95, 1.0)
	fightsound.play()

func _on_attack_area_body_entered(body):
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
	

# ======================
# DAMAGE
# ======================
func take_damage(amount: int):
	if is_dead:
		return

	if not can_take_damage:
		return

	hurt.pitch_scale = randf_range(0.9, 1.1)
	hurt.play()
	
	can_take_damage = false
	invincible_timer.start()

	health -= amount
	health = max(health, 0)

	GameManager.player_health = health

	print("Player HP:", health)
	emit_signal("health_changed", health, max_health)
	
	if health <= 0:
		die()


func _on_invincible_timer_timeout():
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

	if anim.sprite_frames.has_animation("Dead"):
		anim.play("Dead")
		deathsound.pitch_scale = randf_range(0.1, 0.7)
		deathsound.play()

	await get_tree().create_timer(0.8).timeout
	get_tree().reload_current_scene()
