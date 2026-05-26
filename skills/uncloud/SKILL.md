---
name: uncloud
description: Uncloud クラスタを管理するときに使用する（managing Uncloud cluster — deploying services, Caddy ingress, static proxy routes, ports, scaling, logs, machines, volumes with the `uc` CLI）。サービスのデプロイ、Caddy イングレスの設定、非クラスタデバイスへの静的プロキシルート追加、ポート公開、スケーリング、ログ検査、または `uc` CLI でのマシンとボリューム管理。
origin: ECC
---

# Uncloud クラスタ管理

`uc` CLI のリファレンス — Docker コンテナ、WireGuard メッシュネットワーキング、Caddy リバースプロキシを使用する分散自己ホスティングプラットフォーム。

## 起動するタイミング

Uncloud クラスタで作業するとき、特に：
- `uc machine` でマシンをブートストラップまたは参加
- `uc deploy` で Compose ファイルからサービスをデプロイ
- Uncloud 経由で HTTP、HTTPS、TCP、または UDP ポートを公開
- `x-caddy`、`x-ports`、または `--caddyfile` で Caddy イングレスを設定
- 外部 LAN デバイスをクラスタプロキシ経由でルーティング
- ログ、サービス状態、ボリューム、DNS、またはマシン配置を検査

## 動作の仕組み

Uncloud は WireGuard メッシュで接続されたピアマシン全体で Docker サービスを実行する。各マシンは同等のクラスタメンバ。サービスはオーバーレイネットワークで通信し、Caddy はパブリック HTTP/HTTPS トラフィックを終端するためにグローバルに実行される。Compose ファイルはイングレス、配置、生成された Caddy 設定に Uncloud 拡張を使える。`uc` CLI はイメージ配布、スケジューリング、スケーリング、ログ、クラスタ状態を処理する。

## 例

```bash
uc machine init user@host --name machine-1
uc service run --name web -p app.example.com:8080/https nginx:latest
uc deploy
```

## コアコンセプト

- **集中型コントロールプレーンなし** — すべてのマシンが WireGuard で接続された同等のピア
- **Caddy** はすべてのマシンでグローバルサービスとして実行、Let's Encrypt から TLS を自動取得
- **オーバーレイネットワーク** — サービスはデフォルトで `10.210.0.0/16` 経由で通信、DNS はメッシュ内で提供
- **Caddyfile は自動生成** — 直接編集しない。代わりに `x-caddy` / `--caddyfile` を使う

---

## CLI クイックリファレンス

### マシン

| コマンド | 目的 |
|---------|---------|
| `uc machine init user@host` | 最初のマシン／新クラスタをブートストラップ |
| `uc machine add user@host` | 既存クラスタにマシンを参加 |
| `uc machine ls` | マシンをリスト |
| `uc machine update NAME --public-ip IP` | イングレスのパブリック IP を更新 |
| `uc machine rm NAME` | マシンを削除 |

主要 `init` フラグ：`--name`、`--network 10.210.0.0/16`、`--no-caddy`、`--no-dns`、`--public-ip auto\|IP\|none`

### サービス

| コマンド | 目的 |
|---------|---------|
| `uc service ls` / `uc ls` | サービスをリスト |
| `uc service run IMAGE` | 単一コンテナサービスを実行 |
| `uc deploy` | `compose.yaml` からデプロイ |
| `uc deploy --no-build` | 再ビルドせずプッシュ済みイメージをデプロイ |
| `uc deploy --recreate` | サービス再作成を強制 |
| `uc scale SERVICE N` | レプリカ数を設定 |
| `uc service logs SERVICE` | ログを表示 |
| `uc service exec SERVICE` | コンテナにシェルイン |
| `uc service inspect SERVICE` | 詳細情報 |
| `uc service rm SERVICE` | サービスを削除（named volume は保持） |
| `uc ps` | クラスタ全体のすべてのコンテナ |

### イメージ

```bash
uc image push myapp:latest                    # Push local image to all machines
uc image push myapp:latest -m machine1,machine2  # Push to specific machines
uc images                                     # List images in cluster
```

### ボリューム

```bash
uc volume ls                  # All volumes
uc volume ls -m machine1      # On specific machine
uc volume create NAME -m MACHINE
uc volume rm NAME
```

### Caddy

```bash
uc caddy config    # Show current generated Caddyfile (read-only)
uc caddy deploy    # Deploy/upgrade Caddy across cluster
```

### DNS とコンテキスト

```bash
uc dns show        # Show reserved *.uncld.dev domain
uc dns reserve     # Reserve a new domain
uc ctx ls          # List cluster contexts
uc ctx use prod    # Switch context
```

---

## ポート公開

### HTTP/HTTPS（Caddy リバースプロキシ経由）

```
-p [hostname:]container_port[/protocol]
```

| 例 | 意味 |
|---------|---------|
| `-p 8080/https` | 自動 `service-name.cluster-domain` ホスト名で HTTPS |
| `-p app.example.com:8080/https` | カスタムホスト名で HTTPS |
| `-p 8080/http` | HTTP のみ、TLS なし |

### TCP/UDP（ホストバウンド、Caddy バイパス）

```
-p [host_ip:]host_port:container_port[/protocol]@host
```

| 例 | 意味 |
|---------|---------|
| `-p 5432:5432@host` | すべてのインターフェースで TCP 5432 |
| `-p 127.0.0.1:5432:5432@host` | ループバックのみで TCP 5432 |
| `-p 53:5353/udp@host` | UDP |

