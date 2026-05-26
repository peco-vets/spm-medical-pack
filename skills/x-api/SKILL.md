---
name: x-api
description: ツイート投稿、スレッド、タイムライン読取、検索、アナリティクスのための X/Twitter API 統合（X/Twitter API integration for posting tweets, threads, timelines, search, analytics）。OAuth 認証パターン、レート制限、プラットフォームネイティブコンテンツ投稿をカバー。ユーザーが X とプログラム的に対話したいときに使用する。
origin: ECC
---

# X API

> **ドリフトしやすいスキル。** X API エンドポイント、アクセスティア、クォータ、書込権限は頻繁に変わる。レート制限を引用したり投稿／検索フローを実装する前に、現在の開発者ドキュメントとアカウントアクセスを検証する。

X（Twitter）との投稿、読み取り、検索、アナリティクスのためのプログラム的対話。

## 起動するタイミング

- ユーザーがプログラム的にツイートまたはスレッドを投稿したい
- X からタイムライン、メンション、ユーザーデータを読み取り
- コンテンツ、トレンド、会話のために X を検索
- X 統合またはボットを構築
- アナリティクスとエンゲージメント追跡
- ユーザーが「X に投稿」「ツイート」「X API」「Twitter API」と言う

## 認証

### OAuth 2.0 Bearer Token（App-Only）

最適：読み取り重視の操作、検索、パブリックデータ。

```bash
# Environment setup
export X_BEARER_TOKEN="your-bearer-token"
```

```python
import os
import requests

bearer = os.environ["X_BEARER_TOKEN"]
headers = {"Authorization": f"Bearer {bearer}"}

# Search recent tweets
resp = requests.get(
    "https://api.x.com/2/tweets/search/recent",
    headers=headers,
    params={"query": "claude code", "max_results": 10}
)
tweets = resp.json()
```

### OAuth 1.0a（ユーザーコンテキスト）

必要：ツイート投稿、アカウント管理、DM、任意の書込フロー。

```bash
# Environment setup — source before use
export X_CONSUMER_KEY="your-consumer-key"
export X_CONSUMER_SECRET="your-consumer-secret"
export X_ACCESS_TOKEN="your-access-token"
export X_ACCESS_TOKEN_SECRET="your-access-token-secret"
```

`X_API_KEY`、`X_API_SECRET`、`X_ACCESS_SECRET` などのレガシーエイリアスは古いセットアップに存在することがある。新しいフローを文書化または配線するときは `X_CONSUMER_*` と `X_ACCESS_TOKEN_SECRET` 名を推奨。

```python
import os
from requests_oauthlib import OAuth1Session

oauth = OAuth1Session(
    os.environ["X_CONSUMER_KEY"],
    client_secret=os.environ["X_CONSUMER_SECRET"],
    resource_owner_key=os.environ["X_ACCESS_TOKEN"],
    resource_owner_secret=os.environ["X_ACCESS_TOKEN_SECRET"],
)
```

## コア操作

### ツイートを投稿

```python
resp = oauth.post(
    "https://api.x.com/2/tweets",
    json={"text": "Hello from Claude Code"}
)
resp.raise_for_status()
tweet_id = resp.json()["data"]["id"]
```

### スレッドを投稿

```python
def post_thread(oauth, tweets: list[str]) -> list[str]:
    ids = []
    reply_to = None
    for text in tweets:
        payload = {"text": text}
        if reply_to:
            payload["reply"] = {"in_reply_to_tweet_id": reply_to}
        resp = oauth.post("https://api.x.com/2/tweets", json=payload)
        tweet_id = resp.json()["data"]["id"]
        ids.append(tweet_id)
        reply_to = tweet_id
    return ids
```

### ユーザータイムラインを読む

```python
resp = requests.get(
    f"https://api.x.com/2/users/{user_id}/tweets",
    headers=headers,
    params={
        "max_results": 10,
        "tweet.fields": "created_at,public_metrics",
    }
)
```

### ツイートを検索

