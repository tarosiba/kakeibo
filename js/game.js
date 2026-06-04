/**
 * 現代国家シミュレーター — シンプルな国家運営ゲーム
 */

const SAVE_VERSION = 1;
const SAVE_PREFIX = "nation-sim-v1-";
const AUTOSAVE_SLOT = "autosave";
const MANUAL_SLOTS = ["slot1", "slot2", "slot3"];

const COUNTRIES = [
  { id: "japan", name: "日本", flag: "🇯🇵", gdp: 4200, treasury: 800, stability: 72, industry: 85, welfare: 78, map: { x: 286, y: 42 } },
  { id: "usa", name: "アメリカ", flag: "🇺🇸", gdp: 28000, treasury: 1200, stability: 65, industry: 90, welfare: 60, map: { x: 72, y: 48 } },
  { id: "brazil", name: "ブラジル", flag: "🇧🇷", gdp: 2200, treasury: 350, stability: 55, industry: 55, welfare: 48, map: { x: 108, y: 108 } },
  { id: "nigeria", name: "ナイジェリア", flag: "🇳🇬", gdp: 480, treasury: 120, stability: 48, industry: 35, welfare: 35, map: { x: 168, y: 88 } },
];

const AI_NATIONS = [
  { id: "china", name: "中国", flag: "🇨🇳", map: { x: 252, y: 52 } },
  { id: "eu", name: "EU", flag: "🇪🇺", map: { x: 178, y: 38 } },
  { id: "india", name: "インド", flag: "🇮🇳", map: { x: 228, y: 72 } },
];

const CONTINENTS = [
  "M 25,55 L 35,35 L 55,28 L 75,32 L 88,42 L 95,58 L 88,78 L 72,95 L 55,108 L 38,102 L 28,88 L 22,72 Z",
  "M 108,28 L 125,22 L 148,25 L 168,32 L 185,42 L 195,55 L 198,72 L 192,88 L 178,98 L 158,102 L 138,98 L 122,88 L 112,72 L 108,52 Z",
  "M 168,88 L 185,82 L 205,85 L 218,95 L 222,108 L 215,118 L 198,122 L 178,118 L 168,108 Z",
  "M 252,108 L 268,102 L 285,108 L 292,118 L 285,128 L 268,132 L 252,125 Z",
];

const MAX_TURNS = 20;
const COST = { industry: 50, welfare: 40, infra: 35, diplomacy: 25 };

let state = null;
let selectedMapNation = null;

function init() {
  renderCountrySelect();
  renderStartSaves();
  document.getElementById("btn-next-turn").addEventListener("click", nextTurn);
  document.getElementById("btn-restart").addEventListener("click", () => restart(true));
  document.getElementById("btn-play-again").addEventListener("click", () => restart(true));
  document.getElementById("tax-rate").addEventListener("input", onTaxChange);
  document.getElementById("btn-save").addEventListener("click", openSaveDialog);
  document.getElementById("btn-save-cancel").addEventListener("click", () => {
    document.getElementById("save-dialog").close();
  });

  document.querySelectorAll("[data-action]").forEach((btn) => {
    btn.addEventListener("click", () => doPolicy(btn.dataset.action));
  });
}

function allNations() {
  return [...COUNTRIES, ...AI_NATIONS];
}

function getNation(id) {
  return allNations().find((n) => n.id === id);
}

function renderCountrySelect() {
  const el = document.getElementById("country-select");
  el.innerHTML = COUNTRIES.map(
    (c) => `
    <button type="button" class="country-card" data-id="${c.id}">
      <span class="flag">${c.flag}</span>
      <h3>${c.name}</h3>
      <p>GDP ${c.gdp}億ドル · 安定 ${c.stability}%</p>
    </button>`
  ).join("");

  el.querySelectorAll(".country-card").forEach((card) => {
    card.addEventListener("click", () => startGame(card.dataset.id));
  });
}

function startGame(countryId) {
  const base = COUNTRIES.find((c) => c.id === countryId);
  state = createInitialState(base);
  selectedMapNation = null;
  log(`元首として${base.name}の統治を開始しました。`);
  showScreen("screen-game");
  render();
  autoSave();
}

