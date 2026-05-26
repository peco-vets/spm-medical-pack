---
name: ui-demo
description: Playwright を使った磨かれた UI デモビデオの録画（record polished UI demo videos using Playwright）。ユーザーが Web アプリケーションのデモ、ウォークスルー、画面録画、またはチュートリアルビデオを作成するよう依頼したときに使用する。可視カーソル、自然なペース、プロフェッショナルな感覚を持つ WebM ビデオを生成する。
origin: ECC
---

# UI デモビデオレコーダ

注入されたカーソルオーバーレイ、自然なペース、ストーリーテリングフロー付きで Playwright のビデオ録画を使って Web アプリケーションの磨かれたデモビデオを録画する。

## 使用するタイミング

- ユーザーが「demo video」「screen recording」「walkthrough」「tutorial」を依頼
- ユーザーが機能やワークフローを視覚的に示したい
- ドキュメント、オンボーディング、ステークホルダープレゼン用のビデオが必要

## 3 フェーズプロセス

すべてのデモは 3 フェーズを通過する：**Discover → Rehearse → Record**。録画に直接スキップしない。

---

## フェーズ 1：Discover

スクリプトを書く前に、ターゲットページを探索して実際に何があるかを理解する。

### なぜ

見ていないものはスクリプトできない。フィールドが `<textarea>` ではなく `<input>` かもしれない、ドロップダウンが `<select>` ではなくカスタムコンポーネントかもしれない、コメントボックスが `@mentions` や `#tags` をサポートしているかもしれない。仮定は録画をサイレントに壊す。

### どうやって

フローの各ページにナビゲートし、そのインタラクティブ要素をダンプする：

```javascript
// Run this for each page in the flow BEFORE writing the demo script
const fields = await page.evaluate(() => {
  const els = [];
  document.querySelectorAll('input, select, textarea, button, [contenteditable]').forEach(el => {
    if (el.offsetParent !== null) {
      els.push({
        tag: el.tagName,
        type: el.type || '',
        name: el.name || '',
        placeholder: el.placeholder || '',
        text: el.textContent?.trim().substring(0, 40) || '',
        contentEditable: el.contentEditable === 'true',
        role: el.getAttribute('role') || '',
      });
    }
  });
  return els;
});
console.log(JSON.stringify(fields, null, 2));
```

### 何を探すか

- **フォームフィールド**：`<select>`、`<input>`、カスタムドロップダウン、または combobox か？
- **Select オプション**：オプション値とテキストの両方をダンプ。プレースホルダはしばしば `value="0"` や `value=""` で、非空に見える。`Array.from(el.options).map(o => ({ value: o.value, text: o.text }))` を使う。テキストに「Select」を含むか値が `"0"` のオプションをスキップ。
- **リッチテキスト**：コメントボックスは `@mentions`、`#tags`、markdown、絵文字をサポートするか？プレースホルダテキストをチェック。
- **必須フィールド**：どのフィールドがフォーム送信をブロックするか？`required`、ラベル内の `*` をチェックし、空で送信を試して検証エラーを見る。
- **動的コンテンツ**：他のフィールド入力後にフィールドが現れるか？
- **ボタンラベル**：`"Submit"`、`"Submit Request"`、`"Send"` などの正確なテキスト。
- **テーブル列ヘッダ**：テーブル駆動モーダルには、すべての数値入力が同じことを意味すると仮定するのではなく、各 `input[type="number"]` をその列ヘッダにマップする。

### 出力

各ページのフィールドマップ。スクリプトで正しいセレクタを書くために使う。例：

```text
/purchase-requests/new:
  - Budget Code: <select> (first select on page, 4 options)
  - Desired Delivery: <input type="date">
  - Context: <textarea> (not input)
  - BOM table: inline-editable cells with span.cursor-pointer -> input pattern
  - Submit: <button> text="Submit"

/purchase-requests/N (detail):
  - Comment: <input placeholder="Type a message..."> supports @user and #PR tags
  - Send: <button> text="Send" (disabled until input has content)
```

---

## フェーズ 2：Rehearse

録画せずにすべてのステップを実行する。すべてのセレクタが解決することを検証する。

### なぜ

