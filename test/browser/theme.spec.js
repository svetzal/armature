const { test, expect, appearance } = require('./helpers');

for (const event of ['change', 'submit']) {
  test(`standalone ${event}: Light, Dark and Auto change appearance and synchronize switches`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'light' });
    await page.goto('/fixtures');
    const panel = page.locator('#first-panel');
    const light = await appearance(panel);
    const choose = async theme => {
      if (event === 'change') {
        await page.locator('#theme-one-choice').selectOption(theme);
      } else {
        await page.locator('#theme-one-choice').evaluate((el, value) => { el.value = value; }, theme);
        await page.getByRole('button', { name: 'Apply theme' }).click();
      }
      await expect(page.locator('#theme-two-choice')).toHaveValue(theme);
      await expect(page.locator('#theme-one [role=status]')).toHaveCSS('clip-path', 'inset(50%)');
      await expect(page.locator('#theme-one [role=status]')).toHaveText(`Theme: ${theme[0].toUpperCase()}${theme.slice(1)}`);
    };
    await choose('dark');
    await expect.poll(() => appearance(panel)).not.toEqual(light);
    const dark = await appearance(panel);
    await choose('light');
    await expect.poll(() => appearance(panel)).toEqual(light);
    await choose('auto');
    await expect(page.locator('html')).not.toHaveAttribute('data-armature-theme');
    await page.emulateMedia({ colorScheme: 'dark' });
    await expect.poll(() => appearance(panel)).toEqual(dark);
    await page.emulateMedia({ colorScheme: 'light' });
    await expect.poll(() => appearance(panel)).toEqual(light);
    expect(await page.evaluate(() => localStorage.getItem('armature-theme'))).toBeNull();
  });
}

test('reload restores a remembered choice; explicit server theme wins', async ({ page }) => {
  await page.goto('/fixtures');
  await page.locator('#theme-two-choice').selectOption('dark');
  await expect(page.locator('#theme-one-choice')).toHaveValue('dark');
  await expect(page.locator('#theme-two [role=status]')).toHaveText('Appearance: Dark');
  const dark = await appearance(page.locator('#first-panel'));
  await page.reload();
  await expect(page.locator('#theme-one-choice')).toHaveValue('dark');
  expect(await appearance(page.locator('#first-panel'))).toEqual(dark);
  await page.goto('/fixtures?theme=light');
  await expect(page.locator('#theme-one-choice')).toHaveValue('light');
  await expect.poll(() => appearance(page.locator('#first-panel'))).not.toEqual(dark);
});

for (const stored of ['auto', 'invalid', '']) {
  test(`invalid stored value ${JSON.stringify(stored)} falls back to system appearance`, async ({ page }) => {
    await page.addInitScript(value => localStorage.setItem('armature-theme', value), stored);
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.goto('/fixtures');
    await expect(page.locator('#theme-one-choice')).toHaveValue('auto');
    await expect(page.locator('html')).not.toHaveAttribute('data-armature-theme');
    expect((await appearance(page.locator('#first-panel'))).scheme).toBe('dark');
  });
}

test('unavailable storage still permits choosing a theme for the page', async ({ page }) => {
  await page.addInitScript(() => {
    Object.defineProperty(window, 'localStorage', { get() { throw new DOMException('Unavailable', 'SecurityError'); } });
  });
  await page.goto('/fixtures');
  await page.locator('#theme-one-choice').selectOption('dark');
  await expect(page.locator('#theme-two-choice')).toHaveValue('dark');
  expect((await appearance(page.locator('#first-panel'))).scheme).toBe('dark');
  await page.reload();
  await expect(page.locator('#theme-one-choice')).toHaveValue('auto');
});

test('catalogue connects and LiveView owns theme change and submit events', async ({ page }) => {
  await page.goto('/ui?node=button');
  await expect(page.locator('[data-phx-main]')).toHaveClass(/phx-connected/);
  const shell = page.locator('#armature-catalogue');
  const form = page.locator('#catalogue-theme');
  await expect(form).not.toHaveAttribute('data-armature-theme-enhanced');
  await form.locator('select').selectOption('dark');
  await expect(shell).toHaveAttribute('data-armature-theme', 'dark');
  expect((await appearance(shell)).scheme).toBe('dark');
  await form.locator('select').evaluate(el => { el.value = 'light'; el.form.requestSubmit(); });
  await expect(shell).toHaveAttribute('data-armature-theme', 'light');
  await expect(page.locator('html')).not.toHaveAttribute('data-armature-theme');
  expect(await page.evaluate(() => localStorage.getItem('armature-theme'))).toBeNull();
  await expect(form.locator('[role=status]')).toHaveCount(0);
});

test('enhancement also works when loaded after DOM readiness and is idempotent', async ({ page }) => {
  await page.route('**/assets/armature-theme.js', async route => {
    await route.fulfill({ contentType: 'text/javascript', body: '' });
  }, { times: 1 });
  await page.goto('/fixtures');
  await expect(page.locator('#theme-one [role=status]')).toHaveCount(0);
  await page.addScriptTag({ url: '/assets/armature-theme.js' });
  await page.addScriptTag({ url: '/assets/armature-theme.js' });
  await expect(page.locator('#theme-one [role=status]')).toHaveCount(1);
  await page.locator('#theme-one-choice').selectOption('dark');
  await expect(page.locator('#theme-two-choice')).toHaveValue('dark');
  await expect(page.locator('#theme-one [role=status]')).toHaveText('Theme: Dark');
});
