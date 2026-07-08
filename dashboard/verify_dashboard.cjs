const { chromium } = require('playwright');

const SHOT_DIR = 'C:/Users/Dell/AppData/Local/Temp/claude/C--Users-Dell-Sahali/4d31279d-672e-4767-ae41-c5e5bdb45cd1/scratchpad';
const consoleErrors = [];
const networkFailures = [];
const reportsResponses = [];

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });

  page.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('response', async res => {
    const url = res.url();
    if (url.includes('/v1/reports') && (url.includes('/history') || url.includes('/assignments'))) {
      try {
        const body = await res.text();
        reportsResponses.push({ url, status: res.status(), body: body.slice(0, 2000) });
      } catch (e) {}
    }
    if (res.status() >= 400) networkFailures.push(`${res.status()} ${url}`);
  });

  console.log('--- Navigating to login ---');
  await page.goto('http://localhost:5173/login', { waitUntil: 'load' });
  await page.screenshot({ path: `${SHOT_DIR}/1-login.png` });

  await page.fill('input[placeholder="you@example.com"]', 'admin@sahali.tn');
  await page.fill('input[placeholder="••••••••"]', 'Demo1234!');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(1500);
  console.log('URL after login:', page.url());
  await page.screenshot({ path: `${SHOT_DIR}/2-after-login.png` });

  console.log('--- Navigating to Reports ---');
  await page.goto('http://localhost:5173/reports', { waitUntil: 'load' });
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${SHOT_DIR}/3-reports-list.png` });

  console.log('--- Searching for report CA0JC0L3 (5 history rows / 5 assignments) ---');
  await page.fill('input[placeholder="Rechercher par code, titre, ville..."]', 'CA0JC0L3');
  await page.waitForTimeout(800);
  await page.screenshot({ path: `${SHOT_DIR}/3b-search-filtered.png` });

  const targetRow = page.locator('table tbody tr', { hasText: 'CA0JC0L3' });
  await targetRow.first().click();

  console.log('--- Waiting for detail panel to actually open ---');
  const tracTab = page.getByText('Traçabilité', { exact: false });
  const assignTab = page.getByText('Assignation', { exact: false });
  await tracTab.first().waitFor({ state: 'visible', timeout: 15000 });
  // Confirm the panel that opened is actually for CA0JC0L3, not a stale/other report
  await page.getByText('CA0JC0L3', { exact: false }).first().waitFor({ state: 'visible', timeout: 5000 });
  console.log('Detail panel appeared for the correct report (CA0JC0L3 confirmed on screen)');
  await page.screenshot({ path: `${SHOT_DIR}/4-report-detail.png` });

  console.log('--- Clicking Traçabilité tab ---');
  try {
    await tracTab.first().click({ timeout: 10000 });
    await page.waitForTimeout(1200);
    await page.screenshot({ path: `${SHOT_DIR}/5-tracabilite.png` });
  } catch (e) {
    console.log('Traçabilité tab click FAILED:', e.message);
  }

  console.log('--- Clicking Assignation tab ---');
  try {
    await assignTab.first().click({ timeout: 10000 });
    await page.waitForTimeout(1200);
    await page.screenshot({ path: `${SHOT_DIR}/6-assignation.png` });
  } catch (e) {
    console.log('Assignation tab click FAILED:', e.message);
  }

  console.log('=== CONSOLE ERRORS ===');
  console.log(JSON.stringify(consoleErrors, null, 2));
  console.log('=== NETWORK FAILURES (>=400) ===');
  console.log(JSON.stringify(networkFailures, null, 2));
  console.log('=== HISTORY/ASSIGNMENTS RESPONSES ===');
  console.log(JSON.stringify(reportsResponses, null, 2));

  await browser.close();
})().catch(e => { console.error('SCRIPT ERROR', e); process.exit(1); });
