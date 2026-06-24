const { test, expect } = require("@playwright/test");

function expectBufferToContain(buffer, needle) {
  const needleBuffer = Buffer.from(needle, "utf8");
  expect(
    buffer.indexOf(needleBuffer),
    `index.pck should contain ${needle}`
  ).toBeGreaterThanOrEqual(0);
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
});