function createInitialState(base) {
  const s = {
    player: { ...base },
    turn: 1,
    year: 2026,
    quarter: 1,
    taxRate: 20,
    tradeDeals: {},
    relations: Object.fromEntries(AI_NATIONS.map((n) => [n.id, randInt(20, 50)])),
    exports: 0,
    log: [],
    savedAt: null,
  };
  AI_NATIONS.forEach((n) => {
    s.tradeDeals[n.id] = false;
  });
  return s;
}

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function showScreen(id) {
  document.querySelectorAll(".screen").forEach((s) => s.classList.remove("active"));
  document.getElementById(id).classList.add("active");
}

function log(msg) {
  state.log.unshift({ turn: state.turn, year: state.year, q: state.quarter, msg });
  if (state.log.length > 30) state.log.pop();
}

function formatNum(n) {
  if (Math.abs(n) >= 1000) return (n / 1000).toFixed(1) + "兆";
  return Math.round(n) + "億";
}

function relationColor(rel) {
  if (rel >= 50) return "#3ecf8e";
  if (rel >= 0) return "#f0b429";
  return "#f56565";
}

function isPlayerNation(id) {
  return state && state.player.id === id;
}

function isAiNation(id) {
  return AI_NATIONS.some((n) => n.id === id);
}

function renderWorldMap() {
  const svg = document.getElementById("world-map");
  const p = state.player;
  let html = `<rect class="ocean" width="360" height="180" />`;
  CONTINENTS.forEach((d) => {
    html += `<path class="continent" d="${d}" />`;
  });

  AI_NATIONS.forEach((n) => {
    if (state.tradeDeals[n.id]) {
      html += `<line class="trade-line" x1="${p.map.x}" y1="${p.map.y}" x2="${n.map.x}" y2="${n.map.y}" />`;
    }
  });

  allNations().forEach((n) => {
    if (!n.map) return;
    const isPlayer = isPlayerNation(n.id);
    const isAi = isAiNation(n.id);
    let fill = "#5a6a7a";
    if (isPlayer) fill = "#ffd54f";
    else if (isAi) fill = relationColor(state.relations[n.id]);
    const selected = selectedMapNation === n.id ? " selected" : "";
    const playerClass = isPlayer ? " player" : "";
    html += `
      <g class="nation-marker${playerClass}${selected}" data-nation="${n.id}" transform="translate(${n.map.x},${n.map.y})">
        <circle r="6" fill="${fill}" stroke="#1a2332" stroke-width="1.5" />
        <text class="nation-label" y="14">${n.flag}</text>
      </g>`;
  });

  svg.innerHTML = html;

  svg.querySelectorAll(".nation-marker").forEach((g) => {
    g.addEventListener("click", () => selectMapNation(g.dataset.nation));
    g.addEventListener("mouseenter", () => showMapTooltip(g.dataset.nation));
    g.addEventListener("mouseleave", hideMapTooltip);
  });

  renderMapDetail();
}

function showMapTooltip(nationId) {
  const n = getNation(nationId);
  const el = document.getElementById("map-tooltip");
  if (isPlayerNation(nationId)) {
    el.textContent = `${n.flag} ${n.name}（自国）`;
  } else if (isAiNation(nationId)) {
    const rel = state.relations[nationId];
    const deal = state.tradeDeals[nationId] ? " · 貿易協定あり" : "";
    el.textContent = `${n.flag} ${n.name} · 関係 ${rel}${deal}`;
  } else {
    el.textContent = `${n.flag} ${n.name}（他プレイ可能国）`;
  }
  el.classList.remove("hidden");
}

function hideMapTooltip() {
  document.getElementById("map-tooltip").classList.add("hidden");
}

function selectMapNation(nationId) {
  selectedMapNation = selectedMapNation === nationId ? null : nationId;
  renderWorldMap();
}

function renderMapDetail() {
  const el = document.getElementById("map-detail");
  if (!selectedMapNation) {
    el.innerHTML = "地図上の国をクリックすると詳細が表示されます。";
    return;
  }
  const n = getNation(selectedMapNation);
  if (isPlayerNation(selectedMapNation)) {
    const p = state.player;
    el.innerHTML = `<strong>${n.flag} ${n.name}</strong>（自国）— GDP ${formatNum(p.gdp)}ドル、国庫 ${formatNum(p.treasury)}、安定 ${p.stability}%`;
    return;
  }
  if (isAiNation(selectedMapNation)) {
    const rel = state.relations[selectedMapNation];
    const deal = state.tradeDeals[selectedMapNation];
    el.innerHTML = `<strong>${n.flag} ${n.name}</strong> — 外交関係 ${rel}${deal ? "、<span style='color:var(--good)'>貿易協定締結中</span>" : ""}。右のパネルから外交・貿易が可能です。`;
    return;
  }
  el.innerHTML = `<strong>${n.flag} ${n.name}</strong> — プレイ可能な他国（新規ゲーム時に選択）`;
}

