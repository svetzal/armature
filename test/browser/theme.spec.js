const { test, expect, appearance } = require('./helpers');

const NAMES = { auto: 'System', light: 'Light', dark: 'Dark' };
const choice = (page, id, theme) => page.locator(`#${id}-${theme}`);

for (const event of ['change', 'submit']) {
  test(`standalone ${event}: System, Light and Dark change appearance and synchronize switches`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'light' });
    await page.goto('/fixtures');
    const panel = page.locator('#first-panel');
    const light = await appearance(panel);
    const choose = async theme => {
      if (event === 'change') {
        await choice(page, 'theme-one', theme).check();
      } else {
        await choice(page, 'theme-one', theme).evaluate(el => { el.checked = true; });
        await page.getByRole('button', { name: 'Apply theme' }).click();
      }
      await expect(choice(page, 'theme-two', theme)).toBeChecked();
      await expect(choice(page, 'theme-three', theme)).toBeChecked();
      await expect(page.locator('#theme-one [role=status]')).toHaveCSS('clip-path', 'inset(50%)');
      await expect(page.locator('#theme-one [role=status]')).toHaveText(`Theme: ${NAMES[theme]}`);
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
  await choice(page, 'theme-two', 'dark').check();
  await expect(choice(page, 'theme-one', 'dark')).toBeChecked();
  await expect(page.locator('#theme-two [role=status]')).toHaveText('Appearance: Dark');
  const dark = await appearance(page.locator('#first-panel'));
  await page.reload();
  await expect(choice(page, 'theme-one', 'dark')).toBeChecked();
  expect(await appearance(page.locator('#first-panel'))).toEqual(dark);
  await page.goto('/fixtures?theme=light');
  await expect(choice(page, 'theme-one', 'light')).toBeChecked();
  await expect.poll(() => appearance(page.locator('#first-panel'))).not.toEqual(dark);
});

for (const stored of ['auto', 'invalid', '']) {
  test(`invalid stored value ${JSON.stringify(stored)} falls back to system appearance`, async ({ page }) => {
    await page.addInitScript(value => localStorage.setItem('armature-theme', value), stored);
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.goto('/fixtures');
    await expect(choice(page, 'theme-one', 'auto')).toBeChecked();
    await expect(page.locator('html')).not.toHaveAttribute('data-armature-theme');
    expect((await appearance(page.locator('#first-panel'))).scheme).toBe('dark');
  });
}

test('unavailable storage still permits choosing a theme for the page', async ({ page }) => {
  await page.addInitScript(() => {
    Object.defineProperty(window, 'localStorage', { get() { throw new DOMException('Unavailable', 'SecurityError'); } });
  });
  await page.goto('/fixtures');
  await choice(page, 'theme-one', 'dark').check();
  await expect(choice(page, 'theme-two', 'dark')).toBeChecked();
  expect((await appearance(page.locator('#first-panel'))).scheme).toBe('dark');
  await page.reload();
  await expect(choice(page, 'theme-one', 'auto')).toBeChecked();
});

test('catalogue connects and LiveView owns theme change and submit events', async ({ page }) => {
  await page.goto('/ui?node=button');
  await expect(page.locator('[data-phx-main]')).toHaveClass(/phx-connected/);
  const shell = page.locator('#armature-catalogue');
  const form = page.locator('#catalogue-theme');
  await expect(form).not.toHaveAttribute('data-armature-theme-enhanced');
  await choice(page, 'catalogue-theme', 'dark').check();
  await expect(shell).toHaveAttribute('data-armature-theme', 'dark');
  await expect(choice(page, 'catalogue-theme', 'dark')).toBeChecked();
  expect((await appearance(shell)).scheme).toBe('dark');
  await choice(page, 'catalogue-theme', 'light').evaluate(el => { el.checked = true; el.form.requestSubmit(); });
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
  await choice(page, 'theme-one', 'dark').check();
  await expect(choice(page, 'theme-two', 'dark')).toBeChecked();
  await expect(page.locator('#theme-one [role=status]')).toHaveText('Theme: Dark');
});

test('the switch is one tab stop and arrow keys choose and announce', async ({ page }) => {
  await page.goto('/fixtures');
  await page.keyboard.press('Tab');
  await expect(choice(page, 'theme-one', 'auto')).toBeFocused();
  await page.keyboard.press('ArrowRight');
  await expect(choice(page, 'theme-one', 'light')).toBeFocused();
  await expect(choice(page, 'theme-one', 'light')).toBeChecked();
  await expect(page.locator('html')).toHaveAttribute('data-armature-theme', 'light');
  await expect(page.locator('#theme-one [role=status]')).toHaveText('Theme: Light');
  await page.keyboard.press('ArrowRight');
  await expect(page.locator('#theme-one [role=status]')).toHaveText('Theme: Dark');
  await expect(choice(page, 'theme-two', 'dark')).toBeChecked();
  await page.keyboard.press('Tab');
  await expect(page.getByRole('button', { name: 'Apply theme' })).toBeFocused();
});

test('each segment is named in words inside a group named by its legend', async ({ page }) => {
  await page.goto('/fixtures');
  await expect(page.locator('#theme-one fieldset')).toMatchAriaSnapshot(`
    - group "Theme":
      - radio "System" [checked]
      - radio "Light"
      - radio "Dark"
  `);
  for (const [theme, name] of Object.entries(NAMES)) {
    await expect(choice(page, 'theme-one', theme)).toHaveAccessibleName(name);
    await expect(choice(page, 'theme-one', theme)).toHaveAccessibleDescription('');
  }
});

test('a visible legend sits on the same row as its segments', async ({ page }) => {
  await page.goto('/fixtures');
  const legend = page.locator('#theme-three legend');
  await expect(legend).toBeVisible();
  await expect(legend).toHaveText('Colour scheme');
  await expect(page.locator('#theme-one legend')).toHaveCSS('clip-path', 'inset(50%)');
  const text = await legend.boundingBox();
  const segments = await page.locator('#theme-three .armature-theme-switch-options').boundingBox();
  expect(text.x + text.width).toBeLessThanOrEqual(segments.x);
  expect(text.y + text.height / 2).toBeGreaterThan(segments.y);
  expect(text.y + text.height / 2).toBeLessThan(segments.y + segments.height);
});

test('the switch lines up in height with buttons and inputs', async ({ page }) => {
  await page.goto('/fixtures');
  const segment = await page.locator('#theme-one .armature-theme-switch-option').first().boundingBox();
  const input = await page.locator('#valid').boundingBox();
  expect(segment.height).toBeCloseTo(input.height, 0);
  expect(segment.width).toBeCloseTo(segment.height, 0);
});
