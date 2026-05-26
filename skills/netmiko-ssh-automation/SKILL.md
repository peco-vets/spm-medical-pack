---
name: netmiko-ssh-automation
description: 読み取り専用収集、境界付きバッチ SSH、TextFSM パース、ガード付き設定変更、タイムアウト、ネットワーク自動化エラー処理のための安全な Python Netmiko パターン (Safe Python Netmiko patterns for read-only collection, bounded batch SSH, TextFSM parsing, guarded config changes, timeouts, network automation error handling)。
origin: community
---

# Netmiko SSH 自動化

Netmiko でネットワークデバイスに接続する Python 自動化を記述またはレビューする場合にこのスキルを使う。デフォルトパスを読み取り専用に保つ。設定変更には別の変更ウィンドウ、ピアレビュー、ロールバック計画が必要である。

## 使用するタイミング

- ルータ、スイッチ、ファイアウォール全体で `show` コマンド出力を収集する
- インターフェース、ルーティング、設定証拠用の小さな監査スクリプトを構築する
- ネットワーク SSH スクリプトにタイムアウトと例外処理を追加する
- テンプレートが存在する場合に TextFSM でコマンド出力をパースする
- 本番デバイスに触れる前の自動化をレビューする

## 安全性デフォルト

- 読み取り専用の `send_command()` 収集から始める
- インベントリを小さく明示的に保つ。アドレス範囲全体をスイープしない
- 環境変数、ボールト、または `getpass` を使う。認証情報をハードコードしない
- 接続と読み取りタイムアウトを設定する
- 古いデバイスを過負荷にしないよう並行性を制限する
- `send_config_set()` の前に明示的なオペレータフラグを要求する
- 変更が検証・承認されるまで `save_config()` を呼び出さない

## 読み取り専用接続パターン

```python
import os
from getpass import getpass
from netmiko import ConnectHandler
from netmiko.exceptions import (
    NetmikoAuthenticationException,
    NetmikoTimeoutException,
    ReadTimeout,
)

device = {
    "device_type": "cisco_ios",
    "host": "192.0.2.10",
    "username": os.environ.get("NETMIKO_USERNAME") or input("Username: "),
    "password": os.environ.get("NETMIKO_PASSWORD") or getpass("Password: "),
    "secret": os.environ.get("NETMIKO_ENABLE_SECRET"),
    "conn_timeout": 10,
    "auth_timeout": 20,
    "banner_timeout": 15,
    "read_timeout_override": 30,
}

try:
    with ConnectHandler(**device) as conn:
        if device.get("secret") and not conn.check_enable_mode():
            conn.enable()
        output = conn.send_command("show ip interface brief", read_timeout=30)
        print(output)
except NetmikoAuthenticationException:
    print("Authentication failed")
except NetmikoTimeoutException:
    print("SSH connection timed out")
except ReadTimeout:
    print("Command read timed out")
```

例ではドキュメンテーション範囲からのプレースホルダーアドレスを使う。実際のインベントリは無視されたローカルファイルまたはシークレット管理されたシステムに保つ。

## バッチ収集

```python
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any

def collect_show(device: dict[str, Any], command: str) -> dict[str, Any]:
    host = device["host"]
    try:
        with ConnectHandler(**device) as conn:
            output = conn.send_command(command, read_timeout=45)
        return {"host": host, "ok": True, "output": output}
    except (NetmikoAuthenticationException, NetmikoTimeoutException, ReadTimeout) as exc:
        return {"host": host, "ok": False, "error": type(exc).__name__}

results = []
with ThreadPoolExecutor(max_workers=8) as pool:
    futures = [pool.submit(collect_show, device, "show version") for device in devices]
    for future in as_completed(futures):
        results.append(future.result())
```

デバイス資産と AAA システムが高い接続ボリュームを処理できるとわかっている場合を除き、`max_workers` を低く保つ。

## 構造化パース

Netmiko は TextFSM、TTP、または Genie にサポートされたコマンド出力のパースを依頼できる。パーサ出力を最適化として扱い、唯一の証拠パスとしない。

```python
with ConnectHandler(**device) as conn:
    parsed = conn.send_command(
        "show ip interface brief",
        use_textfsm=True,
        raise_parsing_error=False,
        read_timeout=30,
    )

if isinstance(parsed, str):
    print("No parser template matched; store raw output for review")
else:
    for row in parsed:
        print(row)
```

パースがブロッキング決定を駆動する場合、不一致を検査できるよう、生のコマンド出力をパース結果と並べて保持する。

## ガード付き設定パターン

```python
import os

commands = [
    "interface GigabitEthernet0/1",
    "description CHANGE-1234 UPLINK-TO-CORE",
]

apply_changes = os.environ.get("APPLY_NETWORK_CHANGES") == "1"

if not apply_changes:
    print("Dry run only. Candidate commands:")
    print("\n".join(commands))
else:
    with ConnectHandler(**device) as conn:
        conn.enable()
        before = conn.send_command("show running-config interface GigabitEthernet0/1")
        output = conn.send_config_set(commands)
        after = conn.send_command("show running-config interface GigabitEthernet0/1")
        print(before)
        print(output)
        print(after)
        print("Verify behavior before saving startup config.")
```

設定の保存は別の承認ステップである。本番では、ロールバックスニペットを含め、変更記録に前後の証拠をキャプチャする。

## レビューチェックリスト

- スクリプトは明示的なインベントリソースを識別するか?
- 認証情報がソース、ログ、例外メッセージから不在か?
- `conn_timeout`、`auth_timeout`、コマンド `read_timeout` が設定されているか?
- バッチ全体を停止することなくデバイスごとに失敗が報告されるか?
- スクリプトは広範なスキャンと無制限の並行性を避けているか?
- 設定変更はドライランまたは明示的オペレータフラグの背後にあるか?
- `save_config()` は最初のプッシュとは別で、検証に結びついているか?

## アンチパターン

- ソース内のパスワード、enable シークレット、または秘密鍵のハードコード
- デフォルトコードパスとして設定コマンドを送信
- レビューされたインベントリではなく CIDR 範囲に対して自動化を実行
- サニタイズなしで完全な running config を共有システムにログ
- パーサ成功をデバイス状態が正しいことの証拠として扱う

## 参照

- スキル: `cisco-ios-patterns`
- スキル: `network-config-validation`
- スキル: `network-interface-health`