function render() {
  const p = state.player;
  document.getElementById("player-flag").textContent = p.flag;
  document.getElementById("player-name").textContent = p.name;
  document.getElementById("turn-label").textContent =
    `${state.year}年 Q${state.quarter} · ターン ${state.turn}/${MAX_TURNS}`;

  const stats = [
    { label: "GDP", value: formatNum(p.gdp) + "ドル", cls: "" },
    { label: "国庫", value: formatNum(p.treasury), cls: p.treasury < 0 ? "bad" : p.treasury < 100 ? "warn" : "good" },
    { label: "安定度", value: p.stability + "%", cls: p.stability < 30 ? "bad" : p.stability < 50 ? "warn" : "good" },
    { label: "産業力", value: p.industry + "%", cls: "" },
    { label: "福祉", value: p.welfare + "%", cls: "" },
    { label: "輸出収入", value: "+" + state.exports + "億/四半期", cls: state.exports > 0 ? "good" : "" },
  ];

  document.getElementById("stats-grid").innerHTML = stats
    .map(
      (s) => `
    <div class="stat-card">
      <div class="label">${s.label}</div>
      <div class="value ${s.cls}">${s.value}</div>
    </div>`
    )
    .join("");

  document.getElementById("tax-rate").value = state.taxRate;
  document.getElementById("tax-value").textContent = state.taxRate;

  renderWorldMap();
  renderTrade();
  renderDiplomacy();
  renderLog();
  updateButtons();
}

function renderTrade() {
  const el = document.getElementById("trade-list");
  el.innerHTML = AI_NATIONS.map((n) => {
    const deal = state.tradeDeals[n.id];
    const rel = state.relations[n.id];
    return `
    <div class="nation-row">
      <span class="name">${n.flag} ${n.name}</span>
      ${deal ? '<span class="badge">協定あり</span>' : `<span style="color:var(--muted);font-size:0.8rem">関係 ${rel}</span>`}
      <div class="row-actions">
        <button type="button" class="btn" data-trade="${n.id}" ${deal || rel < 30 ? "disabled" : ""}>
          貿易協定
        </button>
      </div>
    </div>`;
  }).join("");

  el.querySelectorAll("[data-trade]").forEach((btn) => {
    btn.addEventListener("click", () => proposeTrade(btn.dataset.trade));
  });
}

function renderDiplomacy() {
  const el = document.getElementById("diplomacy-list");
  el.innerHTML = AI_NATIONS.map((n) => {
    const rel = state.relations[n.id];
    const pct = Math.max(0, Math.min(100, (rel + 100) / 2));
    const color = relationColor(rel);
    return `
    <div class="nation-row">
      <span class="name">${n.flag} ${n.name}</span>
      <div class="relation-bar" title="関係: ${rel}">
        <div class="relation-fill" style="width:${pct}%;background:${color}"></div>
      </div>
      <div class="row-actions">
        <button type="button" class="btn" data-diplo="improve" data-nation="${n.id}">関係改善</button>
        <button type="button" class="btn" data-diplo="sanction" data-nation="${n.id}">制裁</button>
      </div>
    </div>`;
  }).join("");

  el.querySelectorAll("[data-diplo]").forEach((btn) => {
    btn.addEventListener("click", () => {
      if (btn.dataset.diplo === "improve") improveRelations(btn.dataset.nation);
      else imposeSanctions(btn.dataset.nation);
    });
  });
}

function renderLog() {
  document.getElementById("event-log").innerHTML = state.log
    .map((e) => `<li><span class="turn-tag">${e.year}Q${e.q}</span>${e.msg}</li>`)
    .join("");
}

function updateButtons() {
  const p = state.player;
  document.querySelector('[data-action="invest-industry"]').disabled = p.treasury < COST.industry;
  document.querySelector('[data-action="invest-welfare"]').disabled = p.treasury < COST.welfare;
  document.querySelector('[data-action="invest-infra"]').disabled = p.treasury < COST.infra;
}

