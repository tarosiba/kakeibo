/**
 * 現代国家シミュレーター — シンプルな国家運営ゲーム
 */

const COUNTRIES = [
  { id: "japan", name: "日本", flag: "🇯🇵", gdp: 4200, treasury: 800, stability: 72, industry: 85, welfare: 78 },
  { id: "usa", name: "アメリカ", flag: "🇺🇸", gdp: 28000, treasury: 1200, stability: 65, industry: 90, welfare: 60 },
  { id: "brazil", name: "ブラジル", flag: "🇧🇷", gdp: 2200, treasury: 350, stability: 55, industry: 55, welfare: 48 },
  { id: "nigeria", name: "ナイジェリア", flag: "🇳🇬", gdp: 480, treasury: 120, stability: 48, industry: 35, welfare: 35 },
];

const AI_NATIONS = [
  { id: "china", name: "中国", flag: "🇨🇳" },
  { id: "eu", name: "EU", flag: "🇪🇺" },
  { id: "india", name: "インド", flag: "🇮🇳" },
];

const MAX_TURNS = 20;
const COST = { industry: 50, welfare: 40, infra: 35, diplomacy: 25 };

let state = null;

function init() {
  renderCountrySelect();
  document.getElementById("btn-next-turn").addEventListener("click", nextTurn);
  document.getElementById("btn-restart").addEventListener("click", restart);
  document.getElementById("btn-play-again").addEventListener("click", restart);
  document.getElementById("tax-rate").addEventListener("input", onTaxChange);

  document.querySelectorAll("[data-action]").forEach((btn) => {
    btn.addEventListener("click", () => doPolicy(btn.dataset.action));
  });
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
  state = {
    player: { ...base },
    turn: 1,
    year: 2026,
    quarter: 1,
    taxRate: 20,
    tradeDeals: {},
    relations: Object.fromEntries(AI_NATIONS.map((n) => [n.id, randInt(20, 50)])),
    exports: 0,
    log: [],
  };

  AI_NATIONS.forEach((n) => {
    state.tradeDeals[n.id] = false;
  });

  log(`元首として${base.name}の統治を開始しました。`);
  showScreen("screen-game");
  render();
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
    const color = rel >= 50 ? "var(--good)" : rel >= 0 ? "var(--warn)" : "var(--bad)";
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
    .map(
      (e) =>
        `<li><span class="turn-tag">${e.year}Q${e.q}</span>${e.msg}</li>`
    )
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
}

function proposeTrade(nationId) {
  const n = AI_NATIONS.find((x) => x.id === nationId);
  if (state.relations[nationId] < 30 || state.tradeDeals[nationId]) return;
  state.tradeDeals[nationId] = true;
  state.relations[nationId] = Math.min(100, state.relations[nationId] + 10);
  log(`${n.name}と貿易協定を締結しました。輸出が増加します。`);
  render();
}

function improveRelations(nationId) {
  if (state.player.treasury < COST.diplomacy) return;
  const n = AI_NATIONS.find((x) => x.id === nationId);
  state.player.treasury -= COST.diplomacy;
  state.relations[nationId] = Math.min(100, state.relations[nationId] + 15);
  log(`${n.name}との外交関係を改善しました。`);
  render();
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
}

function restart() {
  state = null;
  showScreen("screen-start");
  renderCountrySelect();
}

document.addEventListener("DOMContentLoaded", init);
