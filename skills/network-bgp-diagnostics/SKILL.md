---
name: network-bgp-diagnostics
description: ネイバー状態、ルート交換、プレフィックスポリシー、AS パス検査、安全な証拠収集のための診断のみの BGP トラブルシューティングパターン (Diagnostics-only BGP troubleshooting patterns for neighbor state, route exchange, prefix policy, AS path inspection, safe evidence collection)。
origin: community
---

# Network BGP 診断

BGP セッションがダウン、フラッピング、ルート欠落で確立、または予期しないプレフィックスを広告している場合にこのスキルを使う。デフォルトワークフローは読み取り専用の証拠収集である。ポリシーとリセットアクションはレビュー済み変更ウィンドウに属する。

## 使用するタイミング

- BGP ネイバーが Idle、Connect、Active、OpenSent、または OpenConfirm でスタックしている
- セッションは Established だが期待プレフィックスが欠落している
- route-map、prefix-list、max-prefix 制限、または AS パスポリシーがルートをフィルタリングしている可能性がある
- BGP 変更の前後の証拠が必要
- BGP サマリー出力をパースする自動化をレビュー中

## 読み取り専用トリアージフロー

1. 正確なネイバー、アドレスファミリー、VRF、ローカル/リモート ASN を識別する
2. サマリー状態と最終リセット理由をキャプチャする
3. ピアソースアドレスへの到達性を証明する
4. トランスポート障害を仮定する前にルートポリシー参照をチェックする
5. プラットフォームがそれらのコマンドをサポートする場合、広告、受信、インストールされたルートを比較する

```text
show bgp summary
show bgp neighbors <peer>
show ip route <peer>
show tcp brief | include <peer>|:179
show logging | include BGP|<peer>
show running-config | section router bgp
show ip prefix-list
show route-map
```

デバイスが VRF、IPv6、VPNv4、または EVPN を使う場合は、プラットフォーム固有のアドレスファミリーコマンドを使う。グローバル IPv4 ユニキャストを仮定しない。

## 状態解釈

| 状態 | 最初のチェック |
| --- | --- |
| プレフィックス数を伴う Established | ルート交換は稼働中。ポリシーとテーブル選択を検査 |
| ゼロプレフィックスの Established | インバウンドポリシー、max-prefix、広告ルート、AFI/SAFI をチェック |
| Active | TCP セッションが完了していない。ルーティング、ソース、ACL、ピア到達性をチェック |
| Connect | TCP 接続が進行中。パスとリモートリスナーをチェック |
| OpenSent/OpenConfirm | TCP は動作している。ASN、認証、タイマー、能力、ログをチェック |
| Idle | ネイバーが無効化、設定欠落、ポリシーでブロック、またはバックオフタイマーの可能性 |

## トランスポートチェック

```text
ping <peer> source <local-source>
traceroute <peer> source <local-source>
show ip route <peer>
show bgp neighbors <peer> | include BGP state|Last reset|Local host|Foreign host
```

ピアがループバックからソースされている場合、両方向がループバックアドレスにルーティングされ、ネイバー設定が期待されるアップデートソースを使うことを確認する。

ACL やファイアウォールポリシーを診断ショートカットとして無効化することを避ける。最初にヒットカウンタ、ログ、パス状態を読む。

## ルートポリシーチェック

```text
show bgp neighbors <peer> advertised-routes
show bgp neighbors <peer> routes
show ip prefix-list <name>
show route-map <name>
show bgp <prefix>
```

一部のプラットフォームでは `received-routes` が利用可能になる前に追加設定が必要である。オペレータが変更を承認しない限り、インシデントトリアージ中にその設定を追加しない。

## AS パスとプレフィックスレビュー

```text
show bgp regexp _65001_
show bgp regexp ^65001$
show bgp <prefix>
show bgp neighbors <peer> advertised-routes | include Network|Path|<prefix>
```

AS パス regex は慎重に使う。`_65001_` は AS 65001 をトークンとして一致する。プレーンな `65001` はより長い ASN や無関係なテキストに一致し得る。

## パーサパターン

```python
import re
from typing import Any

BGP_SUMMARY_RE = re.compile(
    r"^(?P<neighbor>\d{1,3}(?:\.\d{1,3}){3})\s+"
    r"(?P<version>\d+)\s+"
    r"(?P<remote_as>\d+)\s+"
    r"(?P<msg_rcvd>\d+)\s+"
    r"(?P<msg_sent>\d+)\s+"
    r"(?P<table_version>\d+)\s+"
    r"(?P<input_queue>\d+)\s+"
    r"(?P<output_queue>\d+)\s+"
    r"(?P<uptime>\S+)\s+"
    r"(?P<state_or_prefixes>\S+)$",
    re.M,
)

def parse_bgp_summary(raw: str) -> list[dict[str, Any]]:
    rows = []
    for match in BGP_SUMMARY_RE.finditer(raw):
        state_or_prefixes = match.group("state_or_prefixes")
        if state_or_prefixes.isdigit():
            state = "Established"
            prefixes_received = int(state_or_prefixes)
        else:
            state = state_or_prefixes
            prefixes_received = None
        rows.append({
            "neighbor": match.group("neighbor"),
            "remote_as": int(match.group("remote_as")),
            "state": state,
            "prefixes_received": prefixes_received,
            "uptime": match.group("uptime"),
        })
    return rows
```

利用可能な場合は構造化パーサ出力を優先するが、BGP サマリー形式はプラットフォームとアドレスファミリーで異なるため、生の出力をインシデント記録と一緒に保存する。

## 変更ウィンドウのみ

これらのアクションはルーティングに影響を与える可能性があり、自動診断として提案すべきではない:

- BGP セッションのクリア
- ネイバー認証、タイマー、アップデートソース、route-map、または prefix-list の変更
- 追加の受信ルートストレージの有効化
- ファイアウォール、ACL、または制御プレーンポリシーの緩和

リセットが承認された場合、プラットフォームがサポートする最も破壊性の低いソフトまたはルートリフレッシュオプションを優先し、なぜ安全なのかを正確に文書化する。

## アンチパターン

- `Active` が常にリモート側がダウンしていることを意味すると仮定する
- VRF、アドレスファミリー、またはアップデートソースの違いを無視
- トークン境界なしの広範な AS パス regex の使用
- 最終リセット理由とログを読む前にピアをハードリセット
- 欠落した `received-routes` 出力をルートが到達しなかった証拠として扱う

## 参照

- スキル: `cisco-ios-patterns`
- スキル: `network-config-validation`
- スキル: `network-interface-health`