サイレントなセレクタ失敗がデモ録画が壊れる主な理由。リハーサルは録画を無駄にする前にそれらを捕捉する。

### どうやって

`ensureVisible` ラッパーを使う。これはログを取り、大声で失敗する：

```javascript
async function ensureVisible(page, locator, label) {
  const el = typeof locator === 'string' ? page.locator(locator).first() : locator;
  const visible = await el.isVisible().catch(() => false);
  if (!visible) {
    const msg = `REHEARSAL FAIL: "${label}" not found - selector: ${typeof locator === 'string' ? locator : '(locator object)'}`;
    console.error(msg);
    const found = await page.evaluate(() => {
      return Array.from(document.querySelectorAll('button, input, select, textarea, a'))
        .filter(el => el.offsetParent !== null)
        .map(el => `${el.tagName}[${el.type || ''}] "${el.textContent?.trim().substring(0, 30)}"`)
        .join('\n  ');
    });
    console.error('  Visible elements:\n  ' + found);
    return false;
  }
  console.log(`REHEARSAL OK: "${label}"`);
  return true;
}
```

### リハーサルスクリプト構造

```javascript
const steps = [
  { label: 'Login email field', selector: '#email' },
  { label: 'Login submit', selector: 'button[type="submit"]' },
  { label: 'New Request button', selector: 'button:has-text("New Request")' },
  { label: 'Budget Code select', selector: 'select' },
  { label: 'Delivery date', selector: 'input[type="date"]:visible' },
  { label: 'Description field', selector: 'textarea:visible' },
  { label: 'Add Item button', selector: 'button:has-text("Add Item")' },
  { label: 'Submit button', selector: 'button:has-text("Submit")' },
];

let allOk = true;
for (const step of steps) {
  if (!await ensureVisible(page, step.selector, step.label)) {
    allOk = false;
  }
}
if (!allOk) {
  console.error('REHEARSAL FAILED - fix selectors before recording');
  process.exit(1);
}
console.log('REHEARSAL PASSED - all selectors verified');
```

### リハーサルが失敗したとき

1. 可視要素ダンプを読む。
2. 正しいセレクタを見つける。
3. スクリプトを更新する。
4. リハーサルを再実行する。
5. すべてのセレクタが通過したときのみ進める。

---

## フェーズ 3：Record

Discovery と Rehearsal が通過した後にのみ録画を作成すべき。

### 録画原則

#### 1. ストーリーテリングフロー

ビデオをストーリーとして計画する。ユーザー指定の順序に従うか、このデフォルトを使う：

- **Entry**：ログインまたは開始ポイントへナビゲート
- **Context**：視聴者が方向感覚を得るために周囲をパン
- **Action**：メインワークフローステップを実行
- **Variation**：設定、テーマ、ローカライゼーションなど二次機能を示す
- **Result**：結果、確認、または新しい状態を示す

#### 2. ペーシング

- ログイン後：`4s`
- ナビゲーション後：`3s`
- ボタンクリック後：`2s`
- 主要ステップ間：`1.5-2s`
- 最終アクション後：`3s`
- タイピング遅延：文字あたり `25-40ms`

#### 3. カーソルオーバーレイ

マウス動作に従う SVG 矢印カーソルを注入する：

