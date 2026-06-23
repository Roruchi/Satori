import { catalogs } from "./catalog-config.js";
import { getActiveDataset, getFilteredRows, getRowKey } from "./state.js";

export function renderApp(state, handlers) {
  renderTabs(state, handlers);
  renderFilters(state, handlers);
  renderSummary(state);
  renderTable(state, handlers);
  renderDetail(state);
}

function renderTabs(state, handlers) {
  const tabs = document.querySelector("#dataset-tabs");
  tabs.replaceChildren(...catalogs.map((catalog) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "tab-button";
    button.textContent = `${catalog.label} ${countFor(state, catalog.id)}`;
    button.setAttribute("aria-selected", String(catalog.id === state.activeCatalogId));
    button.addEventListener("click", () => handlers.selectCatalog(catalog.id));
    return button;
  }));
}

function countFor(state, catalogId) {
  const dataset = state.datasets[catalogId];
  return dataset ? `(${dataset.rows.length})` : "";
}

function renderFilters(state, handlers) {
  const slot = document.querySelector("#filter-slot");
  const dataset = getActiveDataset(state);
  if (!dataset) {
    slot.replaceChildren();
    return;
  }
  if (!dataset.config.filterField) {
    slot.replaceChildren();
    return;
  }

  const values = uniqueValues(dataset.rows.map((row) => row[dataset.config.filterField]));
  const wrapper = document.createElement("div");
  wrapper.className = "segmented";
  wrapper.append(buttonFor("All", "all", state.filterValue, handlers));
  values.forEach((value) => wrapper.append(buttonFor(value, value, state.filterValue, handlers)));
  slot.replaceChildren(wrapper);
}

function buttonFor(label, value, activeValue, handlers) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "segment-button";
  button.textContent = label;
  button.setAttribute("aria-pressed", String(value === activeValue));
  button.addEventListener("click", () => handlers.setFilter(value));
  return button;
}

function uniqueValues(values) {
  return Array.from(new Set(values.filter(Boolean))).sort((a, b) => naturalCompare(a, b));
}

function renderSummary(state) {
  const summary = document.querySelector("#summary");
  const dataset = getActiveDataset(state);
  const rows = getFilteredRows(state);
  if (!dataset) {
    summary.replaceChildren();
    return;
  }

  const emptyCells = rows.reduce((total, row) => {
    return total + dataset.fields.filter((field) => !row[field]).length;
  }, 0);
  const assetCount = dataset.fields.includes("Assets Folder")
    ? rows.filter((row) => row["Assets Folder"]).length
    : 0;

  summary.replaceChildren(
    metric(rows.length, "Visible Rows"),
    metric(dataset.fields.length, "Columns"),
    metric(emptyCells, "Empty Cells"),
    metric(assetCount, "Asset Links"),
  );
}

function metric(value, label) {
  const node = document.createElement("article");
  node.className = "metric";
  node.innerHTML = `<strong>${value}</strong><span>${label}</span>`;
  return node;
}

function renderTable(state, handlers) {
  const dataset = getActiveDataset(state);
  const head = document.querySelector("#table-head");
  const body = document.querySelector("#table-body");
  if (!dataset) {
    head.replaceChildren();
    body.replaceChildren();
    return;
  }

  const fields = dataset.config.visibleFields.filter((field) => dataset.fields.includes(field));
  const headerRow = document.createElement("tr");
  fields.forEach((field) => {
    const th = document.createElement("th");
    th.textContent = field;
    headerRow.append(th);
  });
  head.replaceChildren(headerRow);

  const rows = getFilteredRows(state);
  body.replaceChildren(...rows.map((row) => rowNode(row, fields, dataset.config, state, handlers)));
}

function rowNode(row, fields, config, state, handlers) {
  const tr = document.createElement("tr");
  const key = getRowKey(row);
  tr.classList.toggle("is-selected", key === state.selectedRowKey);
  tr.addEventListener("click", () => handlers.selectRow(key));

  fields.forEach((field) => {
    const td = document.createElement("td");
    const value = row[field] || "";
    if (field === config.primaryField) {
      td.className = "name-cell";
    }
    if (field === config.badgeField && value) {
      const pill = document.createElement("span");
      pill.className = `pill ${value.toLowerCase()}`;
      pill.textContent = value;
      td.append(pill);
    } else if (value) {
      td.textContent = value;
    } else {
      td.className = `${td.className} empty`.trim();
      td.textContent = "blank";
    }
    tr.append(td);
  });

  return tr;
}

function renderDetail(state) {
  const panel = document.querySelector("#detail-panel");
  const dataset = getActiveDataset(state);
  if (!dataset) {
    panel.replaceChildren();
    return;
  }

  const rows = getFilteredRows(state);
  const selected = rows.find((row) => getRowKey(row) === state.selectedRowKey) || rows[0];
  if (!selected) {
    panel.replaceChildren(emptyDetail("No rows"));
    return;
  }

  const title = selected[dataset.config.primaryField] || `Row ${selected.__rowNumber}`;
  const subtitle = `${dataset.config.label} row ${selected.__rowNumber}`;
  const fields = dataset.fields.map((field) => fieldRow(field, selected[field]));

  const inner = document.createElement("div");
  inner.className = "detail-inner";
  const header = document.createElement("div");
  header.className = "detail-title";
  header.innerHTML = `<h2>${escapeHtml(title)}</h2><p>${escapeHtml(subtitle)}</p>`;
  const list = document.createElement("div");
  list.className = "detail-fields";
  list.replaceChildren(...fields);
  inner.replaceChildren(header, list);
  panel.replaceChildren(inner);
}

function fieldRow(field, value) {
  const row = document.createElement("div");
  row.className = "field-row";
  const label = document.createElement("span");
  label.textContent = field;
  const content = document.createElement("strong");
  content.textContent = value || "blank";
  if (!value) {
    content.className = "empty";
  }
  row.replaceChildren(label, content);
  return row;
}

function emptyDetail(message) {
  const node = document.createElement("div");
  node.className = "detail-inner";
  node.innerHTML = `<div class="detail-title"><h2>${escapeHtml(message)}</h2></div>`;
  return node;
}

function naturalCompare(a, b) {
  return String(a).localeCompare(String(b), undefined, { numeric: true, sensitivity: "base" });
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}
