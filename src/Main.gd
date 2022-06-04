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
onready var data_grid := ($Split/DataPanel/ScrollContainer/Cards as VBoxContainer)
onready var top_lang_select := ($Split/ModulesPanel/Buttons/TopLangSelect as MenuButton)
onready var bot_lang_select := ($Split/ModulesPanel/Buttons/BotLangSelect as MenuButton)
onready var add_key_dialog := ($AddKeyDialog as Popup)
onready var key_line_editor := ($AddKeyDialog/NewKeyLineEditor as LineEdit)

onready var card_class := (preload("res://scenes/Card.tscn") as PackedScene)

func _on_cards_text_changed(key: String, lang: String, text: String):
	modules_localization_data[selected_module_name][lang][key] = text

func _on_card_delete_key(key: String):
	for lang in modules_localization_data[selected_module_name]["supported"]:
		modules_localization_data[selected_module_name][lang].erase(key)
	_display_cards_on_data_grid()

func _require_cards(n: int):
	if data_grid.get_child_count() > n:
		for i in range(n, data_grid.get_child_count()):
			data_grid.remove_child(cards[i])
	elif len(cards) < n:
		for i in range(len(cards), n):
			var card = card_class.instance()
			card.connect("changed_text", self, "_on_cards_text_changed")
			card.connect("delete_key", self, "_on_card_delete_key")
			cards.append(card)
			data_grid.add_child(card)
	elif data_grid.get_child_count() < n:
		for i in range(data_grid.get_child_count(), n):
			print("Hi " + str(data_grid.get_child_count()))
			data_grid.add_child(cards[i])

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
	
	file.close()

# Вывод в левую понель названия модулей
func _display_modules_names():
	for name in modules_localization_data.keys():
		modules.add_item(name, null, true)

# При выборе модуля
func _on_module_selected(index: int):
	var keys = modules_localization_data.keys()
	selected_module_name = keys[index]
	top_lang = modules_localization_data[selected_module_name]["supported"][0]
	bot_lang = ""
	_display_cards_on_data_grid()

# Фиксация выбора языка
func _on_top_lang_selected(id: int):
	top_lang = modules_localization_data[selected_module_name]["supported"][id]
	if top_lang == bot_lang:
		bot_lang = ""
	_require_cards(len(modules_localization_data[selected_module_name][top_lang]))
	_display_cards_on_data_grid()

func _on_bot_lang_selected(id: int):
	if top_lang != bot_lang:
		bot_lang = modules_localization_data[selected_module_name]["supported"][id]
		_require_cards(len(modules_localization_data[selected_module_name][bot_lang]))
		_display_cards_on_data_grid()

# При нажатии верхней кнопки выбора языка
func _on_top_lang_select_dialog_show():
	var popup := (top_lang_select.get_popup() as PopupMenu)
	if popup == null or selected_module_name == "":
		return
	
	popup.clear()
	for lang in modules_localization_data[selected_module_name]["supported"]:
		popup.add_item(lang)

func _on_bot_lang_select_dialog_show():
	var popup := (bot_lang_select.get_popup() as PopupMenu)
	if popup == null or selected_module_name == "":
		return
	
	popup.clear()
	for lang in modules_localization_data[selected_module_name]["supported"]:
		popup.add_item(lang)

# Вывод данных на словарь
func _display_cards_on_data_grid():
	var strings_dict := (modules_localization_data[selected_module_name][top_lang] as Dictionary)
	if strings_dict == null:
		return
	
	_require_cards(len(strings_dict))
	
	var card_i := 0
	for key in strings_dict.keys():
		var card = cards[card_i]; card_i += 1
		var bot_text := ""
		if bot_lang != "":
			if modules_localization_data[selected_module_name][bot_lang].has(key):
				bot_text = (modules_localization_data[selected_module_name][bot_lang][key] as String)
		
		card.prepare(key, top_lang, strings_dict[key], bot_lang, bot_text) 

# Инициализация.
func _ready():
	top_lang_select.get_popup().connect("id_pressed", self, "_on_top_lang_selected")
	bot_lang_select.get_popup().connect("id_pressed", self, "_on_bot_lang_selected")
	
	# [Warning] Порядок вызова функций важен
	_resize_split_container()
	_read_json_file()
	
	if len(modules_localization_data) != 0:
		_on_module_selected(0)
	
	_display_modules_names()

func _on_save_button_pressed():
	var content = JSON.print(modules_localization_data, "\t")
	var file := File.new()
	var err := file.open("locale.json", file.WRITE)
	
	if err != OK:
		return
	
	file.store_string(content)
	file.close()

func _on_add_key_button_pressed():
	add_key_dialog.popup()

func _on_add_key_dialog_confirmed():
	var text = key_line_editor.text.trim_prefix(" ").trim_suffix(" ")
	if text == "":
		return
	for lang in modules_localization_data[selected_module_name]["supported"]:
		modules_localization_data[selected_module_name][lang][text] = "" 
	_display_cards_on_data_grid()
	
