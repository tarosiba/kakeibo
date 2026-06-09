extends CanvasLayer

signal closed

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var rating_label: Label = $Panel/Margin/VBox/RatingLabel
@onready var product_option: OptionButton = $Panel/Margin/VBox/ProductOption
@onready var chat_log: RichTextLabel = $Panel/Margin/VBox/ChatLog
@onready var status_label: Label = $Panel/Margin/VBox/StatusLabel
@onready var input_edit: LineEdit = $Panel/Margin/VBox/InputRow/InputEdit
@onready var send_btn: Button = $Panel/Margin/VBox/InputRow/SendBtn
@onready var settings_btn: Button = $Panel/Margin/VBox/ButtonRow/SettingsBtn
@onready var close_btn: Button = $Panel/Margin/VBox/ButtonRow/CloseBtn
@onready var settings_dialog: AcceptDialog = $LlmSettings

var _products: Array[AIProject] = []


func _ready() -> void:
	visible = false
	send_btn.pressed.connect(_on_send_pressed)
	close_btn.pressed.connect(_close)
	settings_btn.pressed.connect(func(): settings_dialog.open_settings())
	input_edit.text_submitted.connect(func(_t): _on_send_pressed())


func open_demo(products: Array[AIProject]) -> void:
	_products = products
	product_option.clear()
	for i in products.size():
		product_option.add_item(products[i].project_name, i)

	if products.is_empty():
		return

	title_label.text = "製品デモチャット（任意・演出機能）"
	rating_label.text = "※外部AI利用時は予期しない応答があり得ます。全年齢向けフィルタを推奨します。"
	_append_system_line("LLM製品のデモルームです。API未設定でもオフライン応答で遊べます。")
	_update_status()
	visible = true
	input_edit.grab_focus()


func _close() -> void:
	visible = false
	closed.emit()


func _on_send_pressed() -> void:
	if LlmClient.is_busy():
		return
	var product := _get_selected_product()
	if product == null:
		return

	var user_text := input_edit.text
	input_edit.text = ""
	_append_user_line(user_text)

	_set_interaction_locked(true)
	status_label.text = "考え中..."

	var result: Dictionary = await LlmClient.chat(product, user_text)

	_set_interaction_locked(false)
	_append_bot_line(str(result.text), str(result.code), bool(result.used_fallback))
	_update_status()


func _get_selected_product() -> AIProject:
	if _products.is_empty():
		return null
	var idx := product_option.get_selected_id()
	if idx < 0 or idx >= _products.size():
		return _products[0]
	return _products[idx]


func _set_interaction_locked(locked: bool) -> void:
	send_btn.disabled = locked
	input_edit.editable = not locked
	product_option.disabled = locked
	if locked:
		status_label.text = "考え中..."


func _update_status() -> void:
	var remaining := LlmClient.get_remaining_requests()
	var mode := "外部AI" if LlmConfig.is_configured() else "オフライン"
	status_label.text = "モード: %s | 残りリクエスト: %d / %d" % [
		mode, remaining, LlmConfig.max_requests_per_session
	]


func _append_user_line(text: String) -> void:
	chat_log.append_text("\n[あなた] %s" % text)


func _append_bot_line(text: String, code: String, used_fallback: bool) -> void:
	var suffix := ""
	if used_fallback:
		match code:
			LlmClient.LIMIT_REACHED:
				suffix = "（上限到達・オフライン応答）"
			LlmClient.API_ERROR:
				suffix = "（API接続失敗・オフライン応答）"
			LlmClient.FALLBACK_USED:
				suffix = "（オフライン応答）"
			LlmClient.FILTERED:
				suffix = "（フィルタ適用）"
	chat_log.append_text("\n[AI] %s%s" % [text, suffix])


func _append_system_line(text: String) -> void:
	chat_log.append_text("[システム] %s" % text)
