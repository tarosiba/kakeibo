extends AcceptDialog

@onready var enabled_check: CheckBox = $Margin/Grid/EnabledCheck
@onready var provider_option: OptionButton = $Margin/Grid/ProviderOption
@onready var url_edit: LineEdit = $Margin/Grid/UrlEdit
@onready var model_edit: LineEdit = $Margin/Grid/ModelEdit
@onready var key_edit: LineEdit = $Margin/Grid/KeyEdit
@onready var max_req_spin: SpinBox = $Margin/Grid/MaxReqSpin
@onready var timeout_spin: SpinBox = $Margin/Grid/TimeoutSpin
@onready var filter_check: CheckBox = $Margin/Grid/FilterCheck
@onready var family_check: CheckBox = $Margin/Grid/FamilyCheck
@onready var env_hint: Label = $Margin/Grid/EnvHint


func _ready() -> void:
	title = "LLM設定（任意機能）"
	provider_option.clear()
	provider_option.add_item("Ollama（ローカル）", LlmConfig.Provider.OLLAMA)
	provider_option.add_item("OpenAI互換API", LlmConfig.Provider.OPENAI_COMPAT)
	confirmed.connect(_on_save)
	_load_values()


func open_settings() -> void:
	_load_values()
	popup_centered(Vector2i(520, 420))


func _load_values() -> void:
	enabled_check.button_pressed = LlmConfig.enabled
	provider_option.select(LlmConfig.provider)
	url_edit.text = LlmConfig.api_url
	model_edit.text = LlmConfig.model
	key_edit.text = LlmConfig.get_api_key()
	max_req_spin.value = LlmConfig.max_requests_per_session
	timeout_spin.value = LlmConfig.request_timeout_sec
	filter_check.button_pressed = LlmConfig.content_filter_enabled
	family_check.button_pressed = LlmConfig.family_safe_mode
	env_hint.text = "環境変数でも上書き可: %s, %s" % [LlmConfig.ENV_API_KEY, LlmConfig.ENV_API_URL]


func _on_save() -> void:
	LlmConfig.enabled = enabled_check.button_pressed
	LlmConfig.provider = provider_option.get_selected_id() as LlmConfig.Provider
	LlmConfig.api_url = url_edit.text.strip_edges()
	LlmConfig.model = model_edit.text.strip_edges()
	LlmConfig.set_api_key(key_edit.text)
	LlmConfig.max_requests_per_session = int(max_req_spin.value)
	LlmConfig.request_timeout_sec = timeout_spin.value
	LlmConfig.content_filter_enabled = filter_check.button_pressed
	LlmConfig.family_safe_mode = family_check.button_pressed
	LlmConfig.save_config()
