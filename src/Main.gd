extends Control

export(float, 0, 1) var split_min_anchor := 0.15
export(float, 0, 1) var split_max_anchor := 0.5
export(Dictionary) var modules_localization_data := {}


onready var split := ($Split as SplitContainer)
onready var modules := ($Split/ModulesPanel/Modules as Tree)


# Автоматический ресайз при изменении развмера контейнера или движинея раздилителя
func _resize_split_container(offset: int = -1):
	if split != null:
		if offset == -1:
			offset = split.split_offset
		
		var width := float(split.rect_size.x)
		split.split_offset = int(width * clamp(offset / width, split_min_anchor, split_max_anchor))

# Открываем файл и считываем из него данные. А затем закрываем
func _read_json_file():
	var file := File.new()
	var err := file.open("locale.json", file.READ)
	
	if err != OK:
		return
	
	var res_json := JSON.parse(file.get_as_text())
	
	if res_json.error != OK:
		return
	
	# Наши данные должны быть словарем
	var json_dict := (res_json.result as Dictionary)
	if json_dict != null:
		modules_localization_data = json_dict
	
	file.close()

func _display_modules_names():
	var modules_root := modules.create_item()
	
	for name in modules_localization_data.keys():
		var item := modules.create_item(modules_root)
		item.set_text(0, name)
		item.set_text_align(0, HALIGN_CENTER)

# Инициализация. Порядок вызова функций важен!!!
func _ready():
	_resize_split_container()
	_read_json_file()
	_display_modules_names()
