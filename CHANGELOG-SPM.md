# spm-medical-pack 変更履歴

> ECC オリジナルの `CHANGELOG.md` は ECC 本家の変更履歴。本ファイル `CHANGELOG-SPM.md` は spm-medical-pack 派生版独自の変更履歴。

## [0.2.0] - 2026-05-25

### 全 410 ファイル日本語化完了 + CLAUDE.md 自動アップデート 3 層フロー追加

#### 追加（Added）
- **CLAUDE.md 自動アップデート 3層フロー** を統合：
  - Layer C: `commands/save-rule.md` — 手動ルールキャプチャコマンド
  - Layer B: `scripts/hooks/spm/session-log.sh` + `hooks/hooks.json` に `spm:session:log` 登録
  - Layer B-bridge: `commands/distill-recent-session.md` — セッションログから LLM 抽出
  - Layer D: `commands/distill-weekly.md` — 週次バッチ横断レビュー
  - `docs/RULE-AUTOMATION.md` — 開発者向け詳細仕様

#### 変更（Changed）
- **全 410 ファイル日本語化完了**（8並列サブエージェント実行）：
  - エージェント 60 件（agents/）
  - スキル 228 件（skills/、SPM 7件は元から日本語）
  - スラッシュコマンド 75 件（commands/）
  - ドキュメント・ルート Markdown 47 件（docs/、ルート MD）
- 各ファイル：
  - frontmatter の `name:` は英語維持（プラグインロード ID のため）
  - `description:` は「日本語訳 + 英語キーワード併記」のハイブリッド形式（自動起動トリガを両言語対応）
  - コードブロック・ファイルパス・URL・ライセンス表記は原文保持
  - 本体散文は「である」調で統一

#### 注意点
- `windows-desktop-e2e/SKILL.md` の後半は要約形式（900行超のため、コードサンプル・セクション構造は保持）

## [0.1.0] - 2026-05-25

### 初版リリース — ECC v2.0.0-rc.1 ベースの SPM 医療事業向けフォーク

#### 追加（Added）
- **SPM 医療スキル 7件** を `skills/` 配下に統合：
  - `spm-3sho-2gl-check` — 厚労省・経産省・総務省 3省2ガイドライン第6.0版
  - `spm-electronic-record-3principles` — 医療法施行規則 電子保存3原則
  - `spm-sensitive-personal-info` — APPI 要配慮個人情報取扱フロー
  - `spm-veterinary-care-act` — 獣医療法・獣医師法 診療簿要件
  - `spm-samd-classification` — 薬機法 SaMD 該当性判定
  - `spm-mrna-gmp` — 薬機法 GMP + 治験法対応
  - `spm-medical-bcp` — 医療事業継続性 BCP 設計
- `README.md` を SPM 用に書き換え（オリジナルは `README.md` を退避せず置換）
- `CHANGELOG-SPM.md`（本ファイル）新規作成
- `.claude-plugin/plugin.json`、`.claude-plugin/marketplace.json` を spm-medical-pack 用に書き換え

#### 削除（Removed）
- **国際業務スキル 4件**（Japan-only 運用のため）：
  - `skills/visa-doc-translate/`
  - `skills/customs-trade-compliance/`
  - `skills/carrier-relationship-management/`
  - `skills/energy-procurement/`
- **非日本語 docs 8件**（日本語 + 英語のみ残す）：
  - `docs/zh-CN/`、`docs/zh-TW/`、`docs/ko-KR/`、`docs/tr/`、`docs/pt-BR/`、`docs/ru/`、`docs/th/`、`docs/vi-VN/`
  - ルートの `README.zh-CN.md`
- `.git/`（上流リポジトリ履歴、独立プラグインとして運用するため）

#### 保持（Kept）
- ECC オリジナルのエージェント 60件（全言語・全領域、将来の言語追加に備える）
- ECC オリジナルのスキル 228件（国際業務4件を除いた全件）
- ECC オリジナルのスラッシュコマンド 75件、レガシーシム 12件、フック
- `docs/ja-JP/`、`docs/architecture/`、`docs/releases/` 等の有用ドキュメント
- ECC オリジナル `LICENSE`（MIT、Affaan Mustafa 著作権）

#### 構成
- Claude Code 参照パス: `~/.claude/plugins/marketplaces/spm-medical-pack`（`/plugin install` で自動配置）
