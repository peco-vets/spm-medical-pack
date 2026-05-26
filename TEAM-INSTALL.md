# PECO 開発チーム向け：spm-medical-pack インストールガイド

PECO 開発メンバー向けに `spm-medical-pack` プラグインをセットアップする手順。

## 前提条件

- macOS（Linux でも可、Windows は未検証）
- Claude Code がインストール済み（[公式ガイド](https://docs.claude.com/claude-code)）
- GitHub アカウント + PECO 組織への所属（プライベートリポにアクセスするため）
- git コマンドが使える

## セットアップ手順

### 方法 A：GitHub から直接インストール（推奨）

Claude Code のチャット入力欄で以下を順に実行：

```
/plugin marketplace add https://github.com/peco-japan/spm-medical-pack
/plugin install spm-medical-pack@spm-medical-pack
/reload-plugins
```

初回は git clone するため数十秒〜数分かかる。`✓ Installed spm-medical-pack` と表示されれば完了。

### 方法 B：ローカルクローンから（GitHub 接続できない時）

```bash
# 任意の場所にクローン
git clone git@github.com:peco-japan/spm-medical-pack.git ~/spm-medical-pack

# Claude Code でインストール
# (チャット欄で実行)
/plugin marketplace add ~/spm-medical-pack
/plugin install spm-medical-pack@spm-medical-pack
/reload-plugins
```

## 動作確認

### 1. プラグイン一覧
```
/plugin list
```
→ `spm-medical-pack@spm-medical-pack v0.2.0 [active]` が表示されれば OK

### 2. SPM 医療スキルの自動起動テスト

新規セッションで以下を聞いてみる：
```
spm-diagnosis に動物のカルテ新規作成 API を設計して
```

応答に「電子保存3原則」「要配慮個人情報」「3省2GL」「獣医師法施行規則 11条」等のキーワードが出てくれば、SPM 医療スキルが自動起動している証拠。

### 3. SPM 独自スラッシュコマンド
- `/save-rule <テキスト>` — CLAUDE.md にルール即時追記
- `/distill-recent-session` — 直近セッションから LLM がルール候補抽出
- `/distill-weekly` — 過去 7 日 + 全 SPM リポを横断レビュー

## 含まれるもの

| 種別 | 数 | 中身 |
|------|---|------|
| エージェント | 60 | コードレビュー・ビルド解決・セキュリティ等（全言語、日本語化済み） |
| スキル | 235 | ECC 228 + SPM 医療 7 |
| スラッシュコマンド | 78 | ECC 75 + SPM 独自 3 |
| フック | 8 | PreToolUse + Stop hook（セッションログ蓄積） |

### SPM 医療スキル7件（このパックの核心）

| スキル | 担当論点 |
|---|---|
| `spm-3sho-2gl-check` | 厚労省・経産省・総務省 3省2ガイドライン第6.0版 |
| `spm-electronic-record-3principles` | 医療法施行規則 電子保存3原則 |
| `spm-sensitive-personal-info` | APPI 改正版 要配慮個人情報取扱フロー |
| `spm-veterinary-care-act` | 獣医療法・獣医師法 診療簿要件 |
| `spm-samd-classification` | 薬機法 SaMD 該当性判定 |
| `spm-mrna-gmp` | 薬機法 GMP + 治験法対応 |
| `spm-medical-bcp` | 医療事業継続性 BCP 設計 |

これらは「カルテ」「診療」「診断 AI」「処方」「獣医療」「医療データ」「APPI」「電子保存」等のキーワードを検出すると**自動でロード**される。

## アップデート方法

新バージョンがリリースされたら：

```
/plugin update spm-medical-pack
/reload-plugins
```

または手動で：
```bash
cd ~/.claude/plugins/cache/spm-medical-pack/spm-medical-pack/<version>/
git pull
```

最新版確認：`/plugin list` のバージョン番号、または [GitHub Releases](https://github.com/peco-japan/spm-medical-pack/releases)。

## アンインストール

```
/plugin uninstall spm-medical-pack
```

## トラブルシュート

### `/plugin install` が長時間反応しない
- Google Drive 等のクラウドドライブを経由したパスは遅い。ローカルディスクから install すること。

### `Plugin not found in any marketplace`
- スペルミス。`spm-medical-pack@spm-medical-pack`（末尾の `k` 含む）を正確に。
- Tab 補完を使うと確実。

### SPM 医療スキルが自動起動しない
- `/reload-plugins` で再ロード。
- それでも駄目なら `/skill spm-3sho-2gl-check` 等で手動起動して動作確認。
- 動作するなら description のキーワードが質問と一致していないだけ。「医療データ」「カルテ」等の明確な語を含めて再質問。

### フック競合
- ECC を別途インストールしている場合は重複ロードでエラー出る可能性。`/plugin uninstall ecc` で先に消す。

## 個人カスタマイズの扱い

- このプラグインは**全員共通**の知識ベース
- 個人ごとの好み・ルールは `~/.claude/CLAUDE.md` に書く（個人ファイル、共有不要）
- `/save-rule` で蓄積したルールも各個人の `~/.claude/CLAUDE.md` に入る

## サポート・問い合わせ

- バグ報告・機能要望: [GitHub Issues](https://github.com/peco-japan/spm-medical-pack/issues)
- 緊急時: PECO 開発チーム Slack `#claude-code`

## ライセンス・帰属

- 派生版（本プラグイン）: MIT License, Copyright (c) 2026 PECO Dev Team
- ベース: [ECC](https://github.com/affaan-m/ECC) by Affaan Mustafa (MIT)

詳細は [README.md](README.md)・[LICENSE](LICENSE)・[CHANGELOG-SPM.md](CHANGELOG-SPM.md) 参照。
