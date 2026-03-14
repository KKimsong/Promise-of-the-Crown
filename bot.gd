extends CharacterBody2D
# ======================
# Sound
# ======================
@onready var Die: AudioStreamPlayer2D = $Die
@onready var Attack: AudioStreamPlayer2D = $Attack

# ======================
# MOVEMENT & ATTACK
# ======================
@export var speed: float = 60.0
@export var attack_cooldown: float = 2.0
@export var damage: int = 1
var attack_timer := 0.0
# ======================
# PATROL
# ======================
@export var patrol_radius: float = 120.0

# ======================
# HEALTH
# ======================
@export var max_health: int = 1
var health: int
var is_dead: bool = false

# ======================
# STATE
# ======================
var player: CharacterBody2D = null
var is_attacking: bool = false
var can_attack: bool = true
var player_in_attack_range: bool = false

# ======================
# PHYSICS
# ======================
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var home_position: Vector2

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


# ======================
# READY
# ======================
func _ready():
	add_to_group("enemy")
	home_position = global_position
	health = max_health
	player = get_tree().get_first_node_in_group("player")


# ======================
# MAIN LOOP
# ======================
func _physics_process(delta):
	if is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Face player
	if player:
		var dx_face = player.global_position.x - global_position.x
		if dx_face != 0:
			anim.flip_h = dx_face < 0

	# Handle cooldown timer
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0

	# Attack logic
	if player_in_attack_range and can_attack:
		attack()

	# Movement
	if can_chase_player():
		var dx = player.global_position.x - global_position.x
		velocity.x = signf(dx) * speed
		play_anim("Walk")

	elif not is_attacking:
		var dx_home = home_position.x - global_position.x
		if abs(dx_home) > 5:
			velocity.x = signf(dx_home) * speed
			play_anim("Walk")
		else:
			velocity.x = 0
			play_anim("Idle")

	move_and_slide()


# ======================
# CHASE CONDITION
# ======================
func can_chase_player() -> bool:
	if not player:
		return false
	if is_attacking or player_in_attack_range:
		return false

	return abs(player.global_position.x - home_position.x) <= patrol_radius

func hit_player():
	if player_in_attack_range and player and player.has_method("take_damage"):
		player.take_damage(damage)
		print("Bot dealt damage to player")
# ======================
# ATTACK
# ======================
func attack():
	if is_dead or not can_attack:
		return

	is_attacking = true
	can_attack = false
	velocity.x = 0

	play_anim("Attack")
	Attack.pitch_scale = randf_range(0.3, 0.7)
	Attack.play()
	await get_tree().create_timer(0.3).timeout

	if player and player_in_attack_range:
		print("Enemy dealt 1 damage")
		player.take_damage(damage)

	await anim.animation_finished

	is_attacking = false

	# Wait for hit frame timing
	await get_tree().create_timer(0.3).timeout

	# DIRECTLY hit player once
	if player and player_in_attack_range and player.has_method("take_damage"):
		print("Enemy dealt 1 damage")
		player.take_damage(damage)

	await anim.animation_finished

	is_attacking = false

# ======================
# TAKE DAMAGE (FROM PLAYER)
# ======================
func take_damage(amount: int):
	if is_dead:
		return

	health -= amount
	print("BOT HP:", health)

	if health <= 0:
		die()


# ======================
# DIE
# ======================
func die():
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	play_anim("Dead")
	Die.pitch_scale = randf_range(0.3, 0.7)
	Die.play()
	# Prevent physics crash
	$CollisionShape2D.set_deferred("disabled", true)
	$AttackArea.set_deferred("monitoring", false)
	$DetectArea.set_deferred("monitoring", false)

	await anim.animation_finished
	queue_free()
	


# ======================
# DETECT AREA
# ======================
func _on_detect_area_body_entered(body):
	if body.is_in_group("player"):
		player = body


func _on_detect_area_body_exited(body):
	if body == player:
		player = null
		player_in_attack_range = false


# ======================
# ATTACK AREA
# ======================
func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_attack_range = true


func _on_attack_area_body_exited(body):
	if body == player:
		player_in_attack_range = false


# ======================
# SAFE ANIMATION
# ======================
func play_anim(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)
