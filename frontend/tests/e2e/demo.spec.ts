import { expect, test, type Page } from '@playwright/test';

function trackForeignRequests(page: Page): string[] {
  const foreignRequests: string[] = [];
  page.on('request', (request) => {
    const url = new URL(request.url());
    if (url.host !== '127.0.0.1:4173') foreignRequests.push(request.url());
  });
  return foreignRequests;
}

async function expectDemoNotice(page: Page) {
  await expect(
    page.getByText(/Änderungen werden nicht gespeichert oder übertragen/).last(),
  ).toBeVisible();
}

test('portfolio entry and both roles work without login or foreign requests', async ({ page }) => {
  const foreignRequests = trackForeignRequests(page);

  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'ActNow' })).toBeVisible();
  await expect(page.getByText('keine echte Plattform')).toBeVisible();

  await page.getByRole('button', { name: 'Als Helferin erkunden' }).click();
  await expect(page).toHaveURL(/\/discover$/);
  await expect(page.getByText(/Hallo Anna/)).toBeVisible();

  await page.getByRole('button', { name: 'SV Sonnenschein (Verein)' }).click();
  await expect(page).toHaveURL(/\/dashboard$/);
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();

  expect(foreignRequests).toEqual([]);
  expect(await page.context().cookies()).toEqual([]);
  expect(
    await page.evaluate(() => ({
      localStorage: localStorage.length,
      sessionStorage: sessionStorage.length,
      indexedDb: typeof indexedDB === 'undefined' ? 'unavailable' : 'unused',
    })),
  ).toEqual({ localStorage: 0, sessionStorage: 0, indexedDb: 'unused' });
});

test('write-looking actions stay read-only and reload resets form state', async ({ page }) => {
  await page.goto('/offers/offer-gartenaktion');
  await page.getByRole('button', { name: /Jetzt bewerben/ }).click();
  await page.getByRole('button', { name: 'Ja, bewerben', exact: true }).click();
  await expectDemoNotice(page);
  await page.getByRole('button', { name: 'Merken' }).click();
  await expectDemoNotice(page);
  await expect(page.getByRole('button', { name: /Jetzt bewerben/ })).toBeVisible();

  await page.goto('/messages/conversation-anna-sommerfest');
  await page.getByPlaceholder('Nachricht schreiben…').fill('Diese Nachricht bleibt lokal.');
  await page.getByRole('button', { name: 'Senden' }).click();
  await expectDemoNotice(page);
  await expect(page.getByText('Diese Nachricht bleibt lokal.')).toHaveCount(0);

  await page.getByRole('button', { name: 'SV Sonnenschein (Verein)' }).click();
  await page.goto('/offers/new');
  await page.getByLabel('Titel').fill('Nur ein lokaler Formularwert');
  await page
    .getByLabel('Beschreibung')
    .fill('Dieser ausreichend lange Beschreibungstext bleibt ausschließlich im Formular.');
  await page.getByLabel('Stadt').fill('Berlin');
  await page.getByRole('button', { name: 'Veröffentlichen' }).click();
  await expectDemoNotice(page);
  await page.reload();
  await expect(page.getByLabel('Titel')).toHaveValue('');
});

test('all primary pages load from static assets without console errors', async ({ page }) => {
  const foreignRequests = trackForeignRequests(page);
  const consoleErrors: string[] = [];
  page.on('console', (message) => {
    if (message.type() === 'error') consoleErrors.push(message.text());
  });

  const pages = [
    ['/discover', /Entdecken · ActNow/],
    ['/community', /Community · ActNow/],
    ['/applications', /Bewerbungen & Einsätze · ActNow/],
    ['/rewards', /Rewards · ActNow/],
    ['/favorites', /Favoriten · ActNow/],
    ['/calendar', /Kalender · ActNow/],
    ['/offers/offer-gartenaktion', /Gemeinschaftsgarten.*ActNow/],
    ['/dashboard', /Dashboard · ActNow/],
    ['/offers', /Angebote · ActNow/],
    ['/offers/new', /Neues Angebot · ActNow/],
    ['/offers/offer-sommerfest/applications', /Bewerbungen · ActNow/],
    ['/messages', /Nachrichten · ActNow/],
    ['/messages/conversation-anna-sommerfest', /Konversation · ActNow/],
    ['/profile', /Profil · ActNow/],
  ] as const;

  for (const [path, title] of pages) {
    await page.goto(path);
    await expect(page).toHaveTitle(title);
    await expect(page.locator('body')).not.toContainText('Laden fehlgeschlagen');
  }

  await page.goto('/login');
  await expect(page).toHaveURL(/\/$/);
  await page.goto('/register');
  await expect(page).toHaveURL(/\/$/);

  expect(foreignRequests).toEqual([]);
  expect(consoleErrors).toEqual([]);
});

