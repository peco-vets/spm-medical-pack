---
name: network-interface-health
description: ルータ、スイッチ、Linux ホストでのインターフェースエラー、ドロップ、CRC、二重通信不一致、フラッピング、速度ネゴシエーション問題、カウンタトレンドを診断する (Diagnose interface errors, drops, CRCs, duplex mismatches, flapping, speed negotiation issues, counter trends on routers, switches, Linux hosts)。
origin: community
---

# Network インターフェース健全性

ネットワーク症状が物理リンク、スイッチポート、ケーブル、トランシーバ、二重通信設定、または混雑したインターフェースに起因する可能性がある場合にこのスキルを使う。

## 使用するタイミング

- ホストや VLAN でパケットロス、レイテンシスパイク、または断続的な到達性
- スイッチまたはルータインターフェースが CRC、ラント、ジャイアント、ドロップ、リセット、またはフラップを示す
- ハードウェア交換前にリンクの両端を比較する必要がある
- 変更ウィンドウに前後のインターフェースカウンタ証拠が必要
- モニタリングが `ifInErrors`、`ifOutErrors`、または `ifOutDiscards` の上昇を報告

## 動作の仕組み

インターフェースカウンタは証拠だが、絶対数より傾向が重要である。ベースラインをキャプチャし、測定間隔を待ち、再度キャプチャしてから増分を比較する。

```text
show interfaces <interface>
show interfaces <interface> status
show logging | include <interface>|changed state|line protocol
```

Linux ホストで:

```text
ip -s link show <interface>
ethtool <interface>
ethtool -S <interface>
```

## カウンタリファレンス

| カウンタ | 意味 | 一般的な原因 |
| --- | --- | --- |
| CRC | 受信フレームのチェックサム失敗 | 不良ケーブル、汚れたファイバ、不良光モジュール、二重通信不一致 |
| input errors | 集約受信側エラー | 結論づける前にサブカウンタをチェック |
| runts | 最小 Ethernet サイズ未満のフレーム | 二重通信不一致、衝突ドメイン、欠陥 NIC |
| giants | 期待 MTU より大きいフレーム | MTU 不一致またはジャンボフレーム境界 |
| input drops | デバイスがインバウンドパケットを受け入れられなかった | バースト、オーバーサブスクリプション、CPU パス、キュー圧力 |
| output drops | 出口キューがパケットを破棄 | 輻輳、QoS ポリシー、不足したアップリンク |
| resets | インターフェースハードウェアリセット | フラッピング、キープアライブ、ドライバ、光モジュール、電源 |
| collisions | Ethernet 衝突カウンタ | 半二重またはネゴシエーション不一致 |

## 診断フロー

### CRC または入力エラー

1. カウンタが履歴ではなく増加していることを確認する
2. リンクの両端をチェックする。受信側エラーは通常、エラーを報告するポートではなく、その側に到着する信号を指す
3. パッチケーブルを交換するか、ファイバと光モジュールを清掃/交換する
4. 速度/二重通信設定が両側で一致することを確認する
5. 同じタイムスタンプ周辺のフラップイベントをログでチェックする

### ドロップ

1. 入力ドロップを出力ドロップから分離する
2. インターフェースレートを容量と比較する
3. QoS ポリシー、キューカウンタ、リンクがオーバーサブスクライブされたアップリンクかどうかをチェックする
4. キューチューニングを副次的に扱う。まずリンクが輻輳しているかどうかを証明する

### 二重通信と速度

両側がサポートする場合、現代の Ethernet リンクでは自動ネゴシエーションを優先する。一方を固定する必要がある場合、両側を明示的に設定し、理由を文書化する。決して一方の固定速度/二重通信と他方の自動を混在させない。

```text
show interfaces <interface> | include duplex|speed
```

## 安全なパーサ例

各インターフェースブロックを 1 つのヘッダーから次へとスライスする。任意の文字ウィンドウを使わない。大きなインターフェースブロックはカウンタを見逃すか、誤ったポートに割り当てる原因になる。

```python
import re
from typing import Any

HEADER_RE = re.compile(
    r"^(?P<name>\S+) is (?P<status>(?:administratively )?down|up), "
    r"line protocol is (?P<protocol>up|down)",
    re.I | re.M,
)
ERROR_RE = re.compile(r"(?P<input>\d+) input errors, (?P<crc>\d+) CRC", re.I)
DROP_RE = re.compile(r"(?P<output>\d+) output errors", re.I)
DUPLEX_RE = re.compile(r"(?P<duplex>Full|Half|Auto)-duplex,\s+(?P<speed>[^,]+)", re.I)

def parse_show_interfaces(raw: str) -> list[dict[str, Any]]:
    headers = list(HEADER_RE.finditer(raw))
    interfaces = []
    for index, header in enumerate(headers):
        end = headers[index + 1].start() if index + 1 < len(headers) else len(raw)
        block = raw[header.start():end]
        errors = ERROR_RE.search(block)
        drops = DROP_RE.search(block)
        duplex = DUPLEX_RE.search(block)
        interfaces.append({
            "name": header.group("name"),
            "status": header.group("status"),
            "protocol": header.group("protocol"),
            "duplex": duplex.group("duplex") if duplex else "unknown",
            "speed": duplex.group("speed").strip() if duplex else "unknown",
            "input_errors": int(errors.group("input")) if errors else 0,
            "crc_errors": int(errors.group("crc")) if errors else 0,
            "output_errors": int(drops.group("output")) if drops else 0,
        })
    return interfaces
```

## 例

### 1 つのスイッチポートでの CRC

1. ローカルポートのカウンタをキャプチャする
2. 接続されたリモートポートのカウンタをキャプチャする
3. ルーティングまたはファイアウォールルールを変更する前にケーブルまたは光モジュールを交換する
4. ベースラインを記録した後でのみカウンタをクリアする
5. 固定間隔後に再確認する

### インターネットは遅いが LAN は問題ない

1. WAN インターフェースドロップ/エラーをチェック
2. LAN アップリンク使用率と出力ドロップをチェック
3. WAN リンクがクリーンだがスループットがまだ低い場合はゲートウェイ CPU をチェック
4. 上流サービスを非難する前に有線と無線のテストを比較する

## アンチパターン

- ベースラインを保存する前にカウンタをクリア
- リンクの片側のみを見る
- 時間ウィンドウなしですべての履歴 CRC を現在の問題と仮定する
- 一方の自動ネゴシエーションと他方の固定速度/二重通信を混在させる
- 輻輳をチェックする前に出力ドロップをケーブル問題として扱う

## 参照

- エージェント: `network-troubleshooter`
- スキル: `network-config-validation`
- スキル: `homelab-network-setup`
