---
name: literature-review
description: 学術、生物医学、技術、科学的トピックの体系的な文献レビューワークフロー（systematic literature-review workflow: search planning, screening, synthesis, citation checks, evidence logging）。
origin: community
---

# Literature Review

タスクが学術または技術文献の体を見つけ、スクリーニングし、合成し、引用する場合にこのスキルを使う。

## 使用するタイミング

- 系統的、スコーピング、または叙述的文献レビューの構築
- 研究質問の最先端の合成
- ギャップ、矛盾、または将来の作業方向の発見
- 論文または報告書の引用裏付け背景セクションの準備
- 査読論文、プレプリント、特許、技術報告書全体でのエビデンス比較

## レビュータイプ

- **叙述的レビュー（Narrative）**：広範な合成。オリエンテーションに有用。
- **スコーピングレビュー**：概念、方法、エビデンスギャップをマップする。
- **系統的レビュー（Systematic）**：事前定義プロトコル、再現可能な検索、明示的スクリーニングと除外。
- **メタアナリシス**：系統的レビューに定量的効果集約を加えたもの。

ユーザーにどの厳密性レベルが必要か尋ねる。指定がない場合、探索的作業にはスコーピングレビュー、刊行物または臨床主張には系統的レビューをデフォルトとする。

## ワークフロー

### 1. 質問を定義する

プロンプトを検索可能なリサーチクエスチョンに変換する。

臨床または生物医学作業には PICO を使う：

- Population（対象集団）
- Intervention または曝露
- Comparator（比較対象）
- Outcome（アウトカム）

技術作業には以下を使う：

- システムまたはドメイン
- 方法または介入
- 比較ベースライン
- 評価メトリック

### 2. 検索を計画する

ソース収集前に検索プロトコルを作成する：

- 検索するデータベース
- 日付範囲
- 言語
- 刊行物タイプ
- 包含基準
- 除外基準
- 正確な検索文字列

最小有用データベースセット：

- 生物医学およびライフサイエンス文献には PubMed
- CS、数学、物理、定量生物学、プレプリントには arXiv
- 広範な学術発見には Semantic Scholar または Crossref
- 関連する場合のドメイン固有ソース：臨床試験レジストリ、特許データベース、標準化団体、公式技術ドキュメント

### 3. 検索しエビデンスを記録する

レビューを再現可能にする検索ログを維持する：

```markdown
| Database | Date searched | Query | Filters | Results | Export |
| --- | --- | --- | --- | ---: | --- |
| PubMed | 2026-05-11 | `("CRISPR"[tiab] OR "Cas9"[tiab]) AND "sickle cell"[tiab]` | 2020:2026, English | 86 | PMID list |
| arXiv | 2026-05-11 | `CRISPR sickle cell gene editing` | q-bio, 2020:2026 | 9 | BibTeX |
```

生 ID、URL、DOI、抄録、メモを最終散文とは別に保存する。

### 4. 重複排除する

この順序で重複排除する：

1. DOI
2. PMID または arXiv ID
3. 正確なタイトル
4. 正規化されたタイトル + 第一著者 + 年

削除された重複数を記録する。

### 5. ソースをスクリーニングする

ステージでスクリーニングする：

1. タイトル
2. 抄録
3. 全文

系統的作業には、除外理由を記録する：

- 対象集団が間違い
- 介入が間違い
- アウトカムが間違い
- 一次研究ではない
- 重複
- 全文利用不可
- 日付範囲外

### 6. データを抽出する

構造化抽出テーブルを使う：

```markdown
| Study | Design | Population/Data | Method | Comparator | Outcome | Key finding | Limitations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Author Year | RCT/cohort/review/etc. | sample or corpus | method | baseline | measured outcome | result | caveat |
```

技術論文には、データセット、ベンチマーク、メトリック、ベースライン、再現性メモを含める。

### 7. 合成する

論文を 1 つずつ要約するのではなく、テーマで証拠をグループ化する。

有用な合成レンズ：

- 最も強いエビデンス
- 矛盾するエビデンス
- 方法論的弱点
- 集団またはデータセットの限界
- 最新性と複製
- 実用的含意
- 未回答の質問

主張を信頼度で分離する：

- **高信頼度**：複製された、ソース全体での高品質エビデンス
- **中信頼度**：もっともらしいがサンプル、方法、または最新性で限定的
- **低信頼度**：早期、推測的、単一ソース、または弱く測定された

### 8. 引用を検証する

最終化前に：

- DOI、PMID、arXiv ID、または公式 URL を検証する
- 著者名と刊行年をチェックする
- 論文をそれが述べない主張で引用しない
- プレプリントをプレプリントとしてマークする
- レビューを一次エビデンスと区別する

## 出力テンプレート

```markdown
# Literature Review: <Topic>

Generated: <date>
Review type: <narrative | scoping | systematic | meta-analysis>
Search window: <dates>
Databases: <list>

## Research Question

## Search Strategy

## Inclusion and Exclusion Criteria

## Evidence Summary

## Thematic Synthesis

## Gaps and Limitations

## References

## Search Log
```

## 落とし穴

- 検索スニペットをエビデンスとして扱わない
- プレプリント、レビュー、一次研究をラベル付けせずに混ぜない
- 否定的または矛盾する所見を省略しない
- 再現可能なプロトコルなしに系統的レビューの厳密性を主張しない
- スコープがそのデータベースに明示的に限定されない限り、広範な主張に単一データベースを使わない
