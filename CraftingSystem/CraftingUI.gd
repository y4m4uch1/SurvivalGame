extends CanvasLayer

var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
var item_data = item_db.get_item_data()

@onready var player = get_parent().get_node("Player")
@onready var inventory_ui = get_node_or_null("/root/Ground/InventoryUI")
@onready var grid_container = $ColorRect/ScrollContainer/GridContainer
@onready var craft_button = $ColorRect/CraftButton
@onready var recipe_list = $ColorRect/RecipeScrollContainer/RecipeList  # Cập nhật đường dẫn
@onready var category_container = $ColorRect/HBoxContainer

var crafting_recipes = {
	"StoneAxe": {
		"result": {"name": "StoneAxe", "quantity": 1, "durability": 50},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "Rock", "quantity": 3}
		],
		"requires_workbench": false,
		"requires_campfire": false
	},
	"StonePickAxe": {
		"result": {"name": "StonePickAxe", "quantity": 1, "durability": 50},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "Rock", "quantity": 3}
		],
		"requires_workbench": false,
		"requires_campfire": false
	},
	"CraftingTable": {
		"result": {"name": "CraftingTable", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 15},
			{"name": "Rock", "quantity": 10}
		],
		"requires_workbench": false,
		"requires_campfire": false
	},
	"Campfire": {
		"result": {"name": "Campfire", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 10}
		],
		"requires_workbench": false,
		"requires_campfire": false
	},
	"BronzeAxe": {
		"result": {"name": "BronzeAxe", "quantity": 1, "durability": 70},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "BronzeIngot", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"SilverAxe": {
		"result": {"name": "SilverAxe", "quantity": 1, "durability": 85},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "SilverIngot", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"GoldAxe": {
		"result": {"name": "GoldAxe", "quantity": 1, "durability": 100},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "GoldIngot", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"IronAxe": {
		"result": {"name": "IronAxe", "quantity": 1, "durability": 120},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "IronIngot", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"BronzePickAxe": {
		"result": {"name": "BronzePickAxe", "quantity": 1, "durability": 70},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "BronzeIngot", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"SilverPickAxe": {
		"result": {"name": "SilverPickAxe", "quantity": 1, "durability": 85},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "SilverIngot", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"GoldPickAxe": {
		"result": {"name": "GoldPickAxe", "quantity": 1, "durability": 100},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "GoldIngot", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"IronPickAxe": {
		"result": {"name": "IronPickAxe", "quantity": 1, "durability": 120},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "IronIngot", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"LeatherHelmet": {
		"result": {"name": "LeatherHelmet", "quantity": 1, "durability": 50},
		"requirements": [
			{"name": "Leather", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"LeatherArmor": {
		"result": {"name": "LeatherArmor", "quantity": 1, "durability": 50},
		"requirements": [
			{"name": "Leather", "quantity": 10}
		],
		"requires_workbench": true,
	},
	"LeatherShoes": {
		"result": {"name": "LeatherShoes", "quantity": 1, "durability": 50},
		"requirements": [
			{"name": "Leather", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"BasicBackpack": {
		"result": {"name": "BasicBackpack", "quantity": 1},
		"requirements": [
			{"name": "Fiber", "quantity": 3},
			{"name": "Rope", "quantity": 5},
			{"name": "Leather", "quantity": 2}
		],
		"requires_workbench": true,
	},
	"BronzeHelmet": {
		"result": {"name": "BronzeHelmet", "quantity": 1, "durability": 30},
		"requirements": [
			{"name": "BronzeIngot", "quantity": 6},
			{"name": "Rope", "quantity": 2},
			{"name": "TannedLeather", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"BronzeArmor": {
		"result": {"name": "BronzeArmor", "quantity": 1, "durability": 30},
		"requirements": [
			{"name": "BronzeIngot", "quantity": 10},
			{"name": "Rope", "quantity": 3},
			{"name": "TannedLeather", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"BronzeShoes": {
		"result": {"name": "BronzeShoes", "quantity": 1, "durability": 30},
		"requirements": [
			{"name": "BronzeIngot", "quantity": 5},
			{"name": "Rope", "quantity": 2},
			{"name": "TannedLeather", "quantity": 2}
		],
		"requires_workbench": true,
	},
	"SilverHelmet": {
		"result": {"name": "SilverHelmet", "quantity": 1, "durability": 30},
		"requirements": [
			{"name": "SilverIngot", "quantity": 6},
			{"name": "Glue", "quantity": 2},
			{"name": "TannedLeather", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"SilverArmor": {
		"result": {"name": "SilverArmor", "quantity": 1, "durability": 30},
		"requirements": [
			{"name": "SilverIngot", "quantity": 10},
			{"name": "Glue", "quantity": 3},
			{"name": "TannedLeather", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"SilverShoes": {
		"result": {"name": "SilverShoes", "quantity": 1, "durability": 30},
		"requirements": [
			{"name": "SilverIngot", "quantity": 5},
			{"name": "Glue", "quantity": 2},
			{"name": "TannedLeather", "quantity": 2}
		],
		"requires_workbench": true,
	},
	"ChitinHelmet": {
		"result": {"name": "ChitinHelmet", "quantity": 1},
		"requirements": [
			{"name": "Chitin", "quantity": 6},
			{"name": "Glue", "quantity": 2},
			{"name": "TannedLeather", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"ChitinArmor": {
		"result": {"name": "ChitinArmor", "quantity": 1},
		"requirements": [
			{"name": "Chitin", "quantity": 10},
			{"name": "Glue", "quantity": 3},
			{"name": "TannedLeather", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"ChitinShoes": {
		"result": {"name": "ChitinShoes", "quantity": 1},
		"requirements": [
			{"name": "Chitin", "quantity": 5},
			{"name": "Glue", "quantity": 2},
			{"name": "TannedLeather", "quantity": 2}
		],
		"requires_workbench": true,
	},
	"GoldHelmet": {
		"result": {"name": "GoldHelmet", "quantity": 1},
		"requirements": [
			{"name": "GoldIngot", "quantity": 6},
			{"name": "Glue", "quantity": 2},
			{"name": "TannedLeather", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"GoldArmor": {
		"result": {"name": "GoldArmor", "quantity": 1},
		"requirements": [
			{"name": "GoldIngot", "quantity": 10},
			{"name": "Glue", "quantity": 3},
			{"name": "TannedLeather", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"GoldShoes": {
		"result": {"name": "GoldShoes", "quantity": 1},
		"requirements": [
			{"name": "GoldIngot", "quantity": 5},
			{"name": "Glue", "quantity": 2},
			{"name": "TannedLeather", "quantity": 2}
		],
		"requires_workbench": true,
	},
	"IronHelmet": {
		"result": {"name": "IronHelmet", "quantity": 1},
		"requirements": [
			{"name": "Iron", "quantity": 5},
			{"name": "Glue", "quantity": 2},
			{"name": "TannedLeather", "quantity": 3},
			{"name": "Nails", "quantity": 4}
		],
		"requires_workbench": true,
	},
	"IronArmor": {
		"result": {"name": "IronArmor", "quantity": 1},
		"requirements": [
			{"name": "IronIngot", "quantity": 10},
			{"name": "Glue", "quantity": 3},
			{"name": "TannedLeather", "quantity": 5},
			{"name": "Nails", "quantity": 8}
		],
		"requires_workbench": true,
	},
	"IronShoes": {
		"result": {"name": "IronShoes", "quantity": 1},
		"requirements": [
			{"name": "IronIngot", "quantity": 5},
			{"name": "Rope", "quantity": 2},
			{"name": "TannedLeather", "quantity": 2}
		],
		"requires_workbench": true,
	},
	"TanningRack": {
		"result": {"name": "TanningRack", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 5},
			{"name": "Fiber", "quantity": 5},
			{"name": "Rock", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"StoneSword": {
		"result": {"name": "StoneSword", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "Rock", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"GoldSword": {
		"result": {"name": "GoldSword", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 5},
			{"name": "Fiber", "quantity": 5},
			{"name": "GoldIngot", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"IronSword": {
		"result": {"name": "IronSword", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 4},
			{"name": "Nail", "quantity": 3},
			{"name": "IronIngot", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"StoneSpear": {
		"result": {"name": "StoneSpear", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 3},
			{"name": "Rock", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"BronzeSpear": {
		"result": {"name": "BronzeSpear", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 5},
			{"name": "Rope", "quantity": 3},
			{"name": "GoldIngot", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"SilverSpear": {
		"result": {"name": "SilverSpear", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 5},
			{"name": "Glue", "quantity": 3},
			{"name": "SilverIngot", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"GoldSpear": {
		"result": {"name": "GoldSpear", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 5},
			{"name": "Glue", "quantity": 4},
			{"name": "GoldIngot", "quantity": 5}
		],
		"requires_workbench": true,
	},
	"IronSpear": {
		"result": {"name": "IronSpear", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 5},
			{"name": "Nails", "quantity": 4},
			{"name": "IronIngot", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"Smelter": {
		"result": {"name": "Smelter", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 15},
			{"name": "Rock", "quantity": 15},
		],
		"requires_workbench": true,
	},
	"CleanWater": {
		"result": {"name": "CleanWater", "quantity": 1},
		"requirements": [
			{"name": "DirtyWater", "quantity": 1},
			{"name": "TreeLog", "quantity": 1}
		],
		"requires_campfire": true,
	},
	"ToastedCarrot": {
		"result": {"name": "ToastedCarrot", "quantity": 1},
		"requirements": [
			{"name": "Carrot", "quantity": 1},
			{"name": "TreeLog", "quantity": 1}
		],
		"requires_campfire": true,
	},
	"CookedMeat": {
		"result": {"name": "CookedMeat", "quantity": 1},
		"requirements": [
			{"name": "RawMeat", "quantity": 1},
			{"name": "TreeLog", "quantity": 1}
		],
		"requires_campfire": true,
	},
	"Bandage": {
		"result": {"name": "Bandage", "quantity": 1},
		"requirements": [
			{"name": "Cloth", "quantity": 2},
			{"name": "RedFlower", "quantity": 2},
		],
		"requires_workbench": true,
	},	
	"Hammer": {
		"result": {"name": "Hammer", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 1},
			{"name": "Rock", "quantity": 1},
		],
		"requires_workbench": true,
	},
	"WoodenChest": {
		"result": {"name": "WoodenChest", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 5},
			{"name": "Rope", "quantity": 2},
		],
		"requires_workbench": true,
	},
	"IronChest": {
		"result": {"name": "IronChest", "quantity": 1},
		"requirements": [
			{"name": "IronIngot", "quantity": 5},
			{"name": "Nails", "quantity": 4},
		],
		"requires_workbench": true,
	},
	"WoodenWall": {
		"result": {"name": "WoodenWall", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 10},
			{"name": "Rope", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"WoodenSpikes": {
		"result": {"name": "WoodenSpikes", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 12},
			{"name": "Rope", "quantity": 3}
		],
		"requires_workbench": true,
	},
	"IronSpikes": {
		"result": {"name": "IronSpikes", "quantity": 1},
		"requirements": [
			{"name": "IronIngot", "quantity": 15},
			{"name": "Nails", "quantity": 10},
			{"name": "Rope", "quantity": 5},
		],
		"requires_workbench": true,
	},
	"FeedingTrough": {
		"result": {"name": "FeedingTrough", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 10},
			{"name": "Carrot", "quantity": 10}
		],
		"requires_workbench": true,
	},
	"CarrotFarm": {
		"result": {"name": "CarrotFarm", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 4},
			{"name": "CarrotSeed", "quantity": 5},
			{"name": "Mud", "quantity": 3},
			{"name": "CleanWater", "quantity": 3},
		],
		"requires_workbench": true,
	},
	"Nails": {
		"result": {"name": "Nails", "quantity": 4},
		"requirements": [
			{"name": "IronIngot", "quantity": 1}
		],
		"requires_workbench": true,
	},
	"Glue": {
		"result": {"name": "Glue", "quantity": 1},
		"requirements": [
			{"name": "SlimeGel", "quantity": 2}
		],
		"requires_workbench": true,
	},
	"TinIngot": {
		"result": {"name": "TinIngot", "quantity": 1},
		"requirements": [
			{"name": "Tin", "quantity": 2},
			{"name": "TreeLog", "quantity": 1}
		],
		"requires_smelter": true,
	},
	"CopperIngot": {
		"result": {"name": "CopperIngot", "quantity": 1},
		"requirements": [
			{"name": "Copper", "quantity": 2},
			{"name": "TreeLog", "quantity": 1}
		],
		"requires_smelter": true,
	},
	"BronzeIngot": {
		"result": {"name": "BronzeIngot", "quantity": 1},
		"requirements": [
			{"name": "Copper", "quantity": 2},
			{"name": "Tin", "quantity": 2},
			{"name": "TreeLog", "quantity": 1}
		],
		"requires_smelter": true,
	},
	"SilverIngot": {
		"result": {"name": "SilverIngot", "quantity": 1},
		"requirements": [
			{"name": "Silver", "quantity": 1},
			{"name": "SwampLog", "quantity": 1}
		],
		"requires_smelter": true,
	},
	"GoldIngot": {
		"result": {"name": "GoldIngot", "quantity": 1},
		"requirements": [
			{"name": "Gold", "quantity": 1},
			{"name": "SwampLog", "quantity": 2}
		],
		"requires_smelter": true,
	},
	"IronIngot": {
		"result": {"name": "IronIngot", "quantity": 1},
		"requirements": [
			{"name": "Iron", "quantity": 1},
			{"name": "Coal", "quantity": 2}
		],
		"requires_smelter": true,
	},
	"EmptyBottle": {
		"result": {"name": "EmptyBottle", "quantity": 1},
		"requirements": [
			{"name": "Glass", "quantity": 3}
		],
		"requires_smelter": true,
	},
	"Glass": {
		"result": {"name": "Glass", "quantity": 1},
		"requirements": [
			{"name": "Sand", "quantity": 4}
		],
		"requires_smelter": true,
	},
	"TannedLeather": {
		"result": {"name": "TannedLeather", "quantity": 1},
		"requirements": [
			{"name": "Leather", "quantity": 1},
			{"name": "SlimeGel", "quantity": 2}
		],
		"requires_tanningrack": true,
	},
	"Twine": {
		"result": {"name": "Twine", "quantity": 1},
		"requirements": [
			{"name": "Cloth", "quantity": 2}
		],
		"requires_tanningrack": true,
	},
	"Rope": {
		"result": {"name": "Rope", "quantity": 1},
		"requirements": [
			{"name": "Vine", "quantity": 2}
		],
		"requires_tanningrack": true,
	},
	"Cloth": {
		"result": {"name": "Cloth", "quantity": 1},
		"requirements": [
			{"name": "Fiber", "quantity": 2}
		],
		"requires_tanningrack": true,
	},
	"Bolas": {
		"result": {"name": "Bolas", "quantity": 1},
		"requirements": [
			{"name": "Rope", "quantity": 1},
			{"name": "Rock", "quantity": 2},
		],
		"requires_workbench": true,
	},
	"Bread": {
		"result": {"name": "Bread", "quantity": 1},
		"requirements": [
			{"name": "Wheat", "quantity": 2}
		],
		"requires_workbench": true,
	},
	"BaseMarker": {
		"result": {"name": "BaseMarker", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 1},
			{"name": "Rock", "quantity": 2}
		],
		"requires_workbench": true,
	},
	"DesertEntrance": {
		"result": {"name": "DesertEntrance", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 1},
			{"name": "Rock", "quantity": 0}
		],
		"requires_workbench": true,
	},
	"CaveEntrance": {
		"result": {"name": "CaveEntrance", "quantity": 1},
		"requirements": [
			{"name": "TreeLog", "quantity": 1},
			{"name": "Rock", "quantity": 0}
		],
		"requires_workbench": true,
	},
}
var selected_recipe: String = ""
var selected_category: String = "All"
var categories = ["All", "Weapons", "Equipment", "Structure", "Consumables", "Materials"]

var recipe_categories = {
	"Weapons": [
		"StoneAxe",
		"StonePickAxe",
		"BronzeAxe",
		"BronzePickAxe",
		"SilverAxe",
		"SilverPickAxe",
		"GoldAxe",
		"GoldPickAxe",
		"IronAxe",
		"IronPickAxe",
		"DiamondAxe",
		"DiamondPickAxe",
		"StoneSword",
		"BronzeSword",
		"SilverSword",
		"GoldSword",
		"IronSword",
		"DiamondSword",
		"StoneSpear",
		"BronzeSpear",
		"SilverSpear",
		"GoldSpear",
		"IronSpear",
		"DiamondSpear",
		"Bolas",
	],
	"Equipment": [
		"BasicBackpack",
		"LeatherHelmet",
		"BronzeHelmet",
		"SilverHelmet",
		"GoldHelmet",
		"IronHelmet",
		"DiamondHelmet",
		"LeatherArmor",
		"BronzeArmor",
		"SilverArmor",
		"GoldArmor",
		"IronArmor",
		"DiamondArmor",
		"LeatherShoes",
		"BronzeShoes",
		"SilverShoes",
		"GoldShoes",
		"IronShoes",
		"DiamondShoes"
	],
	"Structure": [
		"CraftingTable",
		"Campfire",
		"TanningRack",
		"WoodenChest",
		"IronChest",
		"Hammer",
		"Smelter",
		"WoodenWall",
		"WoodenSpikes",
		"IronSpikes",
		"FeedingTrough",
		"CarrotFarm",
		"WheatFarm",
		"MushroomFarm",
		"BaseMarker"
	],
	"Consumables": [
		"CleanWater",
		"CookedMeat",
		"Bandage",
		"ToastedCarrot",
		"Bread"
	],
	"Materials": [
		"BronzeIngot",
		"SilverIngot",
		"GoldIngot",
		"IronIngot",
		"TannedLeather",
		"Rope",
		"Cloth",
		"Glue",
		"Nails",
		"Glass",
		"EmptyBottle"
	]
}

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if not player:
		print("Warning: Player node not found!")
	
	craft_button.connect("pressed", Callable(self, "_on_craft_pressed"))
	setup_category_buttons()
	update_recipe_list()

func setup_category_buttons():
	for category in categories:
		var button = Button.new()
		button.text = category
		button.connect("pressed", Callable(self, "_on_category_selected").bind(category))
		category_container.add_child(button)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_craft"):
		visible = !visible
		if visible:
			update_recipe_list()
			update_crafting_ui()
		else:
			selected_recipe = ""
			update_crafting_ui()
	elif visible and event is InputEventKey and event.pressed and \
		 not event.is_action("ui_up") and \
		 not event.is_action("ui_down") and \
		 not event.is_action("ui_left") and \
		 not event.is_action("ui_right"):
		visible = false
		selected_recipe = ""
		update_crafting_ui()

func update_recipe_list():
	for child in recipe_list.get_children():
		child.queue_free()
	
	var default_recipes = ["StoneAxe", "StonePickAxe", "CraftingTable", "Campfire"]
	var near_structure_type = get_near_structure_type()
	
	for recipe_name in crafting_recipes.keys():
		var recipe = crafting_recipes[recipe_name]
		var can_show = false
		
		if recipe_name in default_recipes:
			can_show = true
		elif recipe.get("requires_workbench", false) and near_structure_type == "CraftingTable":
			can_show = true
		elif recipe.get("requires_campfire", false) and near_structure_type == "Campfire":
			can_show = true
		elif recipe.get("requires_smelter", false) and near_structure_type == "Smelter":
			can_show = true
		elif recipe.get("requires_tanningrack", false) and near_structure_type == "TanningRack":
			can_show = true
		
		if can_show and (selected_category == "All" or is_recipe_in_category(recipe_name, selected_category)):
			# Tạo HBoxContainer để chứa hình ảnh và nút
			var recipe_container = HBoxContainer.new()
			recipe_container.custom_minimum_size = Vector2(200, 64)
			recipe_container.alignment = BoxContainer.ALIGNMENT_CENTER
			
			# Tạo TextureRect cho hình ảnh
			var texture_rect = TextureRect.new()
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.custom_minimum_size = Vector2(110, 110)
			
			# Tìm texture trong item_data
			for category in item_data.keys():
				if recipe["result"]["name"] in item_data[category]:
					texture_rect.texture = load(item_data[category][recipe["result"]["name"]]["texture"])
					break
			
			# Tạo Button để hiển thị tên và xử lý sự kiện chọn
			var button = Button.new()
			button.text = recipe_name
			button.custom_minimum_size = Vector2(100, 0)
			button.connect("pressed", Callable(self, "_on_recipe_selected").bind(recipe_name))
			
			# Thêm các thành phần vào container
			recipe_container.add_child(texture_rect)
			recipe_container.add_child(button)
			
			# Thêm container vào recipe_list
			recipe_list.add_child(recipe_container)

func is_recipe_in_category(recipe_name: String, category: String) -> bool:
	if category == "All":
		return true
	if category in recipe_categories:
		return recipe_name in recipe_categories[category]
	return false

func update_crafting_ui():
	for child in grid_container.get_children():
		child.queue_free()
	
	if selected_recipe == "":
		return
	
	var recipe = crafting_recipes[selected_recipe]
	
	for req in recipe["requirements"]:
		var item_container = VBoxContainer.new()
		item_container.custom_minimum_size = Vector2(100, 100)
		
		var texture_rect = TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.custom_minimum_size = Vector2(64, 64)
		
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		for category in item_data.keys():
			if req["name"] in item_data[category]:
				texture_rect.texture = load(item_data[category][req["name"]]["texture"])
				break
		
		label.text = req["name"] + ": " + str(get_item_quantity(req["name"])) + "/" + str(req["quantity"])
		if get_item_quantity(req["name"]) >= req["quantity"]:
			label.modulate = Color.GREEN
		else:
			label.modulate = Color.RED
		
		item_container.add_child(texture_rect)
		item_container.add_child(label)
		grid_container.add_child(item_container)
	
	var result_container = VBoxContainer.new()
	result_container.custom_minimum_size = Vector2(100, 100)
	
	var result_texture = TextureRect.new()
	result_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	result_texture.custom_minimum_size = Vector2(64, 64)
	
	var result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	for category in item_data.keys():
		if recipe["result"]["name"] in item_data[category]:
			result_texture.texture = load(item_data[category][recipe["result"]["name"]]["texture"])
			break
	
	result_label.text = recipe["result"]["name"]
	
	result_container.add_child(result_texture)
	result_container.add_child(result_label)
	grid_container.add_child(result_container)

func get_item_quantity(item_name: String) -> int:
	var total = 0
	for slot in player.inventory:
		if not slot.is_empty() and slot.has("name") and slot["name"] == item_name:
			total += slot["quantity"]
	return total

func can_craft(recipe: Dictionary) -> bool:
	for req in recipe["requirements"]:
		if get_item_quantity(req["name"]) < req["quantity"]:
			return false
	return true

func _on_category_selected(category: String):
	selected_category = category
	update_recipe_list()
	selected_recipe = ""
	update_crafting_ui()

func _on_recipe_selected(recipe_name: String):
	selected_recipe = recipe_name
	update_crafting_ui()

func _on_craft_pressed():
	if selected_recipe == "":
		print("No recipe selected!")
		return
	
	var recipe = crafting_recipes[selected_recipe]
	var default_recipes = ["StoneAxe", "StonePickAxe", "CraftingTable", "Campfire"]
	var near_structure_type = get_near_structure_type()
	
	if not (selected_recipe in default_recipes) and \
	   not (recipe.get("requires_workbench", false) and near_structure_type == "CraftingTable") and \
	   not (recipe.get("requires_campfire", false) and near_structure_type == "Campfire") and \
	   not (recipe.get("requires_smelter", false) and near_structure_type == "Smelter") and \
	   not (recipe.get("requires_tanningrack", false) and near_structure_type == "TanningRack"):
		var required_structure = "CraftingTable" if recipe.get("requires_workbench", false) else \
								"Campfire" if recipe.get("requires_campfire", false) else \
								"Smelter" if recipe.get("requires_smelter", false) else \
								"TanningRack"
		print("You need to be near a " + required_structure + " to craft", selected_recipe)
		return
	
	if not can_craft(recipe):
		print("Not enough materials to craft", selected_recipe)
		return
	
		# Kiểm tra xem inventory có đủ chỗ để chứa vật phẩm được chế tạo không
	var result = recipe["result"]
	if not can_add_to_inventory(result["name"], result["quantity"], result.get("durability", -1)):
		player.show_notification("Inventory full! Cannot craft " + selected_recipe + "!")
		return
	
	# Logic chế tạo (giữ nguyên phần còn lại của hàm)
	for req in recipe["requirements"]:
		var remaining = req["quantity"]
		for i in range(player.inventory.size() - 1, -1, -1):
			var slot = player.inventory[i]
			if slot.is_empty() or not slot.has("name"):
				continue  # Skip empty or invalid slots
			if slot["name"] == req["name"]:
				if slot["quantity"] <= remaining:
					remaining -= slot["quantity"]
					player.inventory.remove_at(i)
				else:
					slot["quantity"] -= remaining
					remaining = 0
				if remaining == 0:
					break
	
	if "durability" in result:
		player.add_to_inventory(result["name"], result["durability"])
	else:
		player.add_to_inventory(result["name"])
	
	print("Crafted:", result["name"])
	update_crafting_ui()
	if inventory_ui and inventory_ui.visible:
		inventory_ui.update_inventory()

func get_near_structure_type() -> String:
	var space_state = player.get_world_2d().direct_space_state
	var raycast_distance = 16.0  # Match player.gd's raycast distance (one tile length)
	var direction: Vector2

	# Determine direction based on player's sprite frame (facing direction)
	match player.body_sprite.frame:
		0:  # Down
			direction = Vector2(0, 1)
		1:  # Left
			direction = Vector2(-1, 0)
		2:  # Right
			direction = Vector2(1, 0)
		3:  # Up
			direction = Vector2(0, -1)
		_:
			direction = Vector2(0, 1)  # Default to down if frame is invalid

	# Create raycast query
	var query = PhysicsRayQueryParameters2D.create(
		player.global_position,
		player.global_position + direction * raycast_distance,
		1  # Collision mask for structures (layer 1)
	)
	query.exclude = [player]  # Exclude the player from the raycast

	var result = space_state.intersect_ray(query)

	if result and result.collider is StaticBody2D:
		var collider = result.collider
		if collider.has_meta("structure_name"):
			var structure_name = collider.get_meta("structure_name")
			if structure_name in ["CraftingTable", "Campfire", "Smelter", "TanningRack"]:
				return structure_name
	return ""

func can_add_to_inventory(item_name: String, quantity: int, durability: int = -1) -> bool:
	var max_stack = 10  # Giới hạn stack tối đa, đồng bộ với inventoryUI.gd
	var remaining_quantity = quantity
	
	# Kiểm tra các slot hiện có để gộp
	for slot in player.inventory:
		if slot.is_empty():
			continue
		if slot["name"] == item_name and not slot.has("current_durability") and durability == -1:
			var available_space = max_stack - slot["quantity"]
			if available_space > 0:
				remaining_quantity -= available_space
				if remaining_quantity <= 0:
					return true
	
	# Kiểm tra slot trống
	var empty_slots = 0
	for slot in player.inventory:
		if slot.is_empty():
			empty_slots += 1
			remaining_quantity -= max_stack
			if remaining_quantity <= 0:
				return true
	
	# Kiểm tra xem có thể mở rộng inventory không
	if player.inventory.size() < player.max_slots:
		var available_slots = player.max_slots - player.inventory.size()
		empty_slots += available_slots
		remaining_quantity -= available_slots * max_stack
		if remaining_quantity <= 0:
			return true
	
	return false
