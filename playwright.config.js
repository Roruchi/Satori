const { defineConfig, devices } = require("@playwright/test");

const baseURL = process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:8060";

module.exports = defineConfig({
  testDir: "./tests/playwright",
  timeout: 90_000,
  expect: {
    timeout: 15_000
  },
  use: {
    baseURL,
    trace: "on-first-retry"
  },
  projects: [
    {
      name: "mobile-chromium",
      use: {
        ...devices["Pixel 5"]
      }
    }
  ],
  webServer: process.env.PLAYWRIGHT_BASE_URL
    ? undefined
    : {
        command: "python -m http.server 8060 -d build/web",
        url: baseURL,
        reuseExistingServer: true,
        timeout: 10_000
      }
});