```javascript
async function injectCursor(page) {
  await page.evaluate(() => {
    if (document.getElementById('demo-cursor')) return;
    const cursor = document.createElement('div');
    cursor.id = 'demo-cursor';
    cursor.innerHTML = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M5 3L19 12L12 13L9 20L5 3Z" fill="white" stroke="black" stroke-width="1.5" stroke-linejoin="round"/>
    </svg>`;
    cursor.style.cssText = `
      position: fixed; z-index: 999999; pointer-events: none;
      width: 24px; height: 24px;
      transition: left 0.1s, top 0.1s;
      filter: drop-shadow(1px 1px 2px rgba(0,0,0,0.3));
    `;
    cursor.style.left = '0px';
    cursor.style.top = '0px';
    document.body.appendChild(cursor);
    document.addEventListener('mousemove', (e) => {
      cursor.style.left = e.clientX + 'px';
      cursor.style.top = e.clientY + 'px';
    });
  });
}
```

オーバーレイはナビゲートで破壊されるため、各ページナビゲーション後に `injectCursor(page)` を呼ぶ。

#### 4. マウス動作

カーソルを決してテレポートしない。クリック前にターゲットに移動する：

```javascript
async function moveAndClick(page, locator, label, opts = {}) {
  const { postClickDelay = 800, ...clickOpts } = opts;
  const el = typeof locator === 'string' ? page.locator(locator).first() : locator;
  const visible = await el.isVisible().catch(() => false);
  if (!visible) {
    console.error(`WARNING: moveAndClick skipped - "${label}" not visible`);
    return false;
  }
  try {
    await el.scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);
    const box = await el.boundingBox();
    if (box) {
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, { steps: 10 });
      await page.waitForTimeout(400);
    }
    await el.click(clickOpts);
  } catch (e) {
    console.error(`WARNING: moveAndClick failed on "${label}": ${e.message}`);
    return false;
  }
  await page.waitForTimeout(postClickDelay);
  return true;
}
```

すべての呼び出しはデバッグ用に記述的な `label` を含めるべき。

#### 5. タイピング

インスタント充填ではなく、可視にタイプする：

```javascript
async function typeSlowly(page, locator, text, label, charDelay = 35) {
  const el = typeof locator === 'string' ? page.locator(locator).first() : locator;
  const visible = await el.isVisible().catch(() => false);
  if (!visible) {
    console.error(`WARNING: typeSlowly skipped - "${label}" not visible`);
    return false;
  }
  await moveAndClick(page, el, label);
  await el.fill('');
  await el.pressSequentially(text, { delay: charDelay });
  await page.waitForTimeout(500);
  return true;
}
```

#### 6. スクロール

ジャンプではなくスムーススクロールを使う：

```javascript
await page.evaluate(() => window.scrollTo({ top: 400, behavior: 'smooth' }));
await page.waitForTimeout(1500);
```

#### 7. ダッシュボードパン

ダッシュボードまたは概要ページを表示するとき、キー要素間でカーソルを移動する：

```javascript
async function panElements(page, selector, maxCount = 6) {
  const elements = await page.locator(selector).all();
  for (let i = 0; i < Math.min(elements.length, maxCount); i++) {
    try {
      const box = await elements[i].boundingBox();
      if (box && box.y < 700) {
        await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, { steps: 8 });
        await page.waitForTimeout(600);
      }
    } catch (e) {
      console.warn(`WARNING: panElements skipped element ${i} (selector: "${selector}"): ${e.message}`);
    }
  }
}
```

#### 8. 字幕

ビューポートの下部に字幕バーを注入：

```javascript
async function injectSubtitleBar(page) {
  await page.evaluate(() => {
    if (document.getElementById('demo-subtitle')) return;
    const bar = document.createElement('div');
    bar.id = 'demo-subtitle';
    bar.style.cssText = `
      position: fixed; bottom: 0; left: 0; right: 0; z-index: 999998;
      text-align: center; padding: 12px 24px;
      background: rgba(0, 0, 0, 0.75);
      color: white; font-family: -apple-system, "Segoe UI", sans-serif;
      font-size: 16px; font-weight: 500; letter-spacing: 0.3px;
      transition: opacity 0.3s;
      pointer-events: none;
    `;
    bar.textContent = '';
    bar.style.opacity = '0';
    document.body.appendChild(bar);
  });
}

async function showSubtitle(page, text) {
  await page.evaluate((t) => {
    const bar = document.getElementById('demo-subtitle');
    if (!bar) return;
    if (t) {
      bar.textContent = t;
      bar.style.opacity = '1';
    } else {
      bar.style.opacity = '0';
    }
  }, text);
  if (text) await page.waitForTimeout(800);
}
```

各ナビゲーション後に `injectCursor(page)` と並んで `injectSubtitleBar(page)` を呼ぶ。

使用パターン：

```javascript
await showSubtitle(page, 'Step 1 - Logging in');
await showSubtitle(page, 'Step 2 - Dashboard overview');
await showSubtitle(page, '');
```

ガイドライン：

- 字幕テキストを短く、理想的には 60 文字未満に保つ。
- 一貫性のため `Step N - Action` フォーマットを使う。
- UI が自分で語れる長い一時停止中は字幕をクリア。

## スクリプトテンプレート

```javascript
'use strict';
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE_URL = process.env.QA_BASE_URL || 'http://localhost:3000';
const VIDEO_DIR = path.join(__dirname, 'screenshots');
const OUTPUT_NAME = 'demo-FEATURE.webm';
const REHEARSAL = process.argv.includes('--rehearse');

