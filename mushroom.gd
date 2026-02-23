extends CharacterBody2D

@export var speed := 40.0
@export var patrol_time := 5.0
@export var damage := 1
@export var stun_time := 0.8

var direction := -1
var patrol_timer := 0.0
var is_stunned := false
var is_dead := false
var has_damaged_player := false

@onready var anim := $AnimatedSprite2D
@onready var detect_area := $DetectArea

func _ready():
	add_to_group("enemy")
	anim.flip_h = direction > 0
	anim.play("Walk")
	detect_area.body_entered.connect(_on_detect_area_body_entered)

func _physics_process(delta):
	if is_dead:
		return

	if is_stunned:
		velocity.x = 0
		move_and_slide()
		return

	# Patrol
	patrol_timer += delta
	if patrol_timer >= patrol_time:
		patrol_timer = 0
		direction *= -1
		anim.flip_h = direction > 0

	velocity.x = direction * speed
	move_and_slide()

func _on_detect_area_body_entered(body):
	if is_dead or is_stunned:
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		if has_damaged_player:
			return

		has_damaged_player = true
		body.take_damage(damage)
		stun()

func take_damage(_amount):
	if is_dead:
		return
	die()

func stun():
	is_stunned = true
	velocity = Vector2.ZERO
	anim.play("Stun")

	await get_tree().create_timer(stun_time).timeout
	is_stunned = false
	has_damaged_player = false
	anim.play("Walk")

func die():
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("Die")

	$CollisionShape2D.disabled = true
	detect_area.monitoring = false

	await anim.animation_finished
	queue_free()
