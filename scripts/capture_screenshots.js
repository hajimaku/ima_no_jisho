/**
 * capture_screenshots.js
 * Playwright でアプリの全画面スクリーンショットを撮影する
 *
 * 使い方:
 *   node scripts/capture_screenshots.js [--date YYYY-MM-DD] [--port 3000]
 */

const { chromium } = require('/usr/local/lib/node_modules/@playwright/mcp/node_modules/playwright-core');
const fs = require('fs');
const path = require('path');

// 引数パース
const args = process.argv.slice(2);
const dateArg = args[args.indexOf('--date') + 1];
const portArg = args[args.indexOf('--port') + 1];

const today = dateArg || new Date().toISOString().slice(0, 10);
const port = portArg || '3000';
const baseUrl = `http://localhost:${port}`;

const screenshotDir = path.join(__dirname, '..', 'docs', 'screenshots', today);

// 撮影する画面の定義
const screens = [
  {
    id: 'S-01',
    name: 'splash',
    url: `${baseUrl}/#/splash`,
    filename: 'S-01_splash.png',
    waitMs: 800, // フェードイン途中の美しい状態
  },
  {
    id: 'S-02',
    name: 'home',
    url: baseUrl,
    filename: 'S-02_home.png',
    waitMs: 5000,
  },
  {
    id: 'S-03',
    name: 'result_確信犯',
    url: `${baseUrl}/#/result/%E7%A2%BA%E4%BF%A1%E7%8A%AF`,
    filename: 'S-03_result_確信犯.png',
    waitMs: 2000, // スケルトン表示
  },
  {
    id: 'S-03-loaded',
    name: 'result_確信犯_loaded',
    url: `${baseUrl}/#/result/%E7%A2%BA%E4%BF%A1%E7%8A%AF`,
    filename: 'S-03_result_確信犯_loaded.png',
    waitMs: 12000, // API応答（最大10s）＋フェードイン後
  },
  {
    id: 'S-04',
    name: 'daily_word',
    url: `${baseUrl}/#/daily-word`,
    filename: 'S-04_daily_word.png',
    waitMs: 8000, // API応答待ち
  },
  {
    id: 'S-04-share',
    name: 'daily_word_share',
    url: `${baseUrl}/#/daily-word`,
    filename: 'S-04_share_sheet.png',
    waitMs: 8000, // API応答待ち
    // ロード後にシェアボタン（AppBar右端）をクリックしてBottomSheetを開く
    clickAfterLoad: { x: 362, y: 28 },
    clickWaitMs: 1000,
  },
  {
    id: 'S-05',
    name: 'calendar',
    url: `${baseUrl}/#/calendar`,
    filename: 'S-05_calendar.png',
    waitMs: 4000,
  },
  {
    id: 'S-03-en',
    name: 'result_gaslight_loaded',
    url: `${baseUrl}/#/result/gaslight`,
    filename: 'S-03_result_gaslight.png',
    waitMs: 12000, // API応答待ち
  },
  {
    id: 'S-06',
    name: 'settings',
    url: `${baseUrl}/#/settings`,
    filename: 'S-06_settings.png',
    waitMs: 1500,
  },
];

async function main() {
  // 保存先ディレクトリを作成
  if (!fs.existsSync(screenshotDir)) {
    fs.mkdirSync(screenshotDir, { recursive: true });
  }

  console.log(`📸 スクリーンショット撮影開始: ${today}`);
  console.log(`   保存先: ${screenshotDir}`);
  console.log(`   対象URL: ${baseUrl}\n`);

  const browser = await chromium.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const results = [];

  for (const screen of screens) {
    const page = await browser.newPage();
    await page.setViewportSize({ width: 390, height: 844 });

    try {
      await page.goto(screen.url, { waitUntil: 'networkidle' });
      await page.waitForTimeout(screen.waitMs);

      // ロード後にクリック操作が定義されている場合は実行
      if (screen.clickAfterLoad) {
        await page.mouse.click(screen.clickAfterLoad.x, screen.clickAfterLoad.y);
        await page.waitForTimeout(screen.clickWaitMs || 800);
      }

      const savePath = path.join(screenshotDir, screen.filename);
      await page.screenshot({ path: savePath });

      const relativePath = `docs/screenshots/${today}/${screen.filename}`;
      results.push({ id: screen.id, path: relativePath });
      console.log(`  ✅ ${screen.id} — ${screen.filename}`);
    } catch (err) {
      console.error(`  ❌ ${screen.id} 失敗: ${err.message}`);
      results.push({ id: screen.id, path: null });
    } finally {
      await page.close();
    }
  }

  await browser.close();

  // 結果をJSONで出力（update_backlog.py が読み込む）
  const resultFile = path.join(__dirname, '.screenshot_results.json');
  fs.writeFileSync(resultFile, JSON.stringify({ date: today, screenshots: results }, null, 2));

  console.log(`\n📄 結果をJSON保存: ${resultFile}`);
  return results;
}

main().catch((err) => {
  console.error('エラー:', err);
  process.exit(1);
});
