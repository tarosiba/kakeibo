extends Node
## Loads LLM settings from user://config.cfg and OS environment variables.
## API keys are never stored in source code.

signal config_changed

const CONFIG_PATH := "user://llm_config.cfg"

const ENV_API_KEY := "AI_COMPANY_API_KEY"
const ENV_API_URL := "AI_COMPANY_API_URL"
const ENV_MODEL := "AI_COMPANY_MODEL"
const ENV_PROVIDER := "AI_COMPANY_PROVIDER"

enum Provider { OLLAMA, OPENAI_COMPAT }

var enabled: bool = false
var provider: Provider = Provider.OLLAMA
var api_url: String = "http://127.0.0.1:11434/api/chat"
var model: String = "llama3.2"
var max_requests_per_session: int = 15
var request_timeout_sec: float = 30.0
var content_filter_enabled: bool = true
var family_safe_mode: bool = true

var _api_key: String = ""


func _ready() -> void:
	load_config()


func is_configured() -> bool:
	if not enabled:
		return false
	if provider == Provider.OPENAI_COMPAT:
		return get_api_key() != ""
	return api_url != ""


func get_api_key() -> String:
	var from_env := OS.get_environment(ENV_API_KEY)
	if from_env != "":
		return from_env.strip_edges()
	return _api_key


func set_api_key(value: String) -> void:
	_api_key = value.strip_edges()


func load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		_apply_environment_overrides()
		config_changed.emit()
		return

	enabled = bool(cfg.get_value("llm", "enabled", enabled))
	provider = int(cfg.get_value("llm", "provider", provider)) as Provider
	api_url = str(cfg.get_value("llm", "api_url", api_url))
	model = str(cfg.get_value("llm", "model", model))
	_api_key = str(cfg.get_value("llm", "api_key", ""))
	max_requests_per_session = int(cfg.get_value("llm", "max_requests_per_session", max_requests_per_session))
	request_timeout_sec = float(cfg.get_value("llm", "request_timeout_sec", request_timeout_sec))
	content_filter_enabled = bool(cfg.get_value("llm", "content_filter_enabled", content_filter_enabled))
	family_safe_mode = bool(cfg.get_value("llm", "family_safe_mode", family_safe_mode))

	_apply_environment_overrides()
	config_changed.emit()


func save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("llm", "enabled", enabled)
	cfg.set_value("llm", "provider", provider)
	cfg.set_value("llm", "api_url", api_url)
	cfg.set_value("llm", "model", model)
	cfg.set_value("llm", "api_key", _api_key)
	cfg.set_value("llm", "max_requests_per_session", max_requests_per_session)
	cfg.set_value("llm", "request_timeout_sec", request_timeout_sec)
	cfg.set_value("llm", "content_filter_enabled", content_filter_enabled)
	cfg.set_value("llm", "family_safe_mode", family_safe_mode)
	cfg.save(CONFIG_PATH)
	config_changed.emit()


func _apply_environment_overrides() -> void:
	var env_key := OS.get_environment(ENV_API_KEY)
	if env_key != "":
		_api_key = env_key.strip_edges()

	var env_url := OS.get_environment(ENV_API_URL)
	if env_url != "":
		api_url = env_url.strip_edges()

	var env_model := OS.get_environment(ENV_MODEL)
	if env_model != "":
		model = env_model.strip_edges()

	var env_provider := OS.get_environment(ENV_PROVIDER)
	if env_provider != "":
		match env_provider.to_lower():
			"ollama":
				provider = Provider.OLLAMA
			"openai", "openai_compat":
				provider = Provider.OPENAI_COMPAT


func get_provider_name() -> String:
	return "Ollama" if provider == Provider.OLLAMA else "OpenAI互換"