function onTaxChange() {
  state.taxRate = Number(document.getElementById("tax-rate").value);
  document.getElementById("tax-value").textContent = state.taxRate;
}

function doPolicy(action) {
  const p = state.player;
  switch (action) {
    case "invest-industry":
      if (p.treasury < COST.industry) return;
      p.treasury -= COST.industry;
      p.industry = Math.min(100, p.industry + 8);
      log("産業に投資し、生産能力が向上しました。");
      break;
    case "invest-welfare":
      if (p.treasury < COST.welfare) return;
      p.treasury -= COST.welfare;
      p.welfare = Math.min(100, p.welfare + 10);
      p.stability = Math.min(100, p.stability + 5);
      log("福祉・医療に投資し、国民の支持が高まりました。");
      break;
    case "invest-infra":
      if (p.treasury < COST.infra) return;
      p.treasury -= COST.infra;
      p.industry = Math.min(100, p.industry + 4);
      p.stability = Math.min(100, p.stability + 3);
      log("インフラ整備により物流と経済効率が改善しました。");
      break;
  }
  render();
  autoSave();
}

function proposeTrade(nationId) {
  const n = AI_NATIONS.find((x) => x.id === nationId);
  if (state.relations[nationId] < 30 || state.tradeDeals[nationId]) return;
  state.tradeDeals[nationId] = true;
  state.relations[nationId] = Math.min(100, state.relations[nationId] + 10);
  log(`${n.name}と貿易協定を締結しました。輸出が増加します。`);
  render();
  autoSave();
}

function improveRelations(nationId) {
  if (state.player.treasury < COST.diplomacy) return;
  const n = AI_NATIONS.find((x) => x.id === nationId);
  state.player.treasury -= COST.diplomacy;
  state.relations[nationId] = Math.min(100, state.relations[nationId] + 15);
  log(`${n.name}との外交関係を改善しました。`);
  render();
  autoSave();
}

function imposeSanctions(nationId) {
  const n = AI_NATIONS.find((x) => x.id === nationId);
  state.relations[nationId] = Math.max(-100, state.relations[nationId] - 25);
  if (state.tradeDeals[nationId]) {
    state.tradeDeals[nationId] = false;
    log(`${n.name}への制裁により貿易協定が破棄されました。`);
  } else {
    log(`${n.name}に経済制裁を課しました。関係が悪化しました。`);
  }
  render();
  autoSave();
}

function calcQuarterEconomy() {
  const p = state.player;
  const taxFactor = state.taxRate / 100;
  const stabilityMod = 0.5 + p.stability / 200;
  const industryMod = 0.7 + p.industry / 300;
  const welfareMod = 0.9 + p.welfare / 500;

  const gdpGrowth = p.gdp * 0.02 * industryMod * stabilityMod;
  const taxIncome = p.gdp * taxFactor * 0.08 * stabilityMod;
  const welfareCost = p.welfare * 0.3;
  const maintenance = p.gdp * 0.01;

  let exportIncome = 0;
  AI_NATIONS.forEach((n) => {
    if (state.tradeDeals[n.id]) {
      exportIncome += 15 + Math.floor(p.industry / 10);
    }
  });
  state.exports = exportIncome;

  const highTaxPenalty = state.taxRate > 35 ? (state.taxRate - 35) * 0.5 : 0;

  return {
    gdpGrowth: gdpGrowth * welfareMod,
    taxIncome,
    welfareCost,
    maintenance,
    exportIncome,
    stabilityDelta: -highTaxPenalty + (p.welfare > 60 ? 1 : -1) + (state.taxRate < 10 ? -2 : 0),
  };
}

function randomEvent() {
  const events = [
    { msg: "世界景気が好転し、輸出が伸びました。", gdp: 1.03, stability: 2 },
    { msg: "原油価格高騰で物価が上昇しました。", gdp: 0.98, treasury: -30 },
    { msg: "技術革新により生産性が向上しました。", industry: 5 },
    { msg: "国内で抗議デモが発生しました。", stability: -8 },
    { msg: "国際会議で外交的成果を上げました。", relations: 10 },
    { msg: "パンデミック警戒で経済が停滞しました。", gdp: 0.95, stability: -5 },
  ];
  if (Math.random() > 0.35) return;
  const ev = events[randInt(0, events.length - 1)];
  const p = state.player;
  log(ev.msg);
  if (ev.gdp) p.gdp *= ev.gdp;
  if (ev.treasury) p.treasury += ev.treasury;
  if (ev.industry) p.industry = Math.min(100, p.industry + ev.industry);
  if (ev.stability) p.stability = Math.max(0, Math.min(100, p.stability + ev.stability));
  if (ev.relations) {
    AI_NATIONS.forEach((n) => {
      state.relations[n.id] = Math.min(100, state.relations[n.id] + ev.relations);
    });
  }
}