---

## Compose ファイル拡張

Uncloud は Docker Compose の上にこれらの拡張を追加する：

### `x-ports` — ドメイン付きでポートを公開

```yaml
services:
  app:
    image: app:latest
    x-ports:
      - example.com:8000/https
      - www.example.com:8000/https
      - api.example.com:9000/https
```

### `x-caddy` — サービスのカスタム Caddy 設定

```yaml
services:
  app:
    image: app:latest
    x-caddy: |
      example.com {
        redir https://www.example.com{uri} permanent
      }
      www.example.com {
        reverse_proxy {{upstreams 8000}} {
          import common_proxy
        }
        basic_auth /admin/* {
          admin $2a$14$...
        }
      }
```

`x-caddy` 内で利用可能なテンプレート関数：
- `{{upstreams [service] [port]}}` — 健全なコンテナ IP
- `{{.Name}}` — サービス名
- `{{.Upstreams}}` — すべてのサービス → IP のマップ

### `x-machines` — 配置制約

```yaml
services:
  db:
    image: postgres:18
    x-machines: db-machine          # Single machine name
  app:
    image: app:latest
    x-machines:
      - machine-1
      - machine-2
```

### 完全マルチサービス例

```yaml
services:
  api:
    build: ./api
    x-ports:
      - api.example.com:3000/https
    environment:
      DATABASE_URL: postgres://db:5432/mydb

  web:
    build: ./web
    x-ports:
      - example.com:8000/https
      - www.example.com:8000/https
    environment:
      API_URL: http://api:3000

  db:
    image: postgres:18
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db-data:/var/lib/postgresql/data
    x-machines: db-machine

volumes:
  db-data:
```

---

## 外部（非クラスタ）デバイスへのルーティング

実コンテナを実行せずに Caddy 経由で外部デバイス（例：BMC、NAS、ルータ UI）を公開するには：

**1. Caddyfile スニペットを作成**（例：`~/device.caddyfile`）：

```caddyfile
https://device.example.com {
    reverse_proxy https://192.168.1.x {
        transport http {
            tls_insecure_skip_verify   # needed for self-signed BMC certs
        }
    }
    log
}
```

平文上流の場合：`reverse_proxy http://192.168.1.x:port`

**2. no-op コンテナで名前付きサービスとして登録：**

```bash
uc service run \
  --name device-bmc \
  --caddyfile ~/device.caddyfile \
  registry.k8s.io/pause:3.9
```

`pause` は最小の no-op コンテナ — 何もしないが、Caddyfile を添付するためのサービスエントリを Uncloud に提供する。

**3. 検証：**

```bash
uc caddy config   # device.example.com block should appear
```

> `--caddyfile` は非 `@host` 公開ポートと組み合わせられない。

**DNS ヒント：** ワイルドカードレコード（`*.yourdomain.com → cluster-public-ip`）は、任意の新しいサブドメインが直ちに動作することを意味する — サービスごとに DNS 変更不要。

---

## サービス DNS（内部）

クラスタ内のサービスは名前で互いに解決する：

| DNS 名 | 解決先 |
|----------|------------|
| `service-name` | 任意の健全なコンテナ |
| `service-name.internal` | 同じ |
| `rr.service-name.internal` | ラウンドロビン |
| `nearest.service-name.internal` | マシンローカル優先 |

---

## スケーリングとグローバルサービス

```bash
uc scale web 5    # 5 replicas (spread across machines)
uc scale web 1    # Scale down
```

```yaml
services:
  caddy:
    deploy:
      mode: global   # One container on every machine
```

---

## イメージタグテンプレート（compose.yaml 内）

```yaml
image: myapp:{{gitdate "20060102"}}.{{gitsha 7}}
image: myapp:{{gitsha 7}}.${GITHUB_RUN_ID:-local}
```

| 関数 | 出力 |
|----------|--------|
| `{{gitsha N}}` | コミット SHA の最初の N 文字 |
| `{{gitdate "format"}}` | Go フォーマットでの git コミット日付 |
| `{{date "format"}}` | 現在日付 |

---

## 一般的なワークフロー

**ソースからデプロイ：**
```bash
uc deploy                          # Build + push + deploy
uc build --push && uc deploy --no-build   # Separate steps
```

**サービスを検査：**
```bash
uc inspect web
uc logs -f web
uc logs --since 1h web
uc exec web                        # Opens shell
uc exec web /bin/sh -c "env"       # Run specific command
```

**ゼロダウンタイムデプロイ**は自動的に発生する。Uncloud は古いコンテナを終了する前にヘルスチェックを待つ。

**強制再作成：**
```bash
uc deploy --recreate
```

---

## よくあるミス

| ミス | 修正 |
|---------|-----|
| Caddyfile を直接編集 | compose の `x-caddy` または `uc service run` の `--caddyfile` を使う |
| 自己署名証明書付きの HTTPS 上流をプロキシ | `transport http { tls_insecure_skip_verify }` を追加 |
| `uc caddy config` がユーザー定義ブロックを表示しない | Caddy 管理ソケットが到達不可 — `uc inspect caddy` と `uc logs caddy` をチェック |
| サービスがコンテナから外部 LAN IP に到達できない | Caddy コンテナのホストがターゲットネットワークにルートできるか検証 |
| `uc service rm` 後にボリュームが失われる | Named ボリュームは持続、Anonymous ボリュームのみ自動削除 |
