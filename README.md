# spm-medical-pack — PECO/SPM 医療開発パック

PECO/SPM 医療事業（動物病院チェーン 7院 → 8院 → 150院 → 将来ヒト医療）向けに **ECC（Everything Claude Code）を土台にカスタマイズした Claude Code 統合プラグイン**。日本の医療関連法令にネイティブ対応した SPM 専用スキルを追加し、Japan-only 運用に最適化（国際業務スキル・非日本語ドキュメントは除外済み）。

- **バージョン**: 0.2.0
- **作者**: PECO Dev Team（dev@peco-japan.com）
- **配布先**: PECO 内部（プライベート）
- **ベース**: [ECC v2.0.0-rc.1](https://github.com/affaan-m/ECC) by Affaan Mustafa（MIT）

## 同梱物の総量

| 種別 | 数 | 内訳 |
|------|---|------|
| エージェント | 60 | ECC オリジナル（全保持） |
| スキル | 235 | ECC 232 - 国際業務 4 + SPM 医療 7 |
| スラッシュコマンド | 75 | ECC オリジナル（全保持） |
| レガシーコマンドシム | 12 | ECC オリジナル |
| フック | 3カテゴリ | ECC オリジナル（PreToolUse / メモリ永続化 等） |

## SPM 医療スキル7件（このパックの目玉）

日本の医療法令に対応するため新規追加：

| スキル | 該当論点 |
|---|---|
| `spm-3sho-2gl-check` | 厚労省・経産省・総務省「3省2ガイドライン第6.0版」準拠チェック |
| `spm-electronic-record-3principles` | 医療法施行規則の電子保存3原則（真正性・見読性・保存性）|
| `spm-sensitive-personal-info` | APPI 改正版の要配慮個人情報取扱フロー |
| `spm-veterinary-care-act` | 獣医療法・獣医師法の診療簿要件 |
| `spm-samd-classification` | 薬機法「プログラム医療機器（SaMD）」該当性判定 |
| `spm-mrna-gmp` | 薬機法 GMP + 治験法対応（Layer4-5）|
| `spm-medical-bcp` | 医療事業継続性（BCP）設計 |

これらは「カルテ」「診療」「診断 AI」「処方」「獣医療」「医療データ」等のキーワード検知で**自動起動**（SKILL.md の description によるトリガ）。

## ECC からの主な変更点

### 削除したもの
- **国際業務スキル 4 件**: `visa-doc-translate`、`customs-trade-compliance`、`carrier-relationship-management`、`energy-procurement`（PECO は国内事業のため不要）
- **非日本語 README ドキュメント**: `docs/zh-CN`、`docs/tr`、`docs/ko-KR`、`docs/zh-TW`、`docs/pt-BR`、`docs/ru`、`docs/th`、`docs/vi-VN`、ルートの `README.zh-CN.md`
- **`.git`**: 上流 ECC のリポジトリ履歴は保持しない（独立プラグインとして運用）

### 追加したもの
- **SPM 医療スキル 7件**（上記）
- **本 README**（ECC オリジナル README から SPM 用にリブランド）
- **CHANGELOG-SPM.md**（派生版独自の変更履歴）

### 保持したもの
- ECC のエージェント 60 件（全言語・全領域）
- ECC のスキル 228 件（国際業務4件を引いたもの）
- ECC のスラッシュコマンド 75 件
- ECC のフック（PreToolUse・メモリ永続化等）
- ECC のドキュメント `docs/ja-JP/`、`docs/architecture/`、`docs/releases/` 等
- ECC の LICENSE（MIT、Affaan Mustafa 帰属）

> 注：日本でのみ使用するが、ECC のプログラミング言語別スキル（Rust/Kotlin/Swift/Java/Flutter 等）は**保持**。将来 SPM が新言語を採用する可能性に備える。

## インストール

```bash
# プラグインを Claude Code のマーケットプレイスに登録
/plugin marketplace add ~/.claude/plugins/marketplaces/spm-medical-pack
# プラグインインストール
/plugin install spm-medical-pack@spm-medical-pack
/reload-plugins
```

実体は Google Drive 上にあり、`~/.claude/plugins/marketplaces/spm-medical-pack` はそこへの symlink。

## アンインストール

```
/plugin uninstall spm-medical-pack
```

その後 ECC を再インストールしたい場合は：
```
/plugin install ecc@ecc
```

## ライセンス・帰属

本プラグインは ECC（MIT）の派生作品です。ECC オリジナルのライセンス・著作権表示は `LICENSE` ファイルに保持されています。

- **オリジナル**: [ECC](https://github.com/affaan-m/ECC) — Copyright (c) 2026 Affaan Mustafa（MIT）
- **派生版（本プラグイン）**: spm-medical-pack — Copyright (c) 2026 PECO Dev Team（MIT）

詳細：[LICENSE](LICENSE)、[CHANGELOG-SPM.md](CHANGELOG-SPM.md)
