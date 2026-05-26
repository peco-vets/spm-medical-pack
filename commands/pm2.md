---
description: プロジェクトを分析し、検出されたフロントエンド、バックエンド、データベースサービス用の PM2 サービスコマンドを生成する / Analyze a project and generate PM2 service commands for detected frontend, backend, or database services.
---

# PM2 Init

プロジェクトを自動分析し、PM2 サービスコマンドを生成する。

**Command**: `$ARGUMENTS`

---

## ワークフロー

1. PM2 を確認する（不足していれば `npm install -g pm2` でインストール）
2. プロジェクトをスキャンしてサービス（frontend/backend/database）を特定する
3. config ファイルと個別のコマンドファイルを生成する

---

## サービス検出

| Type | Detection | Default Port |
|------|-----------|--------------|
| Vite | vite.config.* | 5173 |
| Next.js | next.config.* | 3000 |
| Nuxt | nuxt.config.* | 3000 |
| CRA | react-scripts in package.json | 3000 |
| Express/Node | server/backend/api directory + package.json | 3000 |
| FastAPI/Flask | requirements.txt / pyproject.toml | 8000 |
| Go | go.mod / main.go | 8080 |

**Port Detection Priority**：User specified > .env > config file > scripts args > default port

---

## 生成されるファイル

```
project/
├── ecosystem.config.cjs              # PM2 config
├── {backend}/start.cjs               # Python wrapper (if applicable)
└── .claude/
    ├── commands/
    │   ├── pm2-all.md                # Start all + monit
    │   ├── pm2-all-stop.md           # Stop all
    │   ├── pm2-all-restart.md        # Restart all
    │   ├── pm2-{port}.md             # Start single + logs
    │   ├── pm2-{port}-stop.md        # Stop single
    │   ├── pm2-{port}-restart.md     # Restart single
    │   ├── pm2-logs.md               # View all logs
    │   └── pm2-status.md             # View status
    └── scripts/
        ├── pm2-logs-{port}.ps1       # Single service logs
        └── pm2-monit.ps1             # PM2 monitor
```

---

## Windows 設定（IMPORTANT）

### ecosystem.config.cjs

**`.cjs` 拡張子を使用する必要がある**

```javascript
module.exports = {
  apps: [
    // Node.js (Vite/Next/Nuxt)
    {
      name: 'project-3000',
      cwd: './packages/web',
      script: 'node_modules/vite/bin/vite.js',
      args: '--port 3000',
      interpreter: 'C:/Program Files/nodejs/node.exe',
      env: { NODE_ENV: 'development' }
    },
    // Python
    {
      name: 'project-8000',
      cwd: './backend',
      script: 'start.cjs',
      interpreter: 'C:/Program Files/nodejs/node.exe',
      env: { PYTHONUNBUFFERED: '1' }
    }
  ]
}
```

**Framework script paths:**

| Framework | script | args |
|-----------|--------|------|
| Vite | `node_modules/vite/bin/vite.js` | `--port {port}` |
| Next.js | `node_modules/next/dist/bin/next` | `dev -p {port}` |
| Nuxt | `node_modules/nuxt/bin/nuxt.mjs` | `dev --port {port}` |
| Express | `src/index.js` or `server.js` | - |

### Python Wrapper Script (start.cjs)

```javascript
const { spawn } = require('child_process');
const proc = spawn('python', ['-m', 'uvicorn', 'app.main:app', '--host', '0.0.0.0', '--port', '8000', '--reload'], {
  cwd: __dirname, stdio: 'inherit', windowsHide: true
});
proc.on('close', (code) => process.exit(code));
```

---

## コマンドファイルテンプレート（最小内容）

各コマンドファイルは 1-2 行の説明と bash ブロックのみを含む。例：

- `pm2-all.md`：すべてのサービスを開始し PM2 monitor を開く
- `pm2-all-stop.md`：すべてのサービスを停止する
- `pm2-all-restart.md`：すべてのサービスを再起動する
- `pm2-{port}.md`：{name}（{port}）を開始しログを開く
- `pm2-{port}-stop.md`：{name}（{port}）を停止する
- `pm2-{port}-restart.md`：{name}（{port}）を再起動する
- `pm2-logs.md`：すべての PM2 ログを表示する
- `pm2-status.md`：PM2 ステータスを表示する

### PowerShell Scripts (pm2-logs-{port}.ps1)
```powershell
Set-Location "{PROJECT_ROOT}"
pm2 logs {name}
```

### PowerShell Scripts (pm2-monit.ps1)
```powershell
Set-Location "{PROJECT_ROOT}"
pm2 monit
```

---

## 主要ルール

1. **Config file**：`ecosystem.config.cjs`（.js ではない）
2. **Node.js**：bin パスを直接指定 + interpreter
3. **Python**：Node.js wrapper スクリプト + `windowsHide: true`
4. **新しいウィンドウを開く**：`start wt.exe -d "{path}" pwsh -NoExit -c "command"`
5. **最小内容**：各コマンドファイルは 1-2 行の説明 + bash ブロックのみ
6. **直接実行**：AI パース不要、bash コマンドを実行するだけ

---

## 実行

`$ARGUMENTS` に基づいて init を実行する：

1. プロジェクトをスキャンしてサービスを検出する
2. `ecosystem.config.cjs` を生成する
3. Python サービス用に `{backend}/start.cjs` を生成する（該当する場合）
4. `.claude/commands/` にコマンドファイルを生成する
5. `.claude/scripts/` にスクリプトファイルを生成する
6. **プロジェクトの CLAUDE.md** を PM2 情報で更新する（下記参照）
7. ターミナルコマンドと共に**完了サマリーを表示**する

---

## Post-Init: CLAUDE.md の更新

ファイル生成後、プロジェクトの `CLAUDE.md` に PM2 セクションを追記する（存在しない場合は作成）：

サービステーブルと一般的なターミナルコマンド（`pm2 start ecosystem.config.cjs`、`pm2 start all`、`pm2 stop all` / `pm2 restart all`、`pm2 start {name}` / `pm2 stop {name}`、`pm2 logs` / `pm2 status` / `pm2 monit`、`pm2 save`、`pm2 resurrect`）を含める。

**CLAUDE.md 更新のルール：**
- PM2 セクションが存在すれば置換する
- 存在しなければ末尾に追記する
- 内容を最小限かつ本質的なものに保つ

---

## Post-Init: サマリー表示

すべてのファイル生成後、以下を出力する：サービス一覧、Claude コマンド（/pm2-all、/pm2-all-stop、/pm2-{port}、/pm2-{port}-stop、/pm2-logs、/pm2-status）、ターミナルコマンド（初回 vs 2回目以降）。

**Tip**：簡略化されたコマンドを有効にするには、初回起動後に `pm2 save` を実行する。
