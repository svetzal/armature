const { test, expect } = require('./helpers');

async function styles(locator, pseudo = null) {
  return locator.evaluate((el, pseudo) => {
    const s = getComputedStyle(el, pseudo);
    return {
      outline: s.outlineStyle, width: parseFloat(s.outlineWidth), offset: parseFloat(s.outlineOffset),
      outlineColor: s.outlineColor, background: s.backgroundColor, color: s.color,
      border: s.borderStyle, borderColor: s.borderColor, shadow: s.boxShadow,
      animation: parseFloat(s.animationDuration), transition: parseFloat(s.transitionDuration),
      iterations: s.animationIterationCount, appearance: s.appearance, content: s.content,
    };
  }, pseudo);
}

// A theme radio covers its segment and the segment draws the ring.
async function visibleFocus(locator, ring = locator) {
  await expect(locator).toBeFocused();
  const focus = await styles(ring);
  expect(focus.outline).not.toBe('none');
  expect(focus.width).toBeGreaterThanOrEqual(2);
  expect(focus.outlineColor).not.toBe('rgba(0, 0, 0, 0)');
  expect(await locator.evaluate(el => {
    const r = el.getBoundingClientRect();
    const hit = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2);
    return r.top >= 0 && r.bottom <= innerHeight && (hit === el || el.contains(hit));
  })).toBe(true);
}

