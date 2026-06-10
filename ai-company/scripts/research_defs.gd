class_name ResearchDefs
extends RefCounted

## Static research tree definitions.

class NodeInfo:
	var id: String
	var name: String
	var description: String
	var cost: float
	var work_needed: float
	var prerequisites: Array[String]
	var boosts: Array[AIProject.Type]
	var accuracy_bonus: float
	var safety_bonus: float
	var speed_bonus: float
	var starts_unlocked: bool = false


static func get_all() -> Array[NodeInfo]:
	var nodes: Array[NodeInfo] = []

	nodes.append(_n({
		"id": "basic_ml",
		"name": "基礎機械学習",
		"description": "初期技術。すべての開発の前提。",
		"cost": 0.0,
		"work": 0.0,
		"prereq": [],
		"boosts": [AIProject.Type.LLM, AIProject.Type.VISION, AIProject.Type.RECOMMEND],
		"acc": 2.0, "safe": 2.0, "spd": 2.0,
		"start": true,
	}))
	nodes.append(_n({
		"id": "word_embeddings",
		"name": "Word Embeddings",
		"description": "言語のベクトル表現。LLMの土台。",
		"cost": 8000.0,
		"work": 50.0,
		"prereq": ["basic_ml"],
		"boosts": [AIProject.Type.LLM],
		"acc": 4.0, "safe": 0.0, "spd": 1.0,
	}))
	nodes.append(_n({
		"id": "cnn",
		"name": "CNN",
		"description": "畳み込みニューラルネット。画像認識の基礎。",
		"cost": 8000.0,
		"work": 50.0,
		"prereq": ["basic_ml"],
		"boosts": [AIProject.Type.VISION],
		"acc": 5.0, "safe": 0.0, "spd": 2.0,
	}))
	nodes.append(_n({
		"id": "collab_filter",
		"name": "協調フィルタリング",
		"description": "ユーザー類似度に基づく推薦。",
		"cost": 7000.0,
		"work": 45.0,
		"prereq": ["basic_ml"],
		"boosts": [AIProject.Type.RECOMMEND],
		"acc": 4.0, "safe": 1.0, "spd": 3.0,
	}))
	nodes.append(_n({
		"id": "transformer",
		"name": "Transformer",
		"description": "Attention機構。現代LLMの中核。",
		"cost": 18000.0,
		"work": 90.0,
		"prereq": ["word_embeddings"],
		"boosts": [AIProject.Type.LLM],
		"acc": 10.0, "safe": 0.0, "spd": -2.0,
	}))
	nodes.append(_n({
		"id": "diffusion",
		"name": "Diffusion",
		"description": "拡散モデル。画像生成・認識に強い。",
		"cost": 20000.0,
		"work": 95.0,
		"prereq": ["cnn"],
		"boosts": [AIProject.Type.VISION],
		"acc": 9.0, "safe": 2.0, "spd": -4.0,
	}))
	nodes.append(_n({
		"id": "rlhf",
		"name": "RLHF",
		"description": "人間のフィードバックで安全性を改善。",
		"cost": 16000.0,
		"work": 70.0,
		"prereq": ["transformer"],
		"boosts": [AIProject.Type.LLM],
		"acc": -1.0, "safe": 12.0, "spd": -1.0,
	}))
	nodes.append(_n({
		"id": "bandits",
		"name": "バンディット最適化",
		"description": "推薦の探索と活用のバランス。",
		"cost": 14000.0,
		"work": 65.0,
		"prereq": ["collab_filter"],
		"boosts": [AIProject.Type.RECOMMEND],
		"acc": 6.0, "safe": 3.0, "spd": 2.0,
	}))
	nodes.append(_n({
		"id": "multimodal",
		"name": "マルチモーダル",
		"description": "言語と画像を統合。全製品に小幅ボーナス。",
		"cost": 35000.0,
		"work": 120.0,
		"prereq": ["transformer", "diffusion"],
		"boosts": [AIProject.Type.LLM, AIProject.Type.VISION, AIProject.Type.RECOMMEND],
		"acc": 5.0, "safe": 4.0, "spd": 1.0,
	}))

	return nodes


static func _n(data: Dictionary) -> NodeInfo:
	var info := NodeInfo.new()
	info.id = data.id
	info.name = data.name
	info.description = data.description
	info.cost = data.cost
	info.work_needed = data.work
	info.prerequisites.assign(data.prereq)
	info.boosts.assign(data.boosts)
	info.accuracy_bonus = data.acc
	info.safety_bonus = data.safe
	info.speed_bonus = data.spd
	info.starts_unlocked = data.get("start", false)
	return info
