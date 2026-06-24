import { loadCatalogs, loadCatalogsFromFiles } from "./data-source.js";
import { renderApp } from "./render.js";
import { createInitialState, getActiveDataset, getFilteredRows } from "./state.js";

const state = createInitialState();
const status = document.querySelector("#status");
const searchInput = document.querySelector("#search-input");
const refreshButton = document.querySelector("#refresh-button");
const fileInput = document.querySelector("#file-input");

const handlers = {
  selectCatalog(catalogId) {
    state.activeCatalogId = catalogId;
    state.filterValue = "all";
    selectFirstVisibleRow();
    render();
  },
  setFilter(value) {
    state.filterValue = value;
    selectFirstVisibleRow();
    render();
  },
  selectRow(rowKey) {
    state.selectedRowKey = rowKey;
    render();
  },
};

searchInput.addEventListener("input", () => {
  state.query = searchInput.value;
  selectFirstVisibleRow();
  render();
});

refreshButton.addEventListener("click", () => {
  void boot();
});

fileInput.addEventListener("change", async () => {
  const loaded = await loadCatalogsFromFiles(fileInput.files);
  const loadedCount = Object.keys(loaded).length;
  if (loadedCount === 0) {
    setStatus("No matching catalog files selected.", true);
    return;
  }
  state.datasets = { ...state.datasets, ...loaded };
  selectFirstVisibleRow();
  setStatus(`Loaded ${loadedCount} catalog file(s).`);
  render();
});

async function boot() {
  try {
    setStatus("Loading catalog files...");
    state.datasets = await loadCatalogs();
    selectFirstVisibleRow();
    setStatus("Catalog files loaded.");
    render();
  } catch (error) {
    setStatus(error.message, true);
    render();
  }
}

function render() {
  renderApp(state, handlers);
}

function selectFirstVisibleRow() {
  const dataset = getActiveDataset(state);
  const first = getFilteredRows(state)[0];
  state.selectedRowKey = dataset && first ? String(first.__rowNumber) : "";
}

function setStatus(message, isError = false) {
  status.textContent = message;
  status.classList.toggle("error", isError);
}

void boot();
