const { test, expect, resize } = require('./helpers');

async function box(page, selector) { return page.locator(selector).boundingBox(); }

for (const theme of ['light', 'dark']) {
  test(`shell responds to container width on both sides of 800 and 520 (${theme})`, async ({ page }) => {
    await page.goto(`/fixtures?theme=${theme}`);
    for (const [width, railWidth] of [[801, 210], [799, 155], [521, 155], [519, 519]]) {
      await resize(page, '#shell-host', width);
      await expect.poll(async () => (await box(page, '#shell-rail')).width).toBeCloseTo(railWidth, 0);
      const rail = await box(page, '#shell-rail');
      const main = await box(page, '#shell .armature-app-shell-main');
      if (width < 520) expect(main.y).toBeGreaterThanOrEqual(rail.y + rail.height);
      else expect(main.x).toBeGreaterThanOrEqual(rail.x + rail.width);
      await expect(page.getByRole('navigation', { name: 'Main' }).getByRole('link', { name: 'Overview' })).toBeVisible();
    }
    expect(page.viewportSize().width).toBe(1280);
    await expect(page.getByRole('main')).toHaveCount(1);
  });

  test(`navigation switches to a usable native picker at 760 (${theme})`, async ({ page }) => {
    await page.goto(`/fixtures?theme=${theme}`);
    await resize(page, '#nav-host', 761);
    await expect(page.locator('#navigation nav')).toBeVisible();
    await expect(page.locator('#navigation-choice')).toBeHidden();
    await resize(page, '#nav-host', 759);
    await expect(page.locator('#navigation nav')).toBeHidden();
    const picker = page.locator('#navigation-choice');
    await expect(picker).toBeVisible();
    await expect(picker).toHaveAccessibleName('Examples');
    await picker.selectOption('/fixtures?destination=second');
    // A controller owns navigation here; native submit carries the selected destination.
    await page.getByRole('button', { name: 'Open example' }).click();
    await expect(page).toHaveURL(/destination=%2Ffixtures%3Fdestination%3Dsecond/);
  });

  test(`grid measures two columns then one at 520 (${theme})`, async ({ page }) => {
    await page.goto(`/fixtures?theme=${theme}`);
    for (const width of [521, 519]) {
      await resize(page, '#grid-host', width);
      const first = await box(page, '#first-panel');
      const second = await box(page, '#second-panel');
      if (width > 520) {
        expect(second.y).toBeCloseTo(first.y, 0);
        expect(second.x).toBeGreaterThan(first.x + first.width);
      } else {
        expect(second.x).toBeCloseTo(first.x, 0);
        expect(second.y).toBeGreaterThan(first.y + first.height);
      }
      expect(second.x + second.width).toBeLessThanOrEqual(first.x + width + 1);
    }
  });

  test(`320px reflow has no unintended page overflow (${theme})`, async ({ page }) => {
    await page.setViewportSize({ width: 320, height: 800 });
    await page.goto(`/fixtures?theme=${theme}`);
    await expect(page.locator('#navigation-choice')).toBeVisible();
    await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    await page.goto('/ui?node=button');
    await expect(page.locator('[data-phx-main]')).toHaveClass(/phx-connected/);
    await page.locator('#catalogue-theme-choice').selectOption(theme);
    await expect(page.locator('#catalogue-components-choice')).toBeVisible();
    await page.locator('#catalogue-components-choice').selectOption('/ui?node=link');
    await expect(page).toHaveURL(/node=link/);
    await expect(page.locator('#armature-catalogue-heading-link')).toBeFocused();
    await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    await page.screenshot({ path: `test-results/catalogue-${theme}-narrow.png`, fullPage: true });
  });
}

for (const theme of ['light', 'dark']) {
  test(`catalogue walkthrough includes table selection and inspector reflow (${theme})`, async ({ page }) => {
    await page.goto('/ui?node=table_inspector');
    await expect(page.locator('[data-phx-main]')).toHaveClass(/phx-connected/);
    await page.locator('#catalogue-theme-choice').selectOption(theme);
    const template = page.locator('#example-records');
    const selection = template.locator('.armature-row-select').first();
    await selection.click();
    await expect(selection).toHaveAttribute('aria-pressed', 'true');
    await expect(page.locator('#example-records-selection')).not.toHaveText('No record selected.');
    const tableArea = template.locator('.armature-split > div').first();
    const inspector = page.locator('#example-records-inspector');
    for (const width of [1280, 320]) {
      await page.setViewportSize({ width, height: 900 });
      const left = await tableArea.boundingBox();
      const right = await inspector.boundingBox();
      if (width === 1280) expect(right.x).toBeGreaterThanOrEqual(left.x + left.width);
      else expect(right.y).toBeGreaterThanOrEqual(left.y + left.height);
      await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
      await page.screenshot({ path: `test-results/catalogue-table-${theme}-${width}.png`, fullPage: true });
    }
  });
}
