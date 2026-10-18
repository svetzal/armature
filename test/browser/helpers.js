const { test: base, expect } = require('@playwright/test');

// Fail every browser scenario on uncaught JS errors, failed assets or CSP errors.
const test = base.extend({
  page: async ({ page }, use) => {
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {
      if (message.type() === 'error') errors.push(message.text());
    });
    page.on('response', response => {
      if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`);
    });
    await use(page);
    expect(errors).toEqual([]);
  },
});

async function appearance(locator) {
  return locator.evaluate(element => {
    const style = getComputedStyle(element);
    return { background: style.backgroundColor, color: style.color, scheme: style.colorScheme };
  });
}

async function resize(page, selector, width) {
  await page.locator(selector).evaluate((element, value) => {
    element.style.width = `${value}px`;
  }, width);
  await expect.poll(() => page.locator(selector).evaluate(el => el.getBoundingClientRect().width))
    .toBeCloseTo(width, 0);
}

module.exports = { test, expect, appearance, resize };
