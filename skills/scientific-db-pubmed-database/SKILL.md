---
name: pubmed-database
description: 生物医学文献、MeSH クエリ、PMID ルックアップ、引用取得、API 連動の文献モニタリング向け、PubMed・NCBI E-utilities の直接検索ワークフロー（PubMed and NCBI E-utilities search for biomedical literature, MeSH queries, PMID lookup, citations）。
origin: community
---

# PubMed Database

タスクに一般的な Web 検索ではなく PubMed の生物医学文献が必要な場合にこのスキルを使う。

## 使用するタイミング

- MEDLINE またはライフサイエンス文献の検索
- MeSH 用語、フィールドタグ、日付、論文タイプ付きの PubMed クエリ構築
- PMID、抄録、刊行物メタデータ、関連引用の検索
- 再現可能な検索文字列が必要な系統的レビュー検索パスの実行
- Python、シェル、または他の HTTP クライアントからの NCBI E-utilities の直接利用

## クエリ構築

リサーチクエスチョンから始め、概念に分解し、Boolean 演算子で概念を結合する。

```text
concept_1 AND concept_2 AND filter
synonym_a OR synonym_b
NOT exclusion_term
```

有用な PubMed フィールドタグ：

- `[ti]`：タイトル
- `[ab]`：抄録
- `[tiab]`：タイトルまたは抄録
- `[au]`：著者
- `[ta]`：ジャーナルタイトル略称
- `[mh]`：MeSH 用語
- `[majr]`：主要 MeSH トピック
- `[pt]`：刊行物タイプ
- `[dp]`：刊行日
- `[la]`：言語

例：

```text
diabetes mellitus[mh] AND treatment[tiab] AND systematic review[pt] AND 2023:2026[dp]
(metformin[nm] OR insulin[nm]) AND diabetes mellitus, type 2[mh] AND randomized controlled trial[pt]
smith ja[au] AND cancer[tiab] AND 2026[dp] AND english[la]
```

## MeSH とサブ見出し

概念に安定した統制語彙用語があるときは MeSH を推奨する。トピックが新しい、または用語が変動する場合は MeSH をタイトル／抄録用語と組み合わせる。

正しいサブ見出し構文ではサブ見出しをフィールドタグの前に置く：

```text
diabetes mellitus, type 2/drug therapy[mh]
cardiovascular diseases/prevention & control[mh]
```

`[majr]` はトピックが論文の中心でなければならない場合にのみ使う。精度を向上させるが、関連作業を見逃す可能性がある。

## フィルタ

刊行物タイプ：

- `clinical trial[pt]`
- `meta-analysis[pt]`
- `randomized controlled trial[pt]`
- `review[pt]`
- `systematic review[pt]`
- `guideline[pt]`

日付フィルタ：

```text
2026[dp]
2020:2026[dp]
2026/03/15[dp]
```

利用可能性フィルタ：

```text
free full text[sb]
hasabstract[text]
```

## E-utilities ワークフロー

NCBI E-utilities は再現可能な API ワークフローをサポートする：

1. `esearch.fcgi`：検索して PMID を返す。
2. `esummary.fcgi`：軽量な論文メタデータを返す。
3. `efetch.fcgi`：抄録または完全レコードを XML、MEDLINE、またはテキストで取得。
4. `elink.fcgi`：関連論文とリンクされたリソースを見つける。

本番スクリプトでは email と API key を使う。API キーは環境変数に保存し、コミットされるファイルやコマンド履歴には決して入れない。

```python
import os
import time
import requests

BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"


def esearch(query: str, retmax: int = 20) -> list[str]:
    params = {
        "db": "pubmed",
        "term": query,
        "retmode": "json",
        "retmax": retmax,
        "tool": "ecc-pubmed-search",
        "email": os.environ.get("NCBI_EMAIL", ""),
    }
    api_key = os.environ.get("NCBI_API_KEY")
    if api_key:
        params["api_key"] = api_key

    response = requests.get(f"{BASE}/esearch.fcgi", params=params, timeout=30)
    response.raise_for_status()
    time.sleep(0.35)
    return response.json()["esearchresult"]["idlist"]


pmids = esearch("hypertension[mh] AND randomized controlled trial[pt] AND 2024:2026[dp]")
print(pmids)
```

バッチには、非常に長い PMID リストを URL 経由で渡すのではなく、NCBI ヒストリサーバパラメータ（`usehistory=y`、`WebEnv`、`query_key`）を推奨する。

## 出力の規律

各検索パスで以下を記録する：

- 正確な検索文字列
- 検索したデータベース
- 検索日
- 使用したフィルタ
- 結果数
- エクスポートフォーマット
- 任意の手動除外

例：

```markdown
| Database | Date searched | Query | Filters | Results |
| --- | --- | --- | --- | ---: |
| PubMed | 2026-05-11 | `sickle cell disease[mh] AND CRISPR[tiab]` | 2020:2026[dp], English | 42 |
```

## レビューチェックリスト

- フィールドタグは有効な PubMed タグか？
- MeSH 用語は新しいトピックのフリーテキスト同義語とペアになっているか？
- 日付範囲は明示的で適切か？
- 検索ログにはクエリを再現するに十分な詳細があるか？
- API キーは環境から読み込まれているか？
- HTTP コードはパースの前に `raise_for_status()` を呼ぶか、非 200 レスポンスを処理するか？
- レート制限は守られているか？

## 参照

- [PubMed help](https://pubmed.ncbi.nlm.nih.gov/help/)
- [NCBI E-utilities documentation](https://www.ncbi.nlm.nih.gov/books/NBK25501/)
- [NCBI API key guidance](https://support.nlm.nih.gov/kbArticle/?pn=KA-05317)
- NCBI サポート：<eutilities@ncbi.nlm.nih.gov>
