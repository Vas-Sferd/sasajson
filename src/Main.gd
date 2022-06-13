extends Control

export(String) var default_file_name: String = ""

export(float, 0, 1) var split_min_anchor := 0.15
export(float, 0, 1) var split_max_anchor := 0.5

#Dependency
const card_class := preload("res://scenes/Card.tscn")

# Data storages
var cards := []
var modules_localization_data := {}

# Selected data
var selected_module_name: String = ""
var top_lang: String = ""
var bot_lang: String = ""

# Base Gui
onready var split := ($Split as SplitContainer)
onready var modules := ($Split/ModulesPanel/Modules as ItemList)
onready var data_grid := ($Split/DataPanel/ScrollContainer/Cards as VBoxContainer)

# Language selection
onready var top_lang_select := ($Split/ModulesPanel/Buttons/TopLangSelect as MenuButton)
onready var bot_lang_select := ($Split/ModulesPanel/Buttons/BotLangSelect as MenuButton)

# Add key dialog
onready var add_key_dialog := ($AddKeyDialog as Popup)
onready var key_line_editor := ($AddKeyDialog/NewKeyLineEditor as LineEdit)

# Add lang dialog
onready var add_lang_dialog := ($AddLangDialog as Popup)
onready var lang_line_editor := ($AddLangDialog/NewLangLineEditor as LineEdit)

# Module dialog
onready var add_module_dialog := ($AddModuleDialog as Popup)
onready var module_line_editor := ($AddModuleDialog/DialogControl/ModuleNameControl/ModuleNameLineEditor as LineEdit)
onready var module_lang_line_editor := ($AddModuleDialog/DialogControl/LangControl/LangLineEditor as LineEdit)

# File dialog
onready var file_dialog := ($FileDialog as FileDialog)

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
		for _i in range(len(cards), n):
			var card = card_class.instance()
			card.connect("changed_text", self, "_on_cards_text_changed")
			card.connect("delete_key", self, "_on_card_delete_key")
			cards.append(card)
			data_grid.add_child(card)
	elif data_grid.get_child_count() < n:
		for i in range(data_grid.get_child_count(), n):
			data_grid.add_child(cards[i])

# Автоматический ресайз при изменении развмера контейнера или движиния раздилителя
func _resize_split_container(offset: int = -1):
	if split != null:
		if offset == -1:
			offset = split.split_offset
		
		var width := float(split.rect_size.x)
		split.split_offset = int(width * clamp(offset / width, split_min_anchor, split_max_anchor))

# Открываем файл и считываем из него данные. А затем закрываем
func _read_json_file(path):
	var file := File.new()
	var err := file.open(path, file.READ)
	
	if err != OK:
		return
	
	var res_json := JSON.parse(file.get_as_text())
	file.close()
	
	if res_json.error != OK:
		return
	
	# Наши данные должны быть словарем
	var json_dict := (res_json.result as Dictionary)
	if json_dict == null:
		return
	
	modules_localization_data = json_dict
	if len(modules_localization_data.keys()) == 0:
		return

func _save_json_file(path: String):
	var content = JSON.print(modules_localization_data, "\t")
	var file := File.new()
	var err := file.open(path, file.WRITE)
	
	if err != OK:
		return
	
	file.store_string(content)
	file.close()

# Вывод в левую понель названия модулей
func _display_modules_names():
	modules.clear()
	for name in modules_localization_data.keys():
		modules.add_item(name, null, true)

# При выборе модуля
func _on_module_selected(index: int):
	var keys = modules_localization_data.keys()
	selected_module_name = keys[index]
	set_top_lang(modules_localization_data[selected_module_name]["supported"][0])
	bot_lang = ""
	_display_cards_on_data_grid()

# Фиксация выбора языка
func set_top_lang(lang: String):
	top_lang = lang
	top_lang_select.text = top_lang
	if top_lang == bot_lang:
		bot_lang = ""
		bot_lang_select.text = ""
	_display_cards_on_data_grid()

func _on_top_lang_selected(id: int):
	var lang = modules_localization_data[selected_module_name]["supported"][id]
	set_top_lang(lang)

func set_bot_lang(lang: String):
	if top_lang != lang:
		bot_lang = lang
		bot_lang_select.text = bot_lang
	elif top_lang != bot_lang and bot_lang != "":
		set_top_lang(bot_lang)
		set_bot_lang(lang)
	_display_cards_on_data_grid()

func _on_bot_lang_selected(id: int):
	var lang = modules_localization_data[selected_module_name]["supported"][id]
	set_bot_lang(lang)

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
	_read_json_file("locale.json")
	
	if len(modules_localization_data) != 0:
		_on_module_selected(0)
	
	_display_modules_names()

func _on_save_button_pressed():
	file_dialog.window_title = "Save file"
	file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.popup()

func _on_load_button_pressed():
	file_dialog.window_title = "Load file"
	file_dialog.mode = FileDialog.MODE_OPEN_FILE
	file_dialog.popup()

func _on_file_selected(path):
	match file_dialog.mode:
		FileDialog.MODE_SAVE_FILE:
			_save_json_file(path)
		FileDialog.MODE_OPEN_FILE:
			_read_json_file(path)
			_display_modules_names()
			_display_cards_on_data_grid()
		_:
			pass

func _on_add_key_button_pressed():
	add_key_dialog.popup()

func _on_add_key_dialog_confirmed():
	var key = key_line_editor.text.trim_prefix(" ").trim_suffix(" ")
	key_line_editor.text = ""
	if key == "":
		_on_add_key_button_pressed()
		return
	for lang in modules_localization_data[selected_module_name]["supported"]:
		modules_localization_data[selected_module_name][lang][key] = "" 
	_display_cards_on_data_grid()
	
func _on_add_lang_button_pressed():
	add_lang_dialog.popup()

func _on_add_lang_dialog_confirmed():
	var lang = lang_line_editor.text.trim_prefix(" ").trim_suffix(" ")
	lang_line_editor.text = ""
	if lang == "" or lang == "supported" or lang == "autogenerated":
		_on_add_lang_button_pressed()
		return
	
	if modules_localization_data[selected_module_name]["supported"].has(lang):
		_on_add_lang_button_pressed()
		return
	
	modules_localization_data[selected_module_name]["supported"].append(lang)
	modules_localization_data[selected_module_name][lang] = {}
	for key in modules_localization_data[selected_module_name][top_lang]:
		modules_localization_data[selected_module_name][lang][key] = ""
	bot_lang = lang
	_display_cards_on_data_grid()


func _on_add_module_button_pressed():
	add_module_dialog.popup()

func _on_add_module_dialog_confirmed():
	var name = module_line_editor.text.trim_prefix(" ").trim_suffix(" ")
	var lang = module_lang_line_editor.text.trim_prefix(" ").trim_suffix(" ")
	if name == "" or lang == "":
		_on_add_module_button_pressed()
		return
	
	modules_localization_data[name] = { "supported" : [lang], "autogenerated" : [], lang : {} }
	selected_module_name = name
	_display_modules_names()
	_display_cards_on_data_grid()
