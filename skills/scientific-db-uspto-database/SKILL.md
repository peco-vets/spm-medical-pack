---
name: uspto-database
description: 公式記録参照、PatentSearch クエリ、TSDR チェック、譲渡データ、再現可能な IP 調査ログ向けの USPTO 特許・商標データワークフロー（USPTO patent and trademark data workflow）。
origin: community
---

# USPTO Database

タスクに USPTO システムからの公式米国特許または商標記録が必要な場合にこのスキルを使う。

## 使用するタイミング

- 登録済み特許または出願公開の検索
- 特許出願ステータス、ファイルラッパーデータ、譲渡、または公開審査履歴のチェック
- 商標ステータス、文書、譲渡履歴の検索
- 再現可能な先行技術、ポートフォリオ、または IP ランドスケープ調査ログの構築
- USPTO 記録を Google Patents、Lens.org、Semantic Scholar、企業特許ページなどの二次ツールと比較

法的助言を提供するためにこのスキルを使わない。データ収集と記録検証のワークフローとして扱う。

## ソース選択

公式 USPTO または USPTO サポートのサーフェスを先に推奨する：

- Open Data Portal（ODP）：移行された USPTO データセットと API の現在のホーム。
- Patent File Wrapper：公開特許出願書誌データとファイルラッパー記録。
- PatentSearch API：登録済み特許および出願公開データセット用の PatentsView 検索 API。
- TSDR Data API：商標ステータスと文書取得。
- Patent and Trademark Assignment Search：所有権移転記録。
- ODP の PTAB データ：Patent Trial and Appeal Board の手続き。

二次ソースは便利なインデックスとしてのみ使う。答えが重要なときは公式記録とクロスチェックする。

## 認証とシークレット

多くの USPTO API フローは API キーを要する。キーは環境変数またはシークレットマネージャに保存し、コミットされるファイルや貼り付けられたトランスクリプトには決して入れない。

一般的な環境名：

```bash
export USPTO_API_KEY="..."
export PATENTSVIEW_API_KEY="..."
```

PatentSearch では、キーを `X-Api-Key` ヘッダで送信する。TSDR では、現在の USPTO API Manager の指示とレート制限ガイダンスに従う。

## PatentSearch ワークフロー

質問がトレンド、発明者、譲受人、分類、日付、ポートフォリオスライスに関するときに、広範な特許および出願公開検索に PatentSearch を使う。

ワークフロー：

1. 現在の PatentSearch リファレンスまたは Swagger UI からエンドポイントを特定する。
2. 明示的フィルタ付きの JSON クエリを構築する。
3. 解析に必要なフィールドのみをリクエストする。
4. 決定的にソートとページングする。
5. エンドポイント、クエリボディ、日付、データ現在性メモ、結果数を記録する。

Python リクエストスケルトン：

```python
import os
import requests

API_KEY = os.environ["PATENTSVIEW_API_KEY"]
BASE = "https://search.patentsview.org/api/v1"

payload = {
    "q": {
        "_and": [
            {"patent_date": {"_gte": "2024-01-01"}},
            {"assignees.assignee_organization": {"_text_any": ["Google", "Alphabet"]}},
        ]
    },
    "f": ["patent_id", "patent_title", "patent_date"],
    "s": [{"patent_date": "desc"}],
    "o": {"per_page": 100, "page": 1},
}

response = requests.post(
    f"{BASE}/patent/",
    headers={"X-Api-Key": API_KEY, "Content-Type": "application/json"},
    json=payload,
    timeout=30,
)
response.raise_for_status()
print(response.json())
```

クエリを再利用する前に、現在のエンドポイント名、フィールドパス、リクエストパラメータ、API キー利用可能性を、ライブ PatentSearch ドキュメントで検証する。

## 商標／TSDR ワークフロー

タスクが商標ケースステータス、文書、画像、所有者履歴、または審査イベントを要するときに TSDR を使う。

ワークフロー：

1. シリアル番号または登録番号を正規化する。
2. 現在の TSDR API 指示と必要な API キーヘッダをチェックする。
3. 先にステータスを取得し、必要な場合のみ文書を取得する。
4. PDF、ZIP、マルチケースダウンロードの低いレート制限を尊重する。
5. 出力に取得日とシリアル／登録識別子をキャプチャする。

大規模な商標プルでは、公開ページのスクリーンスクレイピングではなく、文書化されたバルクデータフローを推奨する。

## ファイルラッパーと審査履歴

出願ステータス、トランザクション履歴、審査文書には：

- ODP Patent File Wrapper 検索から始める。
- 利用可能な場合は正確な識別子を使う：出願番号、公開番号、特許番号、または当事者名。
- 記録が登録済み特許、出願公開、または係属中の出願かを記録する。
- 引用する前に、記録詳細ページに対して文書日付とステータスをクロスチェックする。

## 譲渡ワークフロー

特許または商標所有権には：

1. 利用可能な場合、特許／出願／登録番号、譲渡人、譲受人、またはリール／フレームで公式譲渡データを検索する。
2. 譲渡テキスト、執行日、記録日、当事者を記録する。
3. 譲渡記録を現在の法的所有権結論と区別する。
4. 所有権が重要な場合、結果を弁護士または専門家レビュー用にフラグする。

## 再現可能な出力

すべての USPTO 調査パスにはログテーブルを含める：

```markdown
| Source | Date searched | Identifier/query | Filters | Results | Notes |
| --- | --- | --- | --- | ---: | --- |
| PatentSearch | 2026-05-11 | `assignee=Alphabet AND date>=2024` | patent endpoint | 118 | API docs checked before run |
| TSDR | 2026-05-11 | `serial=90000000` | status only | 1 | API-key flow, no document bulk pull |
```

最終ライトアップでは、以下を分離する：

- 公式記録の事実
- 推論された解析
- 二次ソースの便利マッチ
- 未解決のギャップまたは法的レビューを要する記録

## レビューチェックリスト

- 公式 USPTO または USPTO サポートのソースを先に使用したか？
- コード実行前に現在のエンドポイントとフィールド名を検証したか？
- API キーをファイル、シェル履歴、出力ログから外しているか？
- クエリログには検索日と正確なリクエスト形状が含まれるか？
- レート制限は尊重されているか？
- 法的結論は回避されているか、または明示的にエスカレートされているか？
- 二次ソースは二次としてラベル付けされているか？

## 参照

- [USPTO APIs catalog](https://developer.uspto.gov/api-catalog)
- [USPTO Open Data Portal](https://data.uspto.gov/)
- [PatentSearch API reference](https://search.patentsview.org/docs/docs/Search%20API/SearchAPIReference/)
- [PatentSearch API updates](https://search.patentsview.org/docs/)
- [TSDR API bulk download FAQ](https://developer.uspto.gov/faq/tsdr-api-bulk-download)
