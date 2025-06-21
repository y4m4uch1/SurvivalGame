# Item.gd
extends Node2D

var item_name = ""
var can_pickup = false

@onready var sprite = $Sprite2D
@onready var collision_shape = $Area2D/CollisionShape2D

func _ready():
	var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
	var item_data = item_db.get_item_data()
	
	# Tìm thông tin item trong item_data
	for category in item_data.keys():
		if item_name in item_data[category]:
			var data = item_data[category][item_name]
			sprite.texture = load(data["texture"])
			
			# Điều chỉnh scale nếu có trong dữ liệu
			if "scale" in data:
				sprite.scale = data["scale"]
			
			# Tạo hình dạng va chạm động
			if "collision_shape" in data:
				match data["collision_shape"]["type"]:
					"Rectangle":
						var shape = RectangleShape2D.new()
						shape.size = data["collision_shape"]["size"]
						collision_shape.shape = shape
					"Circle":
						var shape = CircleShape2D.new()
						shape.radius = data["collision_shape"]["radius"]
						collision_shape.shape = shape
					"Capsule":
						var shape = CapsuleShape2D.new()
						shape.radius = data["collision_shape"]["radius"]
						shape.height = data["collision_shape"]["height"]
						collision_shape.shape = shape
			
			# Đặt vị trí CollisionShape2D nếu có
			if "collision_position" in data:
				collision_shape.position = data["collision_position"]
			break
	
	set_meta("can_pickup", can_pickup)
	add_to_group("pickup")
