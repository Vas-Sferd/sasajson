extends Panel

onready var key_label := ($Items/Key as Label)
onready var top_language_label := ($Items/Top/Label as Label)
onready var top_text_edit := ($Items/Top/TextEdit as TextEdit)
onready var bot_language_label := ($Items/Bot/Label as Label)
onready var bot_text_edit := ($Items/Bot/TextEdit as TextEdit)

signal changed_text(key, lang, text)

func _on_top_text_changed():
	emit_signal("changed_text", key_label.text, top_language_label.text, top_text_edit.text)

func _on_bot_text_changed():
	emit_signal("changed_text", key_label.text, bot_language_label.text, bot_text_edit.text)

func _prepare_top(top_lang: String, top_text: String):
	top_language_label.text = top_lang
	top_text_edit.text = top_text

func _prepare_bot(bot_lang: String, bot_text: String):
	if bot_lang == "":
		bot_language_label.visible = false
		bot_text_edit.visible = false	
		return
	
	bot_language_label.text = bot_lang
	bot_text_edit.text = bot_text

func prepare(key: String, top_lang: String, top_text: String, bot_lang: String, bot_text: String):
	key_label.text = key
	_prepare_top(top_lang, top_text)
	_prepare_bot(bot_lang, bot_text)
