extends Control

export(float, 0, 1) var split_min_anchor := 0.15
export(float, 0, 1) var split_max_anchor := 0.5

var cards := []
var modules_localization_data := {}

var selected_module_name: String = ""
var top_lang: String = ""
var bot_lang: String = ""

onready var split := ($Split as SplitContainer)
onready var modules := ($Split/ModulesPanel/Modules as ItemList)
onready var data_grid := ($Split/DataPanel/DataGrid as GridContainer)
onready var top_lang_select := ($Split/ModulesPanel/Buttons/TopLangSelect as MenuButton)
onready var bot_lang_select := ($Split/ModulesPanel/Buttons/BotLangSelect as MenuButton)
onready var card_class := (preload("res://scenes/Card.tscn") as PackedScene)

# Автоматический ресайз при изменении развмера контейнера или движиния раздилителя
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
	if json_dict == null:
		return
	
	modules_localization_data = json_dict
	if len(modules_localization_data.keys()) == 0:
		return
	
	selected_module_name = modules_localization_data.keys()[0]
	
	if len(modules_localization_data[selected_module_name]["supported"]) == 0:
		return
	
	top_lang = modules_localization_data[selected_module_name]["supported"][0]
	
	file.close()

# Вывод в левую понель названия модулей
func _display_modules_names():
	for name in modules_localization_data.keys():
		modules.add_item(name, null, true)

# При выборе модуля
func _on_module_selected(index: int):
	var keys = modules_localization_data.keys()
	selected_module_name = keys[index]
	_display_cards_on_data_grid()

# Фиксация выбора языка
func _on_top_lang_selected(id: int):
	top_lang = modules_localization_data[selected_module_name]["supported"][id]

func _on_bot_lang_selected(id: int):
	if top_lang != bot_lang:
		bot_lang = modules_localization_data[selected_module_name]["supported"][id]
	elif top_lang == null:
		top_lang = modules_localization_data[selected_module_name]["supported"][id]

# При нажатии верхней кнопки выбора языка
func _on_top_lang_select_dialog_show():
	var popup := (top_lang_select.get_popup() as PopupMenu)
	if popup == null or selected_module_name == "":
		return
	
	if typeof(modules_localization_data) != TYPE_DICTIONARY:
		print(typeof(modules_localization_data[selected_module_name]))
		return
	
	if typeof(modules_localization_data["lk"]) != TYPE_DICTIONARY:
		print(typeof(modules_localization_data[selected_module_name]))
		return
	
	popup.clear()
	for lang in modules_localization_data[selected_module_name]["supported"]:
		popup.add_item(lang)
	
	if popup.is_connected("id_pressed", self, "_on_top_lang_selected"):
		return
		
	var e := popup.connect("id_pressed", self, "_on_top_lang_selected")
	if e != OK:
		print("Cant connect signal in _on_top_lang_select_dialog_show()")
		print("Error code: " + str(e))

func _on_bot_lang_select_dialog_show():
	var popup := (bot_lang_select.get_popup() as PopupMenu)
	if popup == null or selected_module_name == "":
		return
	
	popup.clear()
	for lang in modules_localization_data[selected_module_name]["supported"]:
		popup.add_item(lang)
	
	if popup.is_connected("id_pressed", self, "_on_bot_lang_selected"):
		return
	
	var e := popup.connect("id_pressed", self, "_on_bot_lang_selected")
	if e != OK:
		print("Cant connect signal in _on_bot_lang_select_dialog_show()")
		print("Error code: " + str(e))

# Вывод данных на словарь
func _display_cards_on_data_grid():
	var strings_dict := (modules_localization_data[selected_module_name][top_lang] as Dictionary)
	if strings_dict == null:
		return
	
	for key in strings_dict.keys():
		var card = card_class.instance()
		data_grid.add_child(card)
		var bot_text := ""
		if bot_lang != "":
			if modules_localization_data[selected_module_name][bot_lang].has(key):
				bot_text = (modules_localization_data[selected_module_name][bot_lang][key] as String)
		
		card.prepare(key, top_lang, strings_dict[key], bot_lang, bot_text) 

# Инициализация.
func _ready():
	# [Warning] Порядок вызова функций важен
	_resize_split_container()
	_read_json_file()
	_display_modules_names()



