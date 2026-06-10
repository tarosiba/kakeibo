const STORAGE_KEY = "schedule-calendar-events-v2";

const COLORS = [
  { id: "blue", hex: "#1a5fb4", label: "青" },
  { id: "green", hex: "#16a34a", label: "緑" },
  { id: "orange", hex: "#ea580c", label: "橙" },
  { id: "purple", hex: "#7c3aed", label: "紫" },
  { id: "pink", hex: "#db2777", label: "桃" },
  { id: "gray", hex: "#6b7280", label: "灰" },
];

const monthTitle = document.getElementById("monthTitle");
const calendarGrid = document.getElementById("calendarGrid");
const dayPanel = document.getElementById("dayPanel");
const selectedDateLabel = document.getElementById("selectedDateLabel");
const eventList = document.getElementById("eventList");
const eventForm = document.getElementById("eventForm");
const eventTitle = document.getElementById("eventTitle");
const eventTime = document.getElementById("eventTime");
const colorPicker = document.getElementById("colorPicker");
const hintMsg = document.getElementById("hintMsg");

let viewDate = new Date();
let selectedDateKey = null;
let selectedColor = COLORS[0].hex;
let eventsByDate = loadEvents();

initColorPicker();
document.getElementById("prevMonth").addEventListener("click", () => shiftMonth(-1));
document.getElementById("nextMonth").addEventListener("click", () => shiftMonth(1));
document.getElementById("todayBtn").addEventListener("click", goToday);
document.getElementById("closePanel").addEventListener("click", closePanel);
eventForm.addEventListener("submit", onAddEvent);

renderCalendar();
registerServiceWorker();

function initColorPicker() {
  COLORS.forEach((c, index) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "color-btn" + (index === 0 ? " selected" : "");
    btn.style.backgroundColor = c.hex;
    btn.title = c.label;
    btn.setAttribute("aria-label", c.label);
    btn.addEventListener("click", () => {
      selectedColor = c.hex;
      colorPicker.querySelectorAll(".color-btn").forEach((b) => b.classList.remove("selected"));
      btn.classList.add("selected");
    });
    colorPicker.appendChild(btn);
  });
}

function goToday() {
  viewDate = new Date();
  openDay(dateKey(new Date()));
}

function shiftMonth(delta) {
  viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1);
  renderCalendar();
}

function renderCalendar() {
  const year = viewDate.getFullYear();
  const month = viewDate.getMonth();
  monthTitle.textContent = `${year}年${month + 1}月`;

  const firstDay = new Date(year, month, 1);
  const startWeekday = firstDay.getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const daysInPrevMonth = new Date(year, month, 0).getDate();

  calendarGrid.innerHTML = "";
  const todayKey = dateKey(new Date());
  const totalCells = Math.ceil((startWeekday + daysInMonth) / 7) * 7;

  for (let i = 0; i < totalCells; i++) {
    let dayNum;
    let cellMonth = month;
    let cellYear = year;
    let other = false;

    if (i < startWeekday) {
      dayNum = daysInPrevMonth - startWeekday + i + 1;
      cellMonth = month - 1;
      if (cellMonth < 0) {
        cellMonth = 11;
        cellYear = year - 1;
      }
      other = true;
    } else if (i >= startWeekday + daysInMonth) {
      dayNum = i - startWeekday - daysInMonth + 1;
      cellMonth = month + 1;
      if (cellMonth > 11) {
        cellMonth = 0;
        cellYear = year + 1;
      }
      other = true;
    } else {
      dayNum = i - startWeekday + 1;
    }

    const key = dateKeyFromParts(cellYear, cellMonth, dayNum);
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "day-cell";
    btn.setAttribute("role", "gridcell");
    if (other) btn.classList.add("other-month");
    if (key === todayKey) btn.classList.add("today");
    if (key === selectedDateKey) btn.classList.add("selected");

    const num = document.createElement("span");
    num.className = "day-num";
    num.textContent = String(dayNum);
    btn.appendChild(num);

    const dots = document.createElement("div");
    dots.className = "dots";
    const dayEvents = sortedEvents(eventsByDate[key] || []);
    dayEvents.slice(0, 4).forEach((ev) => {
      const dot = document.createElement("span");
      dot.className = "dot";
      dot.style.backgroundColor = ev.color;
      dots.appendChild(dot);
    });
    if (dayEvents.length > 4) {
      const more = document.createElement("span");
      more.className = "dot";
      more.style.backgroundColor = "#9ca3af";
      dots.appendChild(more);
    }
    btn.appendChild(dots);

    btn.addEventListener("click", () => openDay(key));
    calendarGrid.appendChild(btn);
  }

  hintMsg.hidden = selectedDateKey !== null;
}

