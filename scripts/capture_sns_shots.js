/**
 * capture_sns_shots.js
 * SNS投稿用スクリーンショットを撮影する
 * 使い方: node scripts/capture_sns_shots.js
 */

const { chromium } = require('/usr/local/lib/node_modules/@playwright/mcp/node_modules/playwright-core');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:3000';
const TODAY = new Date().toISOString().slice(0, 10);
const OUT_DIR = path.join(__dirname, '..', 'docs', 'screenshots', TODAY, 'sns');

// 撮影対象（確信犯・煮詰まる以外の言葉 + 今日の一言）
const SHOTS = [
  {
    id: 'search_役不足',
    url: `${BASE_URL}/#/result/${encodeURIComponent('役不足')}`,
    filename: 'search_役不足.png',
    waitMs: 14000,
    desc: '役不足（誤用系・超定番）',
  },
  {
    id: 'search_姑息',
    url: `${BASE_URL}/#/result/${encodeURIComponent('姑息')}`,
    filename: 'search_姑息.png',
    waitMs: 14000,
    desc: '姑息（誤用系）',
  },
  {
    id: 'search_爆笑',
    url: `${BASE_URL}/#/result/${encodeURIComponent('爆笑')}`,
    filename: 'search_爆笑.png',
    waitMs: 14000,
    desc: '爆笑（誤用系）',
  },
  {
    id: 'search_敷居が高い',
    url: `${BASE_URL}/#/result/${encodeURIComponent('敷居が高い')}`,
    filename: 'search_敷居が高い.png',
    waitMs: 14000,
    desc: '敷居が高い（誤用系）',
  },
  {
    id: 'search_literally',
    url: `${BASE_URL}/#/result/literally`,
    filename: 'search_literally.png',
    waitMs: 14000,
    desc: 'literally（英語・誤用系）',
  },
  {
    id: 'search_vibe',
    url: `${BASE_URL}/#/result/vibe`,
    filename: 'search_vibe.png',
    waitMs: 14000,
    desc: 'vibe（英語・現代スラング）',
  },
  {
    id: 'daily_word',
    url: `${BASE_URL}/#/daily-word`,
    filename: 'daily_word_today.png',
    waitMs: 12000,
    desc: '今日の一言',
  },
];

async function main() {
  if (!fs.existsSync(OUT_DIR)) {
    fs.mkdirSync(OUT_DIR, { recursive: true });
  }

  console.log(`\n📸 SNS用スクリーンショット撮影`);
  console.log(`   保存先: docs/screenshots/${TODAY}/sns/`);
  console.log(`   対象: ${SHOTS.length}件\n`);

  const browser = await chromium.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const results = [];

  for (const shot of SHOTS) {
    const page = await browser.newPage();
    await page.setViewportSize({ width: 390, height: 844 });

    console.log(`  ⏳ ${shot.desc}...`);
    try {
      await page.goto(shot.url, { waitUntil: 'networkidle' });
      await page.waitForTimeout(shot.waitMs);

      const savePath = path.join(OUT_DIR, shot.filename);
      await page.screenshot({ path: savePath });

      results.push({ id: shot.id, path: `docs/screenshots/${TODAY}/sns/${shot.filename}` });
      console.log(`  ✅ ${shot.filename}`);
    } catch (err) {
      console.error(`  ❌ ${shot.id} 失敗: ${err.message}`);
      results.push({ id: shot.id, path: null });
    } finally {
      await page.close();
    }
  }

  await browser.close();

  // 結果サマリー
  const succeeded = results.filter(r => r.path).length;
  console.log(`\n✅ 完了 ${succeeded}/${SHOTS.length}件`);
  console.log(`   → docs/screenshots/${TODAY}/sns/ に保存`);

  // ファイル一覧を出力
  console.log('\n📁 ファイル一覧:');
  results.filter(r => r.path).forEach(r => console.log(`   ${r.path}`));
}

main().catch((err) => {
  console.error('エラー:', err);
  process.exit(1);
});
