extends CharacterBody2D

@export var speed: float = 100.0  # Speed of the projectile
@export var damage: int = 40      # Damage dealt to the player
@onready var animated_sprite = $AnimatedSprite2D
var direction: Vector2 = Vector2.ZERO
var player_position: Vector2 = Vector2.ZERO

func _ready():
	# Play the default animation
	if animated_sprite:
		animated_sprite.play("default")
	
	# Set initial velocity towards the player
	if player_position != Vector2.ZERO:
		direction = (player_position - global_position).normalized()
		velocity = direction * speed
		
	# Connect the Area2D body_entered signal
	var area = $Area2D
	if not area.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		area.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))

func _physics_process(delta: float):
	# Move the projectile
	var collision = move_and_collide(velocity * delta)
	
	# Check for collision with player or other objects
	if collision:
		var collider = collision.get_collider()
		if collider and collider.name == "Player" and collider.has_method("take_damage"):
			print("Projectile hit player with CharacterBody2D: ", damage)
			collider.take_damage(damage)
			queue_free()  # Destroy projectile on impact
		elif collider:  # Collided with something else (e.g., wall)
			print("Projectile hit non-player object: ", collider)
			queue_free()

func _on_area_2d_body_entered(body: Node):
	# Handle collision with player via Area2D
	if body.name == "Player" and body.has_method("take_damage"):
		print("Projectile hit player with Area2D: ", damage)
		body.take_damage(damage)
		queue_free()
