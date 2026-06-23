import { catalogs } from "./catalog-config.js";

export function createInitialState() {
  return {
    activeCatalogId: catalogs[0].id,
    datasets: {},
    query: "",
    filterValue: "all",
    selectedRowKey: "",
  };
}

export function getActiveDataset(state) {
  return state.datasets[state.activeCatalogId] || null;
}

export function getFilteredRows(state) {
  const dataset = getActiveDataset(state);
  if (!dataset) {
    return [];
  }

  const query = state.query.trim().toLowerCase();
  const filterField = dataset.config.filterField;

  return dataset.rows.filter((row) => {
    const matchesFilter = state.filterValue === "all" || String(row[filterField]) === state.filterValue;
    if (!matchesFilter) {
      return false;
    }
    if (!query) {
      return true;
    }
    return dataset.fields.some((field) => String(row[field] || "").toLowerCase().includes(query));
  });
}

export function getRowKey(row) {
  return String(row.__rowNumber);
}
