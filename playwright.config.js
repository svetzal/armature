const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './test/browser',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  workers: 2,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: 'http://127.0.0.1:4022',
    browserName: 'chromium',
    viewport: { width: 1280, height: 900 },
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'MIX_ENV=test mix run --no-halt test/browser/server.exs',
    env: { MIX_BUILD_PATH: require('node:path').resolve('_build/browser') },
    url: 'http://127.0.0.1:4022/fixtures',
    reuseExistingServer: false,
    stdout: 'pipe',
    timeout: 120000,
  },
});