function nextTurn() {
  const p = state.player;
  const econ = calcQuarterEconomy();

  p.gdp += econ.gdpGrowth;
  p.treasury += econ.taxIncome - econ.welfareCost - econ.maintenance + econ.exportIncome;
  p.stability = Math.max(0, Math.min(100, p.stability + econ.stabilityDelta));

  randomEvent();

  state.quarter++;
  if (state.quarter > 4) {
    state.quarter = 1;
    state.year++;
  }
  state.turn++;

  log(
    `四半期決算: 税収+${Math.round(econ.taxIncome)}億、支出-${Math.round(econ.welfareCost + econ.maintenance)}億、輸出+${econ.exportIncome}億`
  );

  if (checkEnd()) return;
  render();
  autoSave();
}

function checkEnd() {
  const p = state.player;

  if (p.treasury < -200) {
    endGame(false, "財政破綻", "国庫が底をつき、政権が倒れました。");
    return true;
  }
  if (p.stability <= 0) {
    endGame(false, "政変", "安定度がゼロになり、内戦状態に陥りました。");
    return true;
  }
  if (state.turn > MAX_TURNS) {
    const score = Math.round(p.gdp + p.treasury * 2 + p.stability * 10);
    endGame(true, "任期満了", `5年間の統治を終えました。総合スコア: ${score}点`);
    return true;
  }
  return false;
}

function endGame(won, title, message) {
  document.getElementById("end-title").textContent = title;
  document.getElementById("end-message").textContent = message;
  document.getElementById("end-title").style.color = won ? "var(--good)" : "var(--bad)";
  showScreen("screen-end");
  deleteSave(AUTOSAVE_SLOT);
}

function restart(clearAutosave) {
  if (clearAutosave) deleteSave(AUTOSAVE_SLOT);
  state = null;
  selectedMapNation = null;
  showScreen("screen-start");
  renderCountrySelect();
  renderStartSaves();
}

/* ——— Save / Load ——— */

function saveKey(slot) {
  return SAVE_PREFIX + slot;
}

function serializeState() {
  return JSON.stringify({
    version: SAVE_VERSION,
    state: {
      player: { ...state.player },
      turn: state.turn,
      year: state.year,
      quarter: state.quarter,
      taxRate: state.taxRate,
      tradeDeals: { ...state.tradeDeals },
      relations: { ...state.relations },
      exports: state.exports,
      log: [...state.log],
    },
    savedAt: Date.now(),
  });
}

function getSaveMeta(slot) {
  try {
    const raw = localStorage.getItem(saveKey(slot));
    if (!raw) return null;
    const data = JSON.parse(raw);
    if (data.version !== SAVE_VERSION || !data.state) return null;
    const s = data.state;
    return {
      slot,
      nation: s.player.name,
      flag: s.player.flag,
      year: s.year,
      quarter: s.quarter,
      turn: s.turn,
      savedAt: data.savedAt,
    };
  } catch {
    return null;
  }
}

function saveToSlot(slot) {
  if (!state) return false;
  try {
    localStorage.setItem(saveKey(slot), serializeState());
    return true;
  } catch (e) {
    alert("セーブに失敗しました。ブラウザのストレージ容量を確認してください。");
    return false;
  }
}

function hydratePlayer(stateData) {
  const base = COUNTRIES.find((c) => c.id === stateData.player.id);
  if (base) {
    stateData.player.map = base.map;
    stateData.player.flag = stateData.player.flag || base.flag;
    stateData.player.name = stateData.player.name || base.name;
  }
  return stateData;
}

function loadFromSlot(slot) {
  try {
    const raw = localStorage.getItem(saveKey(slot));
    if (!raw) return false;
    const data = JSON.parse(raw);
    if (data.version !== SAVE_VERSION || !data.state) return false;
    state = hydratePlayer(data.state);
    selectedMapNation = null;
    showScreen("screen-game");
    render();
    log("セーブデータを読み込みました。");
    return true;
  } catch {
    alert("セーブデータの読み込みに失敗しました。");
    return false;
  }
}

