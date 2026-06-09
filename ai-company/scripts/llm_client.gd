extends Node
## Optional LLM chat client. Game works fully without this.

signal chat_completed(result: Dictionary)

const FALLBACK_USED := "fallback"
const LIMIT_REACHED := "limit_reached"
const API_ERROR := "api_error"
const FILTERED := "filtered"

var session_request_count: int = 0

var _http: HTTPRequest = null
var _busy: bool = false


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)


func reset_session() -> void:
	session_request_count = 0


func get_remaining_requests() -> int:
	return maxi(0, LlmConfig.max_requests_per_session - session_request_count)


func can_send_request() -> bool:
	return not _busy and get_remaining_requests() > 0


func is_busy() -> bool:
	return _busy


func build_system_prompt(product: AIProject) -> String:
	var reliability := "やや不安定で、時々曖昧"
	if product.accuracy >= 80.0:
		reliability = "比較的正確"
	elif product.accuracy >= 65.0:
		reliability = "まずまず正確"

	var safety_note := "安全配慮は十分"
	if product.safety < 50.0:
		safety_note = "安全性に課題があり、過激・不適切な表現に注意"
	elif product.safety < 70.0:
		safety_note = "安全性は標準的"

	var lines: PackedStringArray = [
		"あなたは架空のスタートアップが開発したAIアシスタント「%s」です。" % product.project_name,
		"これはゲーム内の製品デモです。現実の個人情報・医療・法律の断定助言はしないでください。",
		"モデル特性: %s。%s。" % [reliability, safety_note],
		"200字以内、丁寧で家族向けの日本語で答えてください。",
		"暴力・差別・性的・自傷・違法行為を助長する内容は拒否してください。",
	]
	if LlmConfig.family_safe_mode:
		lines.append("全年齢向けの表現のみ使用してください。")
	return "\n".join(lines)


func chat(product: AIProject, user_message: String) -> Dictionary:
	var input_check := ContentFilter.sanitize_input(user_message)
	if not input_check.ok:
		return _result(false, "メッセージを入力してください。", "invalid_input", true)

	if not LlmConfig.is_configured():
		return _result(true, _mock_reply(product, input_check.text), FALLBACK_USED, true)

	if get_remaining_requests() <= 0:
		return _result(true, _mock_reply(product, input_check.text), LIMIT_REACHED, true)

	_busy = true
	session_request_count += 1

	var api_result: Dictionary
	if LlmConfig.provider == LlmConfig.Provider.OLLAMA:
		api_result = await _request_ollama(input_check.text, product)
	else:
		api_result = await _request_openai_compat(input_check.text, product)

	_busy = false

	if not api_result.ok:
		var fallback := _mock_reply(product, input_check.text)
		return _result(true, fallback, api_result.get("code", API_ERROR), true)

	var filtered := _apply_output_filter(str(api_result.text))
	chat_completed.emit(filtered)
	return filtered


func _apply_output_filter(text: String) -> Dictionary:
	if not LlmConfig.content_filter_enabled:
		return _result(true, text, "ok", false)
	var sanitized := ContentFilter.sanitize(text, LlmConfig.family_safe_mode)
	if sanitized.ok:
		return _result(true, sanitized.text, "ok", false)
	return _result(true, sanitized.text, FILTERED, false)


func _request_ollama(user_message: String, product: AIProject) -> Dictionary:
	var body := {
		"model": LlmConfig.model,
		"messages": [
			{"role": "system", "content": build_system_prompt(product)},
			{"role": "user", "content": user_message},
		],
		"stream": false,
	}
	return await _http_json(LlmConfig.api_url, [], body)


func _request_openai_compat(user_message: String, product: AIProject) -> Dictionary:
	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % LlmConfig.get_api_key(),
	]
	var body := {
		"model": LlmConfig.model,
		"messages": [
			{"role": "system", "content": build_system_prompt(product)},
			{"role": "user", "content": user_message},
		],
	}
	var url := LlmConfig.api_url
	if url == "":
		url = "https://api.openai.com/v1/chat/completions"
	return await _http_json(url, headers, body)


func _http_json(url: String, headers: PackedStringArray, body: Dictionary) -> Dictionary:
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http.cancel_request()

	_http.timeout = LlmConfig.request_timeout_sec
	var err := _http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		return {"ok": false, "text": "", "code": API_ERROR}

	var packed: PackedStringArray = await _http.request_completed
	var result_code: int = packed[0]
	var response_code: int = packed[1]
	var response_body: PackedByteArray = packed[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "text": "", "code": API_ERROR}
	if response_code < 200 or response_code >= 300:
		return {"ok": false, "text": "", "code": API_ERROR}

	var parsed = JSON.parse_string(response_body.get_string_from_utf8())
	if parsed == null:
		return {"ok": false, "text": "", "code": API_ERROR}

	var text := _extract_message_text(parsed)
	if text == "":
		return {"ok": false, "text": "", "code": API_ERROR}
	return {"ok": true, "text": text, "code": "ok"}


func _extract_message_text(parsed: Variant) -> String:
	if parsed is Dictionary:
		if parsed.has("message") and parsed.message is Dictionary:
			return str(parsed.message.get("content", ""))
		var choices = parsed.get("choices", [])
		if choices is Array and choices.size() > 0:
			var first = choices[0]
			if first is Dictionary:
				var msg = first.get("message", {})
				if msg is Dictionary:
					return str(msg.get("content", ""))
	return ""


func _mock_reply(product: AIProject, user_message: String) -> String:
	var options: Array[String] = [
		"ご質問「%s」について、%s の知識ベースで回答します。現時点の精度は%.0f%%です。" % [
			user_message, product.project_name, product.accuracy
		],
		"%s は社内デモ版です。安全性スコア%.0fのため、慎重な表現でお答えします。" % [
			product.project_name, product.safety
		],
		"オフラインモードです。%s として、一般的な説明にとどめます。" % product.project_name,
	]
	return options[randi() % options.size()]


func _result(ok: bool, text: String, code: String, used_fallback: bool) -> Dictionary:
	return {
		"ok": ok,
		"text": text,
		"code": code,
		"used_fallback": used_fallback,
		"remaining": get_remaining_requests(),
	}