// Paste injectCursor, injectSubtitleBar, showSubtitle, moveAndClick,
// typeSlowly, ensureVisible, and panElements here.

(async () => {
  const browser = await chromium.launch({ headless: true });

  if (REHEARSAL) {
    const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    const page = await context.newPage();
    // Navigate through the flow and run ensureVisible for each selector.
    await browser.close();
    return;
  }

  const context = await browser.newContext({
    recordVideo: { dir: VIDEO_DIR, size: { width: 1280, height: 720 } },
    viewport: { width: 1280, height: 720 }
  });
  const page = await context.newPage();

  try {
    await injectCursor(page);
    await injectSubtitleBar(page);

    await showSubtitle(page, 'Step 1 - Logging in');
    // login actions

    await page.goto(`${BASE_URL}/dashboard`);
    await injectCursor(page);
    await injectSubtitleBar(page);
    await showSubtitle(page, 'Step 2 - Dashboard overview');
    // pan dashboard

    await showSubtitle(page, 'Step 3 - Main workflow');
    // action sequence

    await showSubtitle(page, 'Step 4 - Result');
    // final reveal
    await showSubtitle(page, '');
  } catch (err) {
    console.error('DEMO ERROR:', err.message);
  } finally {
    await context.close();
    const video = page.video();
    if (video) {
      const src = await video.path();
      const dest = path.join(VIDEO_DIR, OUTPUT_NAME);
      try {
        fs.copyFileSync(src, dest);
        console.log('Video saved:', dest);
      } catch (e) {
        console.error('ERROR: Failed to copy video:', e.message);
        console.error('  Source:', src);
        console.error('  Destination:', dest);
      }
    }
    await browser.close();
  }
})();
```

使用法：

```bash
# Phase 2: Rehearse
node demo-script.cjs --rehearse

# Phase 3: Record
node demo-script.cjs
```

## 録画前のチェックリスト

- [ ] Discovery フェーズ完了
- [ ] Rehearsal がすべてのセレクタ OK で通過
- [ ] ヘッドレスモード有効
- [ ] 解像度を `1280x720` に設定
- [ ] 各ナビゲーション後にカーソルと字幕オーバーレイを再注入
- [ ] 主要遷移で `showSubtitle(page, 'Step N - ...')` を使用
- [ ] すべてのクリックに記述的ラベル付きで `moveAndClick` を使用
- [ ] 可視入力に `typeSlowly` を使用
- [ ] サイレントキャッチなし、ヘルパーは警告をログ
- [ ] コンテンツ表示にスムーズスクロールを使用
- [ ] キー一時停止が人間視聴者に可視
- [ ] フローが要求されたストーリー順序にマッチ
- [ ] スクリプトがフェーズ 1 で発見された実際の UI を反映

## よくある落とし穴

1. ナビゲーション後にカーソルが消える - 再注入する。
2. ビデオが速すぎる - ポーズを追加。
3. カーソルが矢印ではなく点 - SVG オーバーレイを使う。
4. カーソルがテレポート - クリック前に移動。
5. Select ドロップダウンが間違って見える - 移動を見せ、次にオプションを選ぶ。
6. モーダルが突然 - 確認前に読みポーズを追加。
7. ビデオファイルパスがランダム - 安定した出力名にコピー。
8. セレクタ失敗が飲み込まれる - サイレント catch ブロックを決して使わない。
9. フィールドタイプが仮定された - 先に発見する。
10. 機能が仮定された - スクリプティング前に実際の UI を検査する。
11. プレースホルダ select 値が本物に見える - `"0"` と `"Select..."` に注意。
12. ポップアップが別個のビデオを作成 - ポップアップページを明示的にキャプチャし、必要に応じて後でマージ。