function deleteSave(slot) {
  localStorage.removeItem(saveKey(slot));
}

function autoSave() {
  if (state) saveToSlot(AUTOSAVE_SLOT);
}

function formatSaveTime(ts) {
  const d = new Date(ts);
  return `${d.getFullYear()}/${d.getMonth() + 1}/${d.getDate()} ${d.getHours()}:${String(d.getMinutes()).padStart(2, "0")}`;
}

function slotLabel(slot) {
  if (slot === AUTOSAVE_SLOT) return "自動セーブ";
  const i = MANUAL_SLOTS.indexOf(slot);
  return `スロット ${i + 1}`;
}

function renderSaveSlotRow(slot, inDialog) {
  const meta = getSaveMeta(slot);
  const label = slotLabel(slot);
  if (!meta) {
    return `
    <div class="save-slot" data-slot="${slot}">
      <div class="meta"><strong>${label}</strong><span>空き</span></div>
      ${inDialog && state ? `<div class="slot-actions"><button type="button" class="btn btn-save-here" data-slot="${slot}">セーブ</button></div>` : ""}
    </div>`;
  }
  const time = meta.savedAt ? formatSaveTime(meta.savedAt) : "";
  return `
  <div class="save-slot" data-slot="${slot}">
    <div class="meta">
      <strong>${label} — ${meta.flag} ${meta.nation}</strong>
      <span>${meta.year}年 Q${meta.quarter} · ターン ${meta.turn}/${MAX_TURNS} · ${time}</span>
    </div>
    <div class="slot-actions">
      <button type="button" class="btn btn-load" data-slot="${slot}">ロード</button>
      ${inDialog && state ? `<button type="button" class="btn btn-save-here" data-slot="${slot}">上書き</button>` : ""}
      <button type="button" class="btn btn-delete" data-slot="${slot}">削除</button>
    </div>
  </div>`;
}

function bindSaveSlotButtons(container, inDialog) {
  container.querySelectorAll(".btn-load").forEach((btn) => {
    btn.addEventListener("click", () => {
      if (loadFromSlot(btn.dataset.slot)) {
        if (inDialog) document.getElementById("save-dialog").close();
        renderStartSaves();
      }
    });
  });
  container.querySelectorAll(".btn-save-here").forEach((btn) => {
    btn.addEventListener("click", () => {
      if (saveToSlot(btn.dataset.slot)) {
        log(`${slotLabel(btn.dataset.slot)}に保存しました。`);
        render();
        renderSaveDialog();
        renderStartSaves();
      }
    });
  });
  container.querySelectorAll(".btn-delete").forEach((btn) => {
    btn.addEventListener("click", () => {
      if (confirm(`${slotLabel(btn.dataset.slot)}を削除しますか？`)) {
        deleteSave(btn.dataset.slot);
        renderSaveDialog();
        renderStartSaves();
      }
    });
  });
}

function renderStartSaves() {
  const el = document.getElementById("save-slots-start");
  const slots = [AUTOSAVE_SLOT, ...MANUAL_SLOTS];
  const hasAny = slots.some((s) => getSaveMeta(s));
  if (!hasAny) {
    el.innerHTML = "";
    el.classList.add("hidden");
    return;
  }
  el.classList.remove("hidden");
  el.innerHTML = `<h3>続きから</h3><div class="save-slots">${slots.map((s) => renderSaveSlotRow(s, false)).join("")}</div>`;
  bindSaveSlotButtons(el, false);
}

function renderSaveDialog() {
  const el = document.getElementById("save-slots-dialog");
  const slots = MANUAL_SLOTS;
  el.innerHTML = `
    <p class="panel-desc" style="margin-bottom:0.75rem">手動セーブは3スロット。ターン終了時に自動セーブされます。</p>
    ${renderSaveSlotRow(AUTOSAVE_SLOT, true)}
    ${slots.map((s) => renderSaveSlotRow(s, true)).join("")}
  `;
  bindSaveSlotButtons(el, true);
}

function openSaveDialog() {
  renderSaveDialog();
  document.getElementById("save-dialog").showModal();
}

document.addEventListener("DOMContentLoaded", init);
