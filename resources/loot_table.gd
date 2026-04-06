# loot_table.gd
extends Resource
class_name LootTable

@export var items: Array[Resource] = []  # or any item resource
@export var weights: Array[int] = []

func get_random_item() -> Resource:
	if items.is_empty():
		return null
	if weights.is_empty() or weights.size() != items.size():
		return items[randi() % items.size()]
	var total := 0
	for w in weights:
		total += w
	var roll = randi() % total
	var cumulative := 0
	for i in items.size():
		cumulative += weights[i]
		if roll < cumulative:
			return items[i]
	return items[0]
