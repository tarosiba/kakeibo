class_name ContentFilter
extends RefCounted
## Lightweight output filter for external LLM responses.

const MAX_OUTPUT_CHARS := 600

const BLOCKED_PATTERNS: Array[String] = [
	"殺して", "死ね", "自殺", "リンチ", "テロ",
	"fuck", "shit", "kill yourself", "suicide",
]


static func sanitize(text: String, family_safe: bool) -> Dictionary:
	var cleaned := text.strip_edges()
	if cleaned == "":
		return {"ok": false, "text": "（応答を取得できませんでした）", "reason": "empty"}

	cleaned = cleaned.replace("\n\n", "\n")
	if cleaned.length() > MAX_OUTPUT_CHARS:
		cleaned = cleaned.substr(0, MAX_OUTPUT_CHARS) + "…"

	if not family_safe:
		return {"ok": true, "text": cleaned, "reason": ""}

	var lower := cleaned.to_lower()
	for pattern in BLOCKED_PATTERNS:
		if lower.contains(pattern.to_lower()):
			return {
				"ok": false,
				"text": "（不適切な内容の可能性があるため、安全な代替メッセージを表示しています）",
				"reason": "blocked_pattern",
			}

	return {"ok": true, "text": cleaned, "reason": ""}


static func sanitize_input(text: String) -> Dictionary:
	var cleaned := text.strip_edges()
	if cleaned == "":
		return {"ok": false, "text": "", "reason": "empty"}
	if cleaned.length() > 280:
		cleaned = cleaned.substr(0, 280)
	return {"ok": true, "text": cleaned, "reason": ""}