test('swipe deck can be explored and reset locally', async ({ page }) => {
  await page.goto('/discover');
  const topCard = page.locator('[aria-label^="Wische rechts zum Bewerben"]');
  const initialLabel = await topCard.getAttribute('aria-label');
  expect(initialLabel).toBeTruthy();

  await page.getByRole('button', { name: 'Bewerben', exact: true }).click();
  await expectDemoNotice(page);
  await expect(topCard).not.toHaveAttribute('aria-label', initialLabel!);

  await page.getByRole('button', { name: 'Letzte Karte zurückholen' }).click();
  await expect(topCard).toHaveAttribute('aria-label', initialLabel!);

  await page.getByRole('button', { name: 'Ablehnen', exact: true }).click();
  await page.reload();
  await expect(topCard).toHaveAttribute('aria-label', initialLabel!);
});

test('organization status actions and profile edits remain unchanged', async ({ page }) => {
  await page.goto('/offers');
  const draftRow = page.getByRole('row').filter({ hasText: 'Nachhilfe für Jugendliche' });
  await draftRow.getByRole('button', { name: 'Menü' }).click();
  await page.getByRole('menuitem', { name: 'Veröffentlichen' }).click();
  await expectDemoNotice(page);
  await expect(draftRow).toContainText('Entwurf');

  await draftRow.getByRole('button', { name: 'Menü' }).click();
  await page.getByRole('menuitem', { name: 'Bearbeiten' }).click();
  await expectDemoNotice(page);

  await page.goto('/offers/offer-sommerfest/applications');
  const anna = page.getByRole('article').filter({ hasText: 'Anna Helferin' });
  await anna.getByRole('button', { name: 'Annehmen' }).click();
  await expectDemoNotice(page);
  await expect(anna.getByRole('button', { name: 'Annehmen' })).toBeVisible();
  await anna.getByRole('button', { name: 'Ablehnen' }).click();
  await expectDemoNotice(page);

  const bernd = page.getByRole('article').filter({ hasText: 'Bernd Beispiel' });
  await bernd.getByRole('button', { name: 'Abschließen' }).click();
  await expectDemoNotice(page);
  await expect(bernd).toContainText('Zugesagt');

  await page.goto('/profile');
  await page.getByRole('button', { name: 'Bearbeiten', exact: true }).first().click();
  await expectDemoNotice(page);
});

test('helper withdrawal and notification actions remain unchanged', async ({ page }) => {
  await page.goto('/applications');
  await page.getByRole('button', { name: 'Zurückziehen' }).first().click();
  await page.getByRole('button', { name: 'Zurückziehen', exact: true }).last().click();
  await expectDemoNotice(page);
  await expect(page.getByRole('button', { name: 'Zurückziehen' }).first()).toBeVisible();

  await page.goto('/community');
  await page.getByRole('button', { name: /Aktivität/ }).click();
  await page.getByRole('button', { name: 'Alle gelesen' }).click();
  await expectDemoNotice(page);
  await expect(page.getByRole('button', { name: 'Alle gelesen' })).toBeVisible();
});

test('deep links and missing fixture ids have useful states', async ({ page }) => {
  await page.goto('/offers/offer-sommerfest/applications');
  await expect(page.getByRole('heading', { name: 'Aufbau Sommerfest' })).toBeVisible();
  await expect(page.getByText('Anna Helferin')).toBeVisible();

  await page.goto('/offers/not-a-demo-offer');
  await expect(page.getByText('Angebot nicht gefunden')).toBeVisible();

  await page.goto('/messages/not-a-demo-conversation');
  await expect(page.getByText('Konversation nicht gefunden')).toBeVisible();

  await page.goto('/offers/not-a-demo-offer/applications');
  await expect(page.getByText('Angebot nicht gefunden')).toBeVisible();
});
