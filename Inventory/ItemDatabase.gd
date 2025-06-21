extends Node

var item_data = {
	"Weapons": {
		"StoneSword": {
			"texture": "res://Player/Weapon/StoneSword.png",
			"attack_damage": 10,
			"durability": 50,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "Sword",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"BronzeSword": {
			"texture": "res://Player/Weapon/BronzeSword.png",
			"attack_damage": 20,
			"durability": 50,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "Spear",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"SilverSword": {
			"texture": "res://Player/Weapon/SilverSword.png",
			"attack_damage": 30,
			"durability": 80,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "Spear",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"GoldSword": {
			"texture": "res://Player/Weapon/GoldSword.png",
			"attack_damage": 20,
			"durability": 75,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "Sword",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"IronSword": {
			"texture": "res://Player/Weapon/IronSword.png",
			"attack_damage": 30,
			"durability": 100,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "Sword",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"StoneSpear": {
			"texture": "res://Player/Weapon/StoneSpear.png",
			"attack_damage": 10,
			"durability": 30,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "Spear",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"BronzeSpear": {
			"texture": "res://Player/Weapon/BronzeSpear.png",
			"attack_damage": 20,
			"durability": 50,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "Spear",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"SilverSpear": {
			"texture": "res://Player/Weapon/SilverSpear.png",
			"attack_damage": 30,
			"durability": 60,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "Spear",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"GoldSpear": {
			"texture": "res://Player/Weapon/GoldSpear.png",
			"attack_damage": 35,
			"durability": 90,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "Spear",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"IronSpear": {
			"texture": "res://Player/Weapon/IronSpear.png",
			"attack_damage": 40,
			"durability": 100,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "Spear",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"StoneAxe": {
			"texture": "res://Player/Weapon/StoneAxe.png",
			"attack_damage": 2,
			"durability": 50,
			"tool_type": "Axe",
			"tier": 1,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"BronzeAxe": {
			"texture": "res://Player/Weapon/BronzeAxe.png",
			"attack_damage": 5,
			"durability": 70,
			"tool_type": "Axe",
			"tier": 2,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"SilverAxe": {
			"texture": "res://Player/Weapon/SilverAxe.png",
			"attack_damage": 7,
			"durability": 85,
			"tool_type": "Axe",
			"tier": 3,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"GoldAxe": {
			"texture": "res://Player/Weapon/GoldAxe.png",
			"attack_damage": 10,
			"durability": 100,
			"tool_type": "Axe",
			"tier": 4,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"IronAxe": {
			"texture": "res://Player/Weapon/IronAxe.png",
			"attack_damage": 13,
			"durability": 120,
			"tool_type": "Axe",
			"tier": 5,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"StonePickAxe": {
			"texture": "res://Player/Weapon/StonePickAxe.png",
			"attack_damage": 2,
			"durability": 50,
			"tool_type": "PickAxe",
			"tier": 1,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"BronzePickAxe": {
			"texture": "res://Player/Weapon/BronzePickAxe.png",
			"attack_damage": 5,
			"durability": 70,
			"tool_type": "PickAxe",
			"tier": 2,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"SilverPickAxe": {
			"texture": "res://Player/Weapon/SilverPickAxe.png",
			"attack_damage": 7,
			"durability": 85,
			"tool_type": "PickAxe",
			"tier": 3,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"GoldPickAxe": {
			"texture": "res://Player/Weapon/GoldPickAxe.png",
			"attack_damage": 10,
			"durability": 100,
			"tool_type": "PickAxe",
			"tier": 4,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"IronPickAxe": {
			"texture": "res://Player/Weapon/IronPickAxe.png",
			"attack_damage": 13,
			"durability": 120,
			"tool_type": "PickAxe",
			"tier": 5,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"BronzeShovel": {
			"texture": "res://Player/Weapon/BronzeShovel.png",
			"attack_damage": 5,
			"durability": 50,
			"tool_type": "Shovel",
			"tier": 2,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"SilverShovel": {
			"texture": "res://Player/Weapon/SilverShovel.png",
			"attack_damage": 7,
			"durability": 70,
			"tool_type": "Shovel",
			"tier": 3,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"GoldShovel": {
			"texture": "res://Player/Weapon/GoldShovel.png",
			"attack_damage": 10,
			"durability": 100,
			"tool_type": "Shovel",
			"tier": 3,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"IronShovel": {
			"texture": "res://Player/Weapon/IronShovel.png",
			"attack_damage": 13,
			"durability": 100,
			"tool_type": "Shovel",
			"tier": 3,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"GreatSword": {
			"texture": "res://Player/Weapon/GreatSword.png",
			"attack_damage": 50,
			"durability": 250,
			"scale": Vector2(0.03, 0.03),
			"tool_type": "GreatSword",
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
	},
	"Armor": {
		"LeatherArmor": {
			"texture": "res://Player/Armor/LeatherArmor.png",
			"body_texture": "res://Player/Sprites/LeatherArmorBody.png",
			"defense": 3,
			"durability": 30,
			"scale": Vector2(0.02, 0.02),
			"collision_shape": {
				"type": "Capsule",
				"radius": 5.0,
				"height": 12.0
			}
		},
		"BronzeArmor": {
			"texture": "res://Player/Armor/BronzeArmor.png",
			"body_texture": "res://Player/Sprites/BronzeArmorBody.png",
			"defense": 7,
			"durability": 30,
			"speed_bonus": -10,
			"scale": Vector2(0.02, 0.02),
			"collision_shape": {
				"type": "Capsule",
				"radius": 5.0,
				"height": 12.0
			}
		},
		"SilverArmor": {
			"texture": "res://Player/Armor/SilverArmor.png",
			"body_texture": "res://Player/Sprites/SilverArmorBody.png",
			"defense": 12,
			"durability": 30,
			"speed_bonus": -10,
			"scale": Vector2(0.02, 0.02),
			"collision_shape": {
				"type": "Capsule",
				"radius": 5.0,
				"height": 12.0
			}
		},
		"GoldArmor": {
			"texture": "res://Player/Armor/GoldArmor.png",
			"body_texture": "res://Player/Sprites/GoldArmorBody.png",
			"defense": 17,
			"durability": 50,
			"speed_bonus": -10,
			"scale": Vector2(0.02, 0.02),
			"collision_shape": {
				"type": "Capsule",
				"radius": 5.0,
				"height": 12.0
			}
		},
		"ChitinArmor": {
			"texture": "res://Player/Armor/ChitinArmor.png",
			"body_texture": "res://Player/Sprites/ChitinArmorBody.png",
			"defense": 17,
			"durability": 50,
			"speed_bonus": -10,
			"scale": Vector2(0.02, 0.02),
			"collision_shape": {
				"type": "Capsule",
				"radius": 5.0,
				"height": 12.0
			}
		},
		"IronArmor": {
			"texture": "res://Player/Armor/IronArmor.png",
			"body_texture": "res://Player/Sprites/IronArmorBody.png",
			"defense": 22,
			"durability": 60,
			"speed_bonus": -15,
			"scale": Vector2(0.02, 0.02),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"DiamondArmor": {
			"texture": "res://Player/Armor/DiamondArmor.png",
			"body_texture": "res://Player/Sprites/DiamondArmorBody.png",
			"defense": 18,
			"durability": 75,
			"scale": Vector2(0.02, 0.02),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		}
	},
	"Helmet": {
		"LeatherHelmet": {
			"texture": "res://Player/Helmet/LeatherHelmet.png",
			"head_texture": "res://Player/Sprites/LeatherHelmetHead.png",
			"defense": 2,
			"durability": 20,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"BronzeHelmet": {
			"texture": "res://Player/Helmet/BronzeHelmet.png",
			"head_texture": "res://Player/Sprites/BronzeHelmetHead.png",
			"defense": 3,
			"durability": 30,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"SilverHelmet": {
			"texture": "res://Player/Helmet/SilverHelmet.png",
			"head_texture": "res://Player/Sprites/SilverHelmetHead.png",
			"defense": 4,
			"durability": 30,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"GoldHelmet": {
			"texture": "res://Player/Helmet/GoldHelmet.png",
			"head_texture": "res://Player/Sprites/GoldHelmetHead.png",
			"defense": 5,
			"durability": 50,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"ChitinHelmet": {
			"texture": "res://Player/Helmet/ChitinHelmet.png",
			"head_texture": "res://Player/Sprites/ChitinHelmetHead.png",
			"defense": 5,
			"durability": 50,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"IronHelmet": {
			"texture": "res://Player/Helmet/IronHelmet.png",
			"head_texture": "res://Player/Sprites/IronHelmetHead.png",
			"defense": 5,
			"durability": 75,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		},
		"DiamondHelmet": {
			"texture": "res://Player/Helmet/DiamondHelmet.png",
			"head_texture": "res://Player/Sprites/DiamondHelmetHead.png",
			"defense": 7,
			"durability": 50,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Capsule",
				"radius": 8.0,
				"height": 18.0
			}
		}
	},
	"Backpack": {
		"BasicBackpack": {
			"texture": "res://GUI/CraftingSystem/Sprites/BasicBackpack.png",
			"max_slots_bonus": 3,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(8, 8)
			}
		},
		"LargeBackpack": {
			"texture": "res://GUI/CraftingSystem/Sprites/LargeBackpack.png",
			"max_slots_bonus": 6,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(8, 8)
			}
		},
	},
	"Shoes": {
		"LeatherShoes": {
			"texture": "res://Player/Shoes/LeatherShoes.png",
			"speed_bonus": 5,
			"durability": 20,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(8, 8)
			}
		},
		"BronzeShoes": {
			"texture": "res://Player/Shoes/BronzeShoes.png",
			"speed_bonus": 10,
			"defense": 1,
			"durability": 30,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(8, 8)
			}
		},
		"SilverShoes": {
			"texture": "res://Player/Shoes/SilverShoes.png",
			"speed_bonus": 15,
			"defense": 2,
			"durability": 30,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(8, 8)
			}
		},
		"GoldShoes": {
			"texture": "res://Player/Shoes/GoldShoes.png",
			"speed_bonus": 20,
			"defense": 3,
			"durability": 50,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(8, 8)
			}
		},
		"IronShoes": {
			"texture": "res://Player/Shoes/IronShoes.png",
			"speed_bonus": 17,
			"defense": 4,
			"durability": 75,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(8, 8)
			}
		},
		"DiamondShoes": {
			"texture": "res://Player/Shoes/DiamondShoes.png",
			"speed_bonus": 22,
			"defense": 3,
			"durability": 50,
			"scale": Vector2(0.03, 0.03),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(8, 8)
			}
		},
	},
	"Consumables": {
		"Apple": {
			"texture": "res://World/Tree/Sprites/apple.png",
			"hunger_restore": 5,
			"thirst_restore": 1,
			"scale": Vector2(0.09, 0.09),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(6, 6)
			}
		},
		"DirtyWater": {
			"texture": "res://World/Sprites/DirtyWater.png",
			"health_restore": -5,
			"thirst_restore": 5,
			"scale": Vector2(0.2, 0.2),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(6, 6)
			}
		},
		"CleanWater": {
			"texture": "res://World/Sprites/CleanWater.png",
			"thirst_restore": 30,
			"scale": Vector2(0.2, 0.2),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(6, 6)
			}
		},
		"Carrot": {
			"texture": "res://World/Carrot/Carrot.png",
			"hunger_restore": 5,
			"scale": Vector2(0.09, 0.09),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(6, 6)
			}
		},
		"ToastedCarrot": {
			"texture": "res://World/Carrot/ToastedCarrot.png",
			"health_restore": 1,
			"hunger_restore": 15,
			"scale": Vector2(0.09, 0.09),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(6, 6)
			}
		},
		"RawMeat": {
			"texture": "res://World/Cow/RawMeat.png",
			"health_restore": -5,
			"hunger_restore": 10,
			"scale": Vector2(0.12, 0.12),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"CookedMeat": {
			"texture": "res://World/Cow/CookedMeat.png",
			"health_restore": 5,
			"hunger_restore": 30,
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Bandage": {
			"texture": "res://GUI/CraftingSystem/Sprites/Bandage.png",
			"health_restore": 20,
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Bolas": {
			"texture": "res://Player/Weapon/Bolas.png",
			"range": 75.0,          # Tầm ném (dùng cho RayCast)
			"effect": "immobilize", # Hiệu ứng khi trúng
			"duration": 15.0,
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(6, 6)
			}
		},
		"Bread": {
			"texture": "res://GUI/CraftingSystem/Sprites/Bread.png",
			"health_restore": 5,
			"hunger_restore": 30,
			"scale": Vector2(0.09, 0.09),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(6, 6)
			}
		},
	},
	"Materials": {
		"Fiber": {
			"texture": "res://World/Bush/Sprites/fiber.png",
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(6, 6)
			}
		},
		"Vine": {
			"texture": "res://World/Swamp/VineTree/Vine.png",
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(6, 6)
			}
		},
		"TreeLog": {
			"texture": "res://World/Tree/Sprites/tree_log.png",
			"scale": Vector2(0.07, 0.07),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(8, 3.5),
				"position": Vector2(0, 0.25)
			}
		},
		"SwampLog": {
			"texture": "res://World/Tree/Sprites/tree_log.png",
			"scale": Vector2(0.07, 0.07),
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(8, 3.5),
				"position": Vector2(0, 0.25)
			}
		},
		"Rock": {
			"texture": "res://World/Rock/Sprites/Rock.png",
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Twine": {
			"texture": "res://GUI/CraftingSystem/Sprites/Twine.png",
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Rope": {
			"texture": "res://GUI/CraftingSystem/Sprites/Rope.png",
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Leather": {
			"texture": "res://World/Cow/Leather.png",
			"scale": Vector2(0.3, 0.3),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Copper": {
			"texture": "res://World/CopperOre/CopperOre.png",
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Tin": {
			"texture": "res://World/TinOre/TinOre.png",
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Silver": {
			"texture": "res://World/Swamp/SilverOre/SilverOre.png",
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"BronzeIngot": {
			"texture": "res://GUI/CraftingSystem/Sprites/BronzeIngot.png",
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"TinIngot": {
			"texture": "res://World/TinIngot/TinIngot.png",
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"CopperIngot": {
			"texture": "res://World/CopperIngot/CopperIngot.png",
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"SilverIngot": {
			"texture": "res://World/Swamp/SilverOre/SilverIngot.png",
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Gold": {
			"texture": "res://World/Desert/GoldOre/Sprites/Gold.png",
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Iron": {
			"texture": "res://World/Cave/IronOre/Sprites/Iron.png",
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"GoldIngot": {
			"texture": "res://World/Desert/GoldOre/Sprites/GoldIngot.png",
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"IronIngot": {
			"texture": "res://World/Cave/IronOre/Sprites/IronIngot.png",
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Cloth": {
			"texture": "res://GUI/CraftingSystem/Sprites/Cloth.png",
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"SlimeGel": {
			"texture": "res://World/Enemy/Slime/SlimeGel.png",
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Coin": {
			"texture": "res://World/Enemy/Slime/Coin.png",
			"scale": Vector2(0.08, 0.0840909),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"TannedLeather": {
			"texture": "res://World/Cow/TannedLeather.png",
			"scale": Vector2(0.01, 0.01),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Nails": {
			"texture": "res://GUI/CraftingSystem/Sprites/Nails.png",
			"scale": Vector2(0.1, 0.1),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"CarrotSeed": {
			"texture": "res://World/Carrot/CarrotSeed.png",
			"scale": Vector2(0.05, 0.05),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"RedFlower": {
			"texture": "res://World/Flower/RedFlower.png",
			"scale": Vector2(0.2, 0.2),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"BlueFlower": {
			"texture": "res://World/Flower/BlueFlower.png",
			"scale": Vector2(0.2, 0.2),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Mud": {
			"texture": "res://World/Swamp/Mud/Mud.png",
			"scale": Vector2(0.2, 0.2),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Sand": {
			"texture": "res://World/Cave/Sand/Sand.png",
			"scale": Vector2(0.3, 0.3),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Glass": {
			"texture": "res://World/Cave/Sand/Glass.png",
			"scale": Vector2(0.2, 0.2),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"EmptyBottle": {
			"texture": "res://GUI/CraftingSystem/Sprites/EmptyPotion.png",
			"scale": Vector2(0.1, 0.1),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Diamond": {
			"texture": "res://World/Cave/DiamondOre/Diamond.png",
			"scale": Vector2(0.1, 0.1),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Glue": {
			"texture": "res://GUI/CraftingSystem/Sprites/Glue.png",
			"scale": Vector2(0.04, 0.04),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Wheat": {
			"texture": "res://GUI/CraftingSystem/Sprites/Wheat.png",
			"scale": Vector2(0.04, 0.04),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"WheatSeed": {
			"texture": "res://GUI/CraftingSystem/Sprites/WheatSeed.png",
			"scale": Vector2(0.04, 0.04),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Mushroom": {
			"texture": "res://GUI/CraftingSystem/Sprites/Mushroom.png",
			"scale": Vector2(0.04, 0.04),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Coal": {
			"texture": "res://World/Cave/Coal/Coal.png",
			"scale": Vector2(0.04, 0.04),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"BoneFragment": {
			"texture": "res://World/Enemy/DesertEnemy/Skeleton/BoneFragment.png",
			"scale": Vector2(0.04, 0.04),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Bone": {
			"texture": "res://GUI/CraftingSystem/Sprites/Bone.png",
			"scale": Vector2(0.04, 0.04),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
		"Chitin": {
			"texture": "res://World/Enemy/DesertEnemy/Scopio/Chitin.png",
			"scale": Vector2(0.07, 0.07),
			"collision_shape": {
				"type": "Circle",
				"radius": 5.0
			}
		},
	},
	"Structure": {  # New category for structures
		"CraftingTable": {
			"texture": "res://GUI/CraftingSystem/Sprites/CraftingTable.png",  # Adjust path as needed
			"scale": Vector2(0.05, 0.05),  # Adjust scale as needed
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(30, 30)  # Adjust size as needed
			}
		},
		"Campfire": {
			"texture": "res://GUI/CraftingSystem/Sprites/Campfire.png",  # Adjust path as needed
			"scale": Vector2(0.015, 0.015),  # Adjust scale as needed
			"collision_shape": {
				"type": "Circle",
				"radius": 10.0  # Adjust radius as needed
			},
			"scene_path": "res://GUI/CraftingSystem/Scenes/Campfire.tscn"
		},
		"Smelter": {
			"texture": "res://GUI/CraftingSystem/Sprites/Smelter.png",  # Adjust path as needed
			"scale": Vector2(0.1, 0.1),  # Adjust scale as needed
			"collision_shape": {
				"type": "Circle",
				"radius": 10.0  # Adjust radius as needed
			},
			"scene_path": "res://GUI/CraftingSystem/Scenes/Smelter.tscn"
		},
		"Hammer": {
			"texture": "res://GUI/CraftingSystem/Sprites/Hammer.png",  # Adjust path as needed
			"scale": Vector2(0.05, 0.05),  # Adjust scale as needed
			"collision_shape": {
				"type": "Circle",
				"radius": 10.0  # Adjust radius as needed
			}
		},
		"WoodenChest": {
			"texture": "res://GUI/CraftingSystem/Sprites/WoodenChest.png",
			"slot": 10,
			"scale": Vector2(0.095, 0.095),  # Adjust scale as needed
			"collision_shape": {
				"type": "Circle",
				"radius": 10.0  # Adjust radius as needed
			}
		},
		"IronChest": {
			"texture": "res://GUI/CraftingSystem/Sprites/IronChest.png",
			"slot": 20,
			"scale": Vector2(0.25, 0.25),  # Adjust scale as needed
			"collision_shape": {
				"type": "Circle",
				"radius": 10.0  # Adjust radius as needed
			}
		},
		"TanningRack": {
			"texture": "res://GUI/CraftingSystem/Sprites/TanningRack.png",
			"scale": Vector2(0.25, 0.25),  # Adjust scale as needed
			"collision_shape": {
				"type": "Circle",
				"radius": 10.0  # Adjust radius as needed
			}
		},
		"WoodenWall": {
			"texture": "res://GUI/CraftingSystem/Sprites/WoodenWall.png",
			"scale": Vector2(0.35, 0.35),  # Adjust scale as needed
			"health": 1500,  # Thêm health
			"type": "wall",  # Thêm type
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(35, 11),
				"position": Vector2(0, 0.25)
			}
		},
		"WoodenSpikes": {
			"texture": "res://GUI/CraftingSystem/Sprites/WoodenSpikes.png",
			"scale": Vector2(0.045, 0.045),  # Adjust scale as needed
			"health": 750,  # Thêm health
			"type": "wall",  # Thêm type
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(36, 25),
				"position": Vector2(-5, 50)
			},
			"scene_path": "res://GUI/CraftingSystem/Scenes/WoodenSpikes.tscn"
		},
		"IronSpikes": {
			"texture": "res://GUI/CraftingSystem/Sprites/IronSpikes.png",
			"scale": Vector2(0.045, 0.045),  # Adjust scale as needed
			"health": 2500,  # Thêm health
			"type": "wall",  # Thêm type
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(36, 25),
				"position": Vector2(-5, 50)
			}
		},
		"FeedingTrough": {
			"texture": "res://GUI/CraftingSystem/Sprites/FeedingTrough.png",
			"scale": Vector2(0.05, 0.05),  # Adjust scale as needed
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(39, 20),
				"position": Vector2(-5, 45)
			}
		},
		"CarrotFarm": {
			"texture": "res://GUI/CraftingSystem/Sprites/CarrotFarm.png",
			"scale": Vector2(0.09, 0.09),  # Adjust scale as needed
			"wait_time": 2500,  # Thời gian sinh trưởng: 2500 giây
			"harvest_items": {  # Thay harvest_item và harvest_quantity bằng harvest_items
			"Carrot": 5,    # 3 Carrot
			"CarrotSeed": 5 },
			"collision_shape": {
				"type": "Circle",
				"radius": 2.0  # Adjust radius as needed
			},
			"scene_path": "res://GUI/CraftingSystem/Scenes/CarrotFarm.tscn"
		},
		"WheatFarm": {
			"texture": "res://GUI/CraftingSystem/Sprites/WheatFarm.png",
			"scale": Vector2(1.5, 1.5),  # Adjust scale as needed
			"wait_time": 2500,  # Thời gian sinh trưởng: 2500 giây
			"harvest_items": {  # Thay harvest_item và harvest_quantity bằng harvest_items
			"Wheat": 4,    # 3 Carrot
			"WheatSeed": 3 },
			"collision_shape": {
				"type": "Circle",
				"radius": 15.0  # Adjust radius as needed
			}
		},
		"MushroomFarm": {
			"texture": "res://GUI/CraftingSystem/Sprites/MushroomFarm.png",
			"scale": Vector2(0.09, 0.09),  # Adjust scale as needed
			"wait_time": 2500,  # Thời gian sinh trưởng: 2500 giây
			"harvest_items": {  # Thay harvest_item và harvest_quantity bằng harvest_items
			"Mushroom": 4,    # 3 Carrot
			},
			"collision_shape": {
				"type": "Circle",
				"radius": 15.0  # Adjust radius as needed
			}
		},
		"BaseMarker": {
			"texture": "res://GUI/CraftingSystem/Sprites/BaseMarker.png",
			"scale": Vector2(0.05, 0.05),  # Adjust scale as needed
			"collision_shape": {
				"type": "Rectangle",
				"size": Vector2(10, 10),
				"position": Vector2(-5, 45)
			}
		},
		"Torch": {
			"texture": "res://GUI/CraftingSystem/Sprites/Torch.png",
			"scale": Vector2(0.07, 0.07),  # Lấy từ CaveEntrance.tscn
			"collision_shape": {
				"type": "Circle",
				"radius": 50.0 # Lấy từ CollisionShape2D trong CaveEntrance.tscn
			},
			"scene_path": "res://GUI/CraftingSystem/Scenes/Torch.tscn"  # Đường dẫn đến scene
		},
		"CaveEntrance": {
			"texture": "res://World/Cave/CaveEntrance1.png",
			"scale": Vector2(0.07, 0.07),  # Lấy từ CaveEntrance.tscn
			"collision_shape": {
				"type": "Circle",
				"radius": 50.0 # Lấy từ CollisionShape2D trong CaveEntrance.tscn
			},
			"scene_path": "res://World/Cave/CaveEntrance.tscn"  # Đường dẫn đến scene
		},
		"SwampEntrance": {
			"texture": "res://World/Swamp/Sprites/SwampEntrance1.png",
			"scale": Vector2(0.09, 0.09),  # Lấy từ CaveEntrance.tscn
			"collision_shape": {
				"type": "Circle",
				"radius": 50.0  # Lấy từ CollisionShape2D trong CaveEntrance.tscn
			},
			"scene_path": "res://World/Swamp/SwampEntrance.tscn"  # Đường dẫn đến scene
		},
		"DesertEntrance": {
			"texture": "res://World/Desert/Sprites/DesertEntrance1.png",
			"scale": Vector2(0.07, 0.07),  # Lấy từ CaveEntrance.tscn
			"collision_shape": {
				"type": "Circle",
				"radius": 50.0  # Lấy từ CollisionShape2D trong CaveEntrance.tscn
			},
			"scene_path": "res://World/Desert/DesertEntrance.tscn"  # Đường dẫn đến scene
		},
		"UndefeatedTotem": {
			"texture": "res://World/Enemy/Boss/Undefeated/undefeatedTotem.png",
			"scale": Vector2(0.07, 0.07),  # Lấy từ CaveEntrance.tscn
			"collision_shape": {
				"type": "Circle",
				"radius": 50.0  # Lấy từ CollisionShape2D trong CaveEntrance.tscn
			},
			"scene_path": "res://World/Enemy/Boss/Undefeated/UndefeatedTotem.tscn"  # Đường dẫn đến scene
		},
	}
}

func get_item_data():
	return item_data