function openDay(key) {
  selectedDateKey = key;
  dayPanel.hidden = false;
  selectedDateLabel.textContent = formatLabel(key);
  renderEventList();
  renderCalendar();
  eventTitle.focus();
}

function closePanel() {
  selectedDateKey = null;
  dayPanel.hidden = true;
  renderCalendar();
}

function renderEventList() {
  const list = sortedEvents(eventsByDate[selectedDateKey] || []);
  eventList.innerHTML = "";

  if (list.length === 0) {
    const p = document.createElement("p");
    p.className = "empty-msg";
    p.textContent = "予定はまだありません";
    eventList.appendChild(p);
    return;
  }

  const source = eventsByDate[selectedDateKey] || [];
  list.forEach((ev) => {
    const index = source.indexOf(ev);
    const li = document.createElement("li");
    li.className = "event-item";

    const swatch = document.createElement("span");
    swatch.className = "event-swatch";
    swatch.style.backgroundColor = ev.color;

    const body = document.createElement("div");
    body.className = "event-body";

    const title = document.createElement("span");
    title.className = "event-title";
    title.textContent = ev.title;
    body.appendChild(title);

    if (ev.time) {
      const time = document.createElement("span");
      time.className = "event-time";
      time.textContent = formatTime(ev.time);
      body.appendChild(time);
    }

    const del = document.createElement("button");
    del.type = "button";
    del.className = "delete-btn";
    del.textContent = "削除";
    del.addEventListener("click", () => {
      source.splice(index, 1);
      if (source.length === 0) {
        delete eventsByDate[selectedDateKey];
      } else {
        eventsByDate[selectedDateKey] = source;
      }
      saveEvents();
      renderEventList();
      renderCalendar();
    });

    li.append(swatch, body, del);
    eventList.appendChild(li);
  });
}

function onAddEvent(e) {
  e.preventDefault();
  const title = eventTitle.value.trim();
  if (!title || !selectedDateKey) return;

  if (!eventsByDate[selectedDateKey]) {
    eventsByDate[selectedDateKey] = [];
  }
  eventsByDate[selectedDateKey].push({
    title,
    time: eventTime.value,
    color: selectedColor,
  });
  saveEvents();
  eventTitle.value = "";
  eventTime.value = "";
  renderEventList();
  renderCalendar();
}

function sortedEvents(list) {
  return [...list].sort((a, b) => {
    if (a.time && b.time) return a.time.localeCompare(b.time);
    if (a.time) return -1;
    if (b.time) return 1;
    return 0;
  });
}

function loadEvents() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return JSON.parse(raw);
    const legacy = localStorage.getItem("schedule-calendar-events-v1");
    if (legacy) {
      const data = JSON.parse(legacy);
      localStorage.setItem(STORAGE_KEY, legacy);
      return data;
    }
    return {};
  } catch {
    return {};
  }
}

function saveEvents() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(eventsByDate));
}

function dateKey(d) {
  return dateKeyFromParts(d.getFullYear(), d.getMonth(), d.getDate());
}

function dateKeyFromParts(y, m, d) {
  const mm = String(m + 1).padStart(2, "0");
  const dd = String(d).padStart(2, "0");
  return `${y}-${mm}-${dd}`;
}

function formatLabel(key) {
  const [y, m, d] = key.split("-");
  const weekdays = ["日", "月", "火", "水", "木", "金", "土"];
  const dt = new Date(Number(y), Number(m) - 1, Number(d));
  return `${Number(y)}年${Number(m)}月${Number(d)}日（${weekdays[dt.getDay()]}）`;
}

function formatTime(value) {
  const [h, m] = value.split(":");
  return `${Number(h)}:${m}`;
}

function registerServiceWorker() {
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("./sw.js").catch(() => {});
  }
}
