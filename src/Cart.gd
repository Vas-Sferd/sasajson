extends Tree

func _ready():
	var root = create_item()
	for i in 3:
		var item = create_item(root)
		item.set_text(0, str(i))
