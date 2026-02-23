extends CharacterBody2D

# ======================
# MOVEMENT & ATTACK
# ======================
@export var speed := 60.0
@export var attack_cooldown := 3
@export var damage := 1
@export var damage_interval := 0.8

# ======================
# PATROL SETTINGS
# ======================
@export var patrol_radius := 120.0   # max distance from spawn (home)

# ======================
# HEALTH
# ======================
@export var max_health := 1
var health := 1
var is_dead := false

# ======================
# STATE
# ======================
var player: CharacterBody2D = null
var is_attacking := false
var can_attack := true
var player_in_attack_range := false
var damage_timer := 0.0

# ======================
# PHYSICS
# ======================
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var home_position: Vector2

@onready var anim := $AnimatedSprite2D


# ======================
# READY
# ======================
func _ready():
	add_to_group("enemy")   # IMPORTANT
	home_position = global_position
	health = max_health
	player = get_tree().get_first_node_in_group("player")


# ======================
# MAIN LOOP
# ======================
func _physics_process(delta):
	if is_dead:
		return

	# ----------------------
	# DAMAGE OVER TIME (BOT → PLAYER)
	# ----------------------
	if player_in_attack_range:
		damage_timer += delta
		if damage_timer >= damage_interval:
			damage_timer = 0.0
			if player and player.has_method("take_damage"):
				player.take_damage(damage)

	# ----------------------
	# GRAVITY
	# ----------------------
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# ----------------------
	# FACE PLAYER
	# ----------------------
	if player:
		var dx_face = player.global_position.x - global_position.x
		if dx_face != 0:
			anim.flip_h = dx_face < 0

	# ----------------------
	# MOVE LOGIC (LIMITED AREA)
	# ----------------------
	if can_chase_player():
		# Chase player inside patrol area
		var dx = player.global_position.x - global_position.x
		velocity.x = signf(dx) * speed
		play_anim("Walk")

	elif not is_attacking:
		# Return to home position
		var dx = home_position.x - global_position.x
		if abs(dx) > 5:
			velocity.x = signf(dx) * speed
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

	# Player must be inside patrol radius
	return abs(player.global_position.x - home_position.x) <= patrol_radius


# ======================
# ATTACK LOGIC
# ======================
func attack():
	if not can_attack or is_attacking or is_dead:
		return

	can_attack = false
	is_attacking = true
	velocity.x = 0

	play_anim("Attack")
	await anim.animation_finished

	is_attacking = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


# ======================
# TAKE DAMAGE (PLAYER → BOT)
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

	print("BOT DIED")
	play_anim("Dead")

	$CollisionShape2D.disabled = true
	$AttackArea.monitoring = false
	$DetectArea.monitoring = false

	await anim.animation_finished
	queue_free()


# ======================
# DETECT AREA (VISION)
# ======================
func _on_detect_area_body_entered(body):
	if body.is_in_group("player"):
		player = body


func _on_detect_area_body_exited(body):
	if body == player:
		player = null
		player_in_attack_range = false
		damage_timer = 0.0


# ======================
# ATTACK AREA (MELEE)
# ======================
func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_attack_range = true
		damage_timer = 0.0
		attack()


func _on_attack_area_body_exited(body):
	if body == player:
		player_in_attack_range = false
		damage_timer = 0.0


# ======================
# SAFE ANIMATION SWITCH
# ======================
func play_anim(anim_name: String):
	if anim.animation != anim_name:
		anim.play(anim_name)