for (const theme of ['light', 'dark']) {
  test(`keyboard reaches named controls with visible unobscured focus (${theme})`, async ({ page }) => {
    await page.goto(`/fixtures?theme=${theme}`);
    // The script checks the radio for the page's theme, the group's one tab stop.
    const controls = [`#theme-one-${theme}`, '#theme-one button', `#theme-two-${theme}`,
      '.armature-skip-link', '#shell-rail .armature-side-nav-brand > a', '#shell-rail nav a', '#navigation a', '#open-example', '#enabled', '#valid', '#invalid'];
    for (const selector of controls) {
      await page.keyboard.press('Tab');
      const ring = selector.startsWith('#theme-') && !selector.endsWith('button')
        ? page.locator(`label:has(> ${selector})`) : page.locator(selector);
      await visibleFocus(page.locator(selector), ring);
    }
    await expect(page.locator(`#theme-one-${theme}`)).toHaveAccessibleName(theme === 'dark' ? 'Dark' : 'Light');
    await expect(page.locator('#enabled')).toHaveAccessibleName('Save');
    await expect(page.locator('#valid')).toHaveAccessibleName('Name');
    await expect(page.locator('#invalid')).toHaveAccessibleName('Required name');
    await expect(page.locator('#shell-rail nav a')).toHaveAttribute('aria-current', 'page');
    await expect(page.locator('#disabled')).toBeDisabled();
    await expect(page.locator('#disabled-input')).toBeDisabled();
    await expect(page.locator('#invalid')).toHaveAccessibleDescription('Enter a name');
    await expect(page.locator('#invalid')).toMatchAriaSnapshot('- textbox "Required name" [invalid]');
  });

  test(`disabled, invalid and selected controls expose visible state cues (${theme})`, async ({ page }) => {
    await page.goto(`/fixtures?theme=${theme}`);
    for (const selector of ['#disabled', '#disabled-input']) {
      const disabled = await styles(page.locator(selector));
      expect(disabled.border).toBe('dashed');
      expect(disabled.color).not.toBe(disabled.background);
      expect(disabled.borderColor).not.toBe(disabled.background);
    }
    const invalid = await styles(page.locator('#invalid'));
    const valid = await styles(page.locator('#valid'));
    expect(invalid.shadow).not.toBe('none');
    expect(invalid.borderColor).not.toBe(valid.borderColor);
    // The chosen theme is a raised thumb: a bordered paper surface with a
    // shadow, while the other choices sit unbordered on the track.
    const chosen = await styles(page.locator(`label:has(> #theme-one-${theme})`));
    const other = await styles(page.locator('label:has(> #theme-one-auto)'));
    expect(chosen.border).toBe('solid');
    expect(other.border).toBe('none');
    expect(chosen.shadow).not.toBe('none');
    expect(other.shadow).toBe('none');
    expect(chosen.background).not.toBe(other.background);
    expect(chosen.color).not.toBe(other.color);
    await expect(page.locator('#records-r1 button')).toHaveAttribute('aria-pressed', 'true');
    await expect(page.locator('#records-r2 button')).toHaveAttribute('aria-pressed', 'false');
    expect((await styles(page.locator('#records-r1 td').first())).shadow).not.toBe('none');
    expect((await styles(page.locator('#records-r1'))).background)
      .not.toBe((await styles(page.locator('#records-r2'))).background);
    await page.locator('#records-r1 button').focus();
    await page.keyboard.press('Tab');
    await page.keyboard.press('Shift+Tab');
    await visibleFocus(page.locator('#records-r1 button'));
    expect((await styles(page.locator('#records-r1'))).outline).toBe('solid');
    const numeric = await page.locator('#records-r1 td').last().evaluate(el => {
      const s = getComputedStyle(el); return [s.textAlign, s.fontVariantNumeric];
    });
    expect(numeric).toEqual(['end', 'tabular-nums']);
    const rowLabel = await styles(page.locator('#records-r1 button'));
    expect(rowLabel.border).toBe('none');
    expect(rowLabel.background).toBe('rgba(0, 0, 0, 0)');
    // Zebra striping, hover and selection each remain visible in both themes.
    const even = page.locator('#records-r2');
    const odd = page.locator('#records-r3');
    expect((await styles(even)).background).not.toBe((await styles(odd)).background);
    const beforeHover = (await styles(odd)).background;
    await odd.hover();
    await expect.poll(async () => (await styles(odd)).background).not.toBe(beforeHover);
  });

  test(`table scrolling keeps keyboard focus outside sticky headings (${theme})`, async ({ page }) => {
    await page.goto(`/fixtures?theme=${theme}`);
    const region = page.getByRole('region', { name: 'Records', exact: true });
    const header = page.locator('#records th').first();
    await region.scrollIntoViewIfNeeded();
    await region.evaluate(el => { el.scrollTop = 180; });
    const bounds = await region.boundingBox();
    const heading = await header.boundingBox();
    expect(heading.y).toBeGreaterThanOrEqual(bounds.y);
    expect(heading.y).toBeLessThan(bounds.y + 8);
    await region.focus();
    await page.keyboard.press('Tab');
    await visibleFocus(page.getByRole('button', { name: 'Sort by Name' }));
    for (let index = 1; index <= 10; index++) {
      await page.keyboard.press('Tab');
      const rowButton = page.getByRole('button', { name: `Record ${index}`, exact: true });
      await visibleFocus(rowButton);
      const r = await rowButton.boundingBox();
      const h = await header.boundingBox();
      expect(r.y).toBeGreaterThanOrEqual(h.y + h.height);
      const viewport = await region.boundingBox();
      expect(r.y).toBeGreaterThanOrEqual(viewport.y);
      expect(r.y + r.height).toBeLessThanOrEqual(viewport.y + viewport.height);
    }
  });

  test(`targets meet AA on desktop and 44px at narrow widths (${theme})`, async ({ page }) => {
    await page.goto(`/fixtures?theme=${theme}`);
    for (const width of [1280, 320]) {
      await page.setViewportSize({ width, height: 900 });
      for (const selector of ['#enabled', '#valid', '#invalid', '#theme-one-auto', '#theme-one-dark',
        '#records .armature-sort', '#records-r1 button', '#shell-rail nav a']) {
        const r = await page.locator(selector).boundingBox();
        const minimum = width === 320 || selector === '#shell-rail nav a' ? 44 : 24;
        expect(r.width, selector).toBeGreaterThanOrEqual(minimum);
        expect(r.height, selector).toBeGreaterThanOrEqual(minimum);
      }
    }
  });

  test(`reduced motion removes effective animations and transitions (${theme})`, async ({ page }) => {
    await page.goto(`/fixtures?theme=${theme}`);
    const button = page.locator('#enabled');
    expect((await styles(button)).animation).toBeGreaterThan(0);
    expect((await styles(button)).transition).toBeGreaterThan(0);
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await expect.poll(async () => (await styles(button)).animation).toBe(0);
    expect((await styles(button)).transition).toBe(0);
    expect((await styles(button)).iterations).toBe('1');
  });

  test(`forced colours distinguish selection, focus and invalid states without colour (${theme})`, async ({ page }) => {
    await page.emulateMedia({ forcedColors: 'active' });
    await page.goto(`/fixtures?theme=${theme}`);
    const selected = page.locator('#selected');
    const selection = await styles(selected);
    expect(selection.outline).toBe('solid');
    expect(selection.offset).toBeLessThan(0);
    await selected.focus();
    await page.keyboard.press('Tab');
    await page.keyboard.press('Shift+Tab');
    await visibleFocus(selected);
    const focusedSelection = await styles(selected);
    expect(focusedSelection.outline).toBe('double');
    expect(focusedSelection.offset).toBeGreaterThan(0);
    const invalid = page.locator('#invalid');
    expect((await styles(invalid)).outline).toBe('dashed');
    await invalid.focus();
    await page.keyboard.press('Tab');
    await page.keyboard.press('Shift+Tab');
    await visibleFocus(invalid);
    expect((await styles(invalid)).outline).toBe('solid');
    expect((await styles(page.locator('#disabled'))).border).toBe('dashed');
    expect((await styles(page.locator('#shell-rail nav a'))).border).toBe('solid');
    expect((await styles(page.locator('#single'))).appearance).toBe('auto');
    const wrapper = page.locator('.armature-select-wrap').filter({ has: page.locator('#single') });
    expect((await styles(wrapper, '::after')).content).toBe('none');
    const chosen = page.locator(`label:has(> #theme-one-${theme})`);
    expect((await styles(chosen)).outline).toBe('solid');
    expect((await styles(chosen)).offset).toBeLessThan(0);
    expect((await styles(page.locator('label:has(> #theme-one-auto)'))).outline).toBe('none');
    await page.locator(`#theme-one-${theme}`).focus();
    await page.keyboard.press('Tab');
    await page.keyboard.press('Shift+Tab');
    await visibleFocus(page.locator(`#theme-one-${theme}`), chosen);
    expect((await styles(chosen)).outline).toBe('double');
    expect((await styles(chosen)).offset).toBeGreaterThan(0);
  });
}

