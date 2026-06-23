import { catalogs } from "./catalog-config.js";
import { parseCsv } from "./csv.js";

const fileNameMap = new Map(catalogs.map((catalog) => [catalog.path.split("/").pop(), catalog.id]));

export async function loadCatalogs() {
  const entries = await Promise.all(catalogs.map(loadCatalog));
  return Object.fromEntries(entries.map((entry) => [entry.config.id, entry]));
}

export async function loadCatalog(config) {
  const response = await fetch(config.path, { cache: "no-store" });
  if (!response.ok) {
    throw new Error(`${config.label} failed to load (${response.status})`);
  }
  const text = await response.text();
  return {
    config,
    ...parseCsv(text),
  };
}

export async function loadCatalogsFromFiles(fileList) {
  const files = Array.from(fileList);
  const loaded = {};

  await Promise.all(files.map(async (file) => {
    const catalogId = fileNameMap.get(file.name);
    if (!catalogId) {
      return;
    }
    const config = catalogs.find((candidate) => candidate.id === catalogId);
    loaded[catalogId] = {
      config,
      ...parseCsv(await file.text()),
    };
  }));

  return loaded;
}
