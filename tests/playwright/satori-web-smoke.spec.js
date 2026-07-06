const { test, expect } = require("@playwright/test");

function expectBufferToContain(buffer, needle) {
  const needleBuffer = Buffer.from(needle, "utf8");
  expect(
    buffer.indexOf(needleBuffer),
    `index.pck should contain ${needle}`
  ).toBeGreaterThanOrEqual(0);
}

function expectBufferNotToContain(buffer, needle) {
  const needleBuffer = Buffer.from(needle, "utf8");
  expect(
    buffer.indexOf(needleBuffer),
    `index.pck should not contain ${needle}`
  ).toBe(-1);
}

test("web export serves the Godot shell and core assets", async ({ browser, request }) => {
  const context = await browser.newContext({
    javaScriptEnabled: false,
    viewport: { width: 393, height: 851 },
    isMobile: true,
    hasTouch: true
  });
  const page = await context.newPage();
  await page.goto("/", { waitUntil: "domcontentloaded" });
  await expect(page.locator("canvas")).toHaveCount(1);
  await expect(page.locator("progress")).toHaveCount(1);
  await context.close();

  for (const assetPath of ["/index.js", "/index.wasm", "/index.pck"]) {
    const response = await request.get(assetPath);
    expect(response.ok()).toBe(true);
    const body = await response.body();
    expect(body.length).toBeGreaterThan(1_000);
  }
});

test("web export boots the Godot runtime in browser", async ({ page }) => {
  const pageErrors = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));

  await page.goto("/", { waitUntil: "domcontentloaded" });
  await expect.poll(async () => page.locator("#status").count(), {
    timeout: 30_000
  }).toBe(0);

  const canvas = page.locator("canvas");
  const box = await canvas.boundingBox();
  expect(box).not.toBeNull();
  expect(box.width).toBeGreaterThan(300);
  expect(box.height).toBeGreaterThan(600);

  const screenshot = await canvas.screenshot();
  expect(screenshot.length).toBeGreaterThan(10_000);
  expect(pageErrors).toEqual([]);
});

test("web export can complete the alpha route to Suijin and reload it", async ({ page }) => {
  const pageErrors = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));
  await page.addInitScript(() => {
    window.__SATORI_ALPHA_WEB_PLAYTEST__ = true;
  });

  await page.goto("/", { waitUntil: "domcontentloaded" });
  const result = await page.waitForFunction(() => {
    return window.__SATORI_ALPHA_WEB_PLAYTEST_RESULT__ || null;
  }, null, { timeout: 45_000 });
  const payload = await result.jsonValue();

  expect(payload).toMatchObject({
    ok: true,
    stage: "complete",
    route: {
      ok: true,
      stage: "route_complete",
      suijin_invited: true,
      fox_den_owner: "spirit_red_fox"
    },
    reload: {
      suijin_persisted: true,
      ku_unlocked: true,
      sacred_stone_coord: [12, 0],
      satori: 1000
    }
  });
  expect(payload.route.second_island_id).not.toBe(payload.route.first_island_id);
  expect(payload.reload.save_path).toBe("user://alpha_web_playtest/autosave.json");
  expect(pageErrors).toEqual([]);
});

test("web export packages seed recipe data and generated icon pngs", async ({ request }) => {
  for (const iconPath of ["/index.icon.png", "/index.apple-touch-icon.png"]) {
    const response = await request.get(iconPath);
    expect(response.ok()).toBe(true);
    expect(response.headers()["content-type"]).toContain("image/png");
    const body = await response.body();
    expect(body.length).toBeGreaterThan(1_000);
  }

  const pckResponse = await request.get("/index.pck");
  expect(pckResponse.ok()).toBe(true);
  const pckBuffer = await pckResponse.body();
  expectBufferToContain(pckBuffer, "recipe_chi");
  expectBufferToContain(pckBuffer, "recipe_fu");
  expectBufferToContain(pckBuffer, "recipe_ka");
  expectBufferToContain(pckBuffer, "Stone Seed");
  expectBufferToContain(pckBuffer, "Meadow Seed");
  expectBufferToContain(pckBuffer, "material_icon_spritesheet.png");
  expectBufferToContain(pckBuffer, "assets/structures/house/frames/idle/down/frame_0000.png.import");
  expectBufferToContain(pckBuffer, "assets/structures/fox_den/frames/idle/down/frame_0000.png.import");
  expectBufferToContain(pckBuffer, "materials.csv.txt");
  expectBufferToContain(pckBuffer, "rituals.csv.txt");
  expectBufferToContain(pckBuffer, "0.1.0-alpha+20260627.1");
  expectBufferToContain(pckBuffer, "alpha_web_playtest");
});

test("web export excludes development-only release folders", async ({ request }) => {
  const pckResponse = await request.get("/index.pck");
  expect(pckResponse.ok()).toBe(true);
  const pckBuffer = await pckResponse.body();

  for (const excludedPath of [
    "res://addons/gut/gut_cmdln.gd.remap",
    "res://addons/gut/error_tracker.gd.remap",
    "res://tests/unit/test_save_game_service.gd.remap",
    "res://tests/playwright/satori-web-smoke.spec.js",
    "res://specs/031-itch-web-alpha/spec.md",
    "res://tools/godot.ps1",
    "res://.godot/imported/",
    "playwright.config.js"
  ]) {
    expectBufferNotToContain(pckBuffer, excludedPath);
  }
});
