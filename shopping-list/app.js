const STORAGE_KEY = "shopping-list-v1";

const CATEGORIES = {
  produce: "野菜・果物",
  meat: "肉・魚",
  dairy: "乳製品",
  pantry: "調味料・乾物",
  daily: "日用品",
  other: "その他",
};

const addForm = document.getElementById("addForm");
const itemName = document.getElementById("itemName");
const itemQty = document.getElementById("itemQty");
const itemCategory = document.getElementById("itemCategory");
const itemList = document.getElementById("itemList");
const itemCount = document.getElementById("itemCount");
const emptyMsg = document.getElementById("emptyMsg");
const clearDone = document.getElementById("clearDone");
const filterActive = document.getElementById("filterActive");
const filterAll = document.getElementById("filterAll");

let items = loadItems();
let filter = "active";

addForm.addEventListener("submit", onAddItem);
clearDone.addEventListener("click", onClearDone);
filterActive.addEventListener("click", () => setFilter("active"));
filterAll.addEventListener("click", () => setFilter("all"));

render();

function onAddItem(e) {
  e.preventDefault();
  const name = itemName.value.trim();
  if (!name) return;

  items.unshift({
    id: crypto.randomUUID(),
    name,
    qty: itemQty.value.trim(),
    category: itemCategory.value,
    done: false,
    createdAt: Date.now(),
  });

  saveItems();
  itemName.value = "";
  itemQty.value = "";
  itemName.focus();
  render();
}

function onToggle(id) {
  const item = items.find((i) => i.id === id);
  if (!item) return;
  item.done = !item.done;
  saveItems();
  render();
}

function onDelete(id) {
  items = items.filter((i) => i.id !== id);
  saveItems();
  render();
}

function onClearDone() {
  items = items.filter((i) => !i.done);
  saveItems();
  render();
}

function setFilter(next) {
  filter = next;
  filterActive.classList.toggle("active", filter === "active");
  filterAll.classList.toggle("active", filter === "all");
  render();
}

function render() {
  const activeCount = items.filter((i) => !i.done).length;
  const doneCount = items.filter((i) => i.done).length;

  itemCount.textContent =
    activeCount === 0 && items.length > 0
      ? "すべて購入済み"
      : `残り ${activeCount}件`;

  clearDone.hidden = doneCount === 0;

  const visible =
    filter === "active" ? items.filter((i) => !i.done) : [...items];

  visible.sort((a, b) => {
    if (a.done !== b.done) return a.done ? 1 : -1;
    return b.createdAt - a.createdAt;
  });

  itemList.innerHTML = "";
  emptyMsg.hidden = visible.length > 0;

  visible.forEach((item) => {
    const li = document.createElement("li");
    li.className = "item" + (item.done ? " done" : "");

    const check = document.createElement("button");
    check.type = "button";
    check.className = "check-btn" + (item.done ? " checked" : "");
    check.setAttribute("aria-label", item.done ? "未購入に戻す" : "購入済みにする");
    check.addEventListener("click", () => onToggle(item.id));

    const body = document.createElement("div");
    body.className = "item-body";

    const name = document.createElement("div");
    name.className = "item-name";
    name.textContent = item.name;

    const meta = document.createElement("div");
    meta.className = "item-meta";

    if (item.qty) {
      const qty = document.createElement("span");
      qty.className = "item-qty";
      qty.textContent = item.qty;
      meta.appendChild(qty);
    }

    const tag = document.createElement("span");
    tag.className = `category-tag ${item.category}`;
    tag.textContent = CATEGORIES[item.category] || CATEGORIES.other;
    meta.appendChild(tag);

    body.append(name, meta);

    const del = document.createElement("button");
    del.type = "button";
    del.className = "delete-btn";
    del.textContent = "削除";
    del.addEventListener("click", () => onDelete(item.id));

    li.append(check, body, del);
    itemList.appendChild(li);
  });
}

function loadItems() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveItems() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
}