test('native single and multiple selects and checkbox retain usable geometry', async ({ page }) => {
  await page.goto('/fixtures');
  const choice = page.locator('#single');
  expect((await styles(choice)).appearance).toBe('none');
  const chevron = await styles(page.locator('.armature-select-wrap').filter({ has: choice }), '::after');
  expect(chevron.content).toBe('""');
  expect(chevron.borderColor).not.toBe('rgba(0, 0, 0, 0)');
  expect((await styles(page.locator('#list'))).appearance).toBe('auto');
  expect((await styles(page.locator('.armature-select-wrap').filter({ has: page.locator('#list') }), '::after')).content).toBe('none');
  const checkbox = page.getByRole('checkbox', { name: 'Include record' });
  const r = await checkbox.boundingBox();
  expect(r.width).toBe(r.height);
  expect(r.width).toBeLessThan(24);
  await page.getByText('Include record', { exact: true }).click();
  await expect(checkbox).toBeChecked();
});

test.describe('coarse pointer', () => {
  test.use({ hasTouch: true });
  test('controls grow to 44px without a narrow viewport', async ({ page }) => {
    await page.goto('/fixtures');
    for (const selector of ['#enabled', '#valid', '#theme-one-auto', '#records-r1 button']) {
      const r = await page.locator(selector).boundingBox();
      expect(r.width).toBeGreaterThanOrEqual(44);
      expect(r.height).toBeGreaterThanOrEqual(44);
    }
  });
});

for (const theme of ['light', 'dark']) {
  test(`compact tables reduce cell padding while keeping named row actions (${theme})`, async ({ page }) => {
    await page.goto('/ui?node=data_table');
    await expect(page.locator('[data-phx-main]')).toHaveClass(/phx-connected/);
    await page.locator(`#catalogue-theme-${theme}`).check();
    const compact = page.locator('#example-table tbody tr').first();
    const regular = page.locator('#example-table-default tbody tr').first();
    expect((await compact.boundingBox()).height).toBeLessThan((await regular.boundingBox()).height);
    const padding = async row => row.locator('td').first().evaluate(el => parseFloat(getComputedStyle(el).paddingTop));
    expect(await padding(compact)).toBeLessThan(await padding(regular));
    const action = compact.getByRole('button');
    expect(await action.getAttribute('aria-controls')).toBe('example-details');
    await expect(action).toHaveAccessibleName(/Example \d+/);
    const links = page.locator('.armature-catalogue-detail ul a');
    expect(await links.count()).toBeGreaterThan(0);
    for (const link of await links.all()) expect((await link.boundingBox()).width).toBeGreaterThanOrEqual(24);
  });
}

for (const theme of ['light', 'dark']) {
  test(`forced colours retain table selection when focus moves away (${theme})`, async ({ page }) => {
    await page.emulateMedia({ forcedColors: 'active' });
    await page.goto(`/fixtures?theme=${theme}`);
    const row = page.locator('#records-r1');
    const selected = await styles(row);
    expect(selected.outline).toBe('solid');
    expect(selected.width).toBeGreaterThanOrEqual(2);
    expect(selected.offset).toBeLessThan(0);
    await row.getByRole('button').focus();
    await page.keyboard.press('Tab');
    await page.keyboard.press('Shift+Tab');
    await visibleFocus(row.getByRole('button'));
    const focused = await styles(row);
    expect(focused.outline).toBe('double');
    // Keep the ring inside the scrolling region, where it cannot be clipped.
    expect(focused.offset).toBeLessThanOrEqual(-focused.width);
    await page.keyboard.press('Tab');
    expect((await styles(row)).outline).toBe('solid');
    expect((await styles(page.locator('#records-r2'))).outline).toBe('solid');
  });
}