```python
resp = requests.get(
    "https://api.x.com/2/tweets/search/recent",
    headers=headers,
    params={
        "query": "from:affaanmustafa -is:retweet",
        "max_results": 10,
        "tweet.fields": "public_metrics,created_at",
    }
)
```

### ボイスモデリング用に最近のオリジナル投稿を取得

```python
resp = requests.get(
    "https://api.x.com/2/tweets/search/recent",
    headers=headers,
    params={
        "query": "from:affaanmustafa -is:retweet -is:reply",
        "max_results": 25,
        "tweet.fields": "created_at,public_metrics",
    }
)
voice_samples = resp.json()
```

### ユーザー名でユーザーを取得

```python
resp = requests.get(
    "https://api.x.com/2/users/by/username/affaanmustafa",
    headers=headers,
    params={"user.fields": "public_metrics,description,created_at"}
)
```

### メディアをアップロードして投稿

```python
# Media upload uses v1.1 endpoint

# Step 1: Upload media
media_resp = oauth.post(
    "https://upload.twitter.com/1.1/media/upload.json",
    files={"media": open("image.png", "rb")}
)
media_id = media_resp.json()["media_id_string"]

# Step 2: Post with media
resp = oauth.post(
    "https://api.x.com/2/tweets",
    json={"text": "Check this out", "media": {"media_ids": [media_id]}}
)
```

## レート制限

X API レート制限はエンドポイント、認証方法、アカウントティアで変動し、時間とともに変わる。常に：
- 仮定をハードコードする前に現在の X 開発者ドキュメントをチェック
- ランタイムで `x-rate-limit-remaining` と `x-rate-limit-reset` ヘッダを読む
- コード内の静的テーブルに依存せず自動的にバックオフ

```python
import time

remaining = int(resp.headers.get("x-rate-limit-remaining", 0))
if remaining < 5:
    reset = int(resp.headers.get("x-rate-limit-reset", 0))
    wait = max(0, reset - int(time.time()))
    print(f"Rate limit approaching. Resets in {wait}s")
```

## エラー処理

```python
resp = oauth.post("https://api.x.com/2/tweets", json={"text": content})
if resp.status_code == 201:
    return resp.json()["data"]["id"]
elif resp.status_code == 429:
    reset = int(resp.headers["x-rate-limit-reset"])
    raise Exception(f"Rate limited. Resets at {reset}")
elif resp.status_code == 403:
    raise Exception(f"Forbidden: {resp.json().get('detail', 'check permissions')}")
else:
    raise Exception(f"X API error {resp.status_code}: {resp.text}")
```

## セキュリティ

- **トークンを決してハードコードしない。** 環境変数または `.env` ファイルを使う。
- **`.env` ファイルを決してコミットしない。** `.gitignore` に追加。
- 公開されたら**トークンをローテーション**。developer.x.com で再生成。
- 書込アクセスが不要なときは**読み取り専用トークンを使う**。
- **OAuth シークレットを安全に保存** — ソースコードやログに入れない。

## Content Engine との統合

`brand-voice` と `content-engine` を使ってプラットフォームネイティブコンテンツを生成し、X API 経由で投稿する：
1. ボイスマッチングが重要なら最近のオリジナル投稿を取得
2. `VOICE PROFILE` を構築または再利用
3. X ネイティブフォーマットで `content-engine` でコンテンツを生成
4. 長さとスレッド構造を検証
5. ユーザーが今投稿するよう明示的に求めない限り、ドラフトを承認のために返す
6. 承認後にのみ X API で投稿
7. public_metrics 経由でエンゲージメントを追跡

## 関連スキル

- `brand-voice` — 実 X とサイト／ソース資料から再利用可能なボイスプロファイルを構築
- `content-engine` — X 用にプラットフォームネイティブコンテンツを生成
- `crosspost` — X、LinkedIn、他プラットフォーム全体でコンテンツを配信
- `connections-optimizer` — ネットワーク駆動アウトリーチを起草する前に X グラフを再編成
