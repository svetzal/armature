const { test, expect } = require('./helpers');

const stops = page => page.locator('#example-toolbar-actions [tabindex="0"]');

test('without the hook every toolbar control is its own Tab stop', async ({ page }) => {
  await page.goto('/fixtures');
  await expect(page.locator('#plain-toolbar [tabindex]')).toHaveCount(0);
  await page.locator('#theme-three-auto').focus();
  await page.keyboard.press('Tab');
  await expect(page.locator('#plain-add')).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(page.locator('#plain-more')).toBeFocused();
});

test.describe('with the hook', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/ui?node=toolbar');
    await expect(stops(page)).toHaveCount(1);
  });

  test('the toolbar is one tab stop', async ({ page }) => {
    await expect(stops(page)).toHaveAttribute('id', 'example-toolbar-add');
    await expect(page.locator('#example-toolbar-actions button[tabindex="-1"]')).toHaveCount(3);
  });

  test('arrow keys move between enabled controls and skip a disabled one', async ({ page }) => {
    await page.locator('#example-toolbar-add').focus();
    await page.keyboard.press('ArrowRight');
    await expect(page.locator('#example-toolbar-edit')).toBeFocused();
    await page.keyboard.press('ArrowRight');
    await expect(page.locator('#example-toolbar-hidden')).toBeFocused();
    await expect(stops(page)).toHaveAttribute('id', 'example-toolbar-hidden');
  });

  test('arrow keys wrap at the ends', async ({ page }) => {
    await page.locator('#example-toolbar-add').focus();
    await page.keyboard.press('ArrowLeft');
    await expect(page.locator('#example-toolbar-more')).toBeFocused();
    await page.keyboard.press('ArrowRight');
    await expect(page.locator('#example-toolbar-add')).toBeFocused();
  });

  test('Home and End reach the first and last controls', async ({ page }) => {
    await page.locator('#example-toolbar-edit').focus();
    await page.keyboard.press('End');
    await expect(page.locator('#example-toolbar-more')).toBeFocused();
    await page.keyboard.press('Home');
    await expect(page.locator('#example-toolbar-add')).toBeFocused();
  });

  test('Tab leaves the toolbar from its tab stop', async ({ page }) => {
    await page.locator('#example-toolbar-edit').focus();
    await page.keyboard.press('Tab');
    const inside = await page.evaluate(() =>
      document.querySelector('#example-toolbar-actions').contains(document.activeElement));
    expect(inside).toBe(false);
    await page.keyboard.press('Shift+Tab');
    await expect(page.locator('#example-toolbar-edit')).toBeFocused();
  });

  test('a LiveView patch keeps the roving tabindex and the tab stop', async ({ page }) => {
    await page.locator('#example-toolbar-add').focus();
    await page.keyboard.press('Enter');
    await expect(page.getByText('Added an item. Items: 1.')).toBeVisible();
    await expect(page.locator('#example-toolbar-delete')).toBeEnabled();
    await expect(stops(page)).toHaveCount(1);
    await expect(stops(page)).toHaveAttribute('id', 'example-toolbar-add');
    await expect(page.locator('#example-toolbar-delete')).toHaveAttribute('tabindex', '-1');
    await page.keyboard.press('End');
    await page.keyboard.press('ArrowLeft');
    await page.keyboard.press('ArrowLeft');
    await expect(page.locator('#example-toolbar-delete')).toBeFocused();
  });

  test('a pressed toggle announces its state and stays the tab stop', async ({ page }) => {
    const toggle = page.locator('#example-toolbar-hidden');
    await toggle.focus();
    await page.keyboard.press('Space');
    await expect(toggle).toHaveAttribute('aria-pressed', 'true');
    await expect(page.getByText('Hidden items shown.')).toBeVisible();
    await expect(stops(page)).toHaveAttribute('id', 'example-toolbar-hidden');
  });

  test('a vertical toolbar moves with the up and down arrows', async ({ page }) => {
    const toolbar = page.locator('#example-toolbar-vertical');
    await toolbar.locator('button').first().focus();
    await page.keyboard.press('ArrowRight');
    await expect(toolbar.locator('button').first()).toBeFocused();
    await page.keyboard.press('ArrowDown');
    await expect(toolbar.locator('button').nth(1)).toBeFocused();
  });
});

test('icon buttons are square and grow to 44px on a narrow viewport', async ({ page }) => {
  await page.goto('/ui?node=icon_button');
  const size = () => page.locator('#example-icon-add').evaluate(el => {
    const r = el.getBoundingClientRect();
    return [Math.round(r.width), Math.round(r.height)];
  });
  expect(await size()).toEqual([32, 32]);
  await page.setViewportSize({ width: 375, height: 800 });
  expect(await size()).toEqual([44, 44]);
});

test('a pressed icon button differs by shape, not only colour', async ({ page }) => {
  await page.goto('/ui?node=icon_button');
  const toggle = page.locator('#example-icon-toggle');
  const shadow = () => toggle.evaluate(el => getComputedStyle(el).boxShadow);
  const before = await shadow();
  await toggle.click();
  await expect(toggle).toHaveAttribute('aria-pressed', 'true');
  await page.mouse.move(0, 0);
  await expect.poll(shadow).not.toBe(before);
  expect(await shadow()).toContain('inset');
});
