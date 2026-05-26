---
name: network-config-validation
description: 危険なコマンド、重複アドレス、サブネットオーバーラップ、古い参照、管理プレーンリスク、IOS スタイルセキュリティ衛生を含むルータとスイッチ設定のデプロイ前チェック (Pre-deployment checks for router and switch configuration; dangerous commands, duplicate addresses, subnet overlaps, stale references, management-plane risk, IOS-style security hygiene)。
origin: community
---

# Network 設定検証

変更ウィンドウ前または自動化実行が本番デバイスに触れる前にネットワーク設定をレビューするためにこのスキルを使う。

## 使用するタイミング

- デプロイ前の Cisco IOS または IOS-XE スタイルスニペットのレビュー
- スクリプトやテンプレートから生成された設定の監査
- 危険なコマンド、重複 IP アドレス、またはサブネットオーバーラップを探す
- ACL、route-map、prefix-list、またはライン ポリシーが参照されているが定義されていないかチェック
- ネットワーク自動化用の軽量プリフライトスクリプトの構築

## 動作の仕組み

設定検証を完全なパーサとしてではなく、層化された証拠として扱う。Regex チェックはプリフライト警告に有用だが、最終承認には依然としてネットワークエンジニアによる意図、プラットフォーム構文、ロールバック手順のレビューが必要である。

この順序で検証する:

1. 破壊的コマンド
2. 認証情報と管理プレーン露出
3. 重複アドレスとオーバーラップサブネット
4. ACL、route-map、prefix-list、インターフェースへの古い参照
5. NTP、タイムスタンプ、リモートロギング、バナーなどの運用衛生

## 危険なコマンドの検出

```python
import re

DANGEROUS_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"\breload\b", re.I), "reload causes downtime"),
    (re.compile(r"\berase\s+(startup|nvram|flash)", re.I), "erases persistent storage"),
    (re.compile(r"\bformat\b", re.I), "formats a device filesystem"),
    (re.compile(r"\bno\s+router\s+(bgp|ospf|eigrp)\b", re.I), "removes a routing process"),
    (re.compile(r"\bno\s+interface\s+\S+", re.I), "removes interface configuration"),
    (re.compile(r"\baaa\s+new-model\b", re.I), "changes authentication behavior"),
    (re.compile(r"\bcrypto\s+key\s+(zeroize|generate)\b", re.I), "changes device SSH keys"),
]

def find_dangerous_commands(lines: list[str]) -> list[dict[str, str | int]]:
    findings = []
    for line_number, line in enumerate(lines, start=1):
        stripped = line.strip()
        for pattern, reason in DANGEROUS_PATTERNS:
            if pattern.search(stripped):
                findings.append({
                    "line": line_number,
                    "command": stripped,
                    "reason": reason,
                })
    return findings
```

## 重複 IP とサブネットオーバーラップ

```python
import ipaddress
import re
from collections import Counter

IP_ADDRESS_RE = re.compile(
    r"^\s*ip address\s+"
    r"(?P<ip>\d{1,3}(?:\.\d{1,3}){3})\s+"
    r"(?P<mask>\d{1,3}(?:\.\d{1,3}){3})\b",
    re.I | re.M,
)

def extract_interfaces(config: str) -> list[dict[str, str]]:
    results = []
    current = None
    for line in config.splitlines():
        if line.startswith("interface "):
            current = line.split(maxsplit=1)[1]
            continue
        match = IP_ADDRESS_RE.match(line)
        if current and match:
            ip = match.group("ip")
            mask = match.group("mask")
            network = ipaddress.ip_interface(f"{ip}/{mask}").network
            results.append({"interface": current, "ip": ip, "network": str(network)})
    return results

def find_duplicate_ips(config: str) -> list[str]:
    ips = [entry["ip"] for entry in extract_interfaces(config)]
    counts = Counter(ips)
    return sorted(ip for ip, count in counts.items() if count > 1)

def find_subnet_overlaps(config: str) -> list[tuple[str, str]]:
    networks = [ipaddress.ip_network(entry["network"]) for entry in extract_interfaces(config)]
    overlaps = []
    for index, left in enumerate(networks):
        for right in networks[index + 1:]:
            if left.overlaps(right):
                overlaps.append((str(left), str(right)))
    return overlaps
```

## 管理プレーンチェック

VTY ブロックをセクションごとにパースし、access-class チェックが無関係なラインにこぼれないようにする。

```python
import re

def iter_blocks(config: str, starts_with: str) -> list[str]:
    blocks = []
    current: list[str] = []
    for line in config.splitlines():
        if line.startswith(starts_with):
            if current:
                blocks.append("\n".join(current))
            current = [line]
            continue
        if current:
            if line and not line.startswith(" "):
                blocks.append("\n".join(current))
                current = []
            else:
                current.append(line)
    if current:
        blocks.append("\n".join(current))
    return blocks

def check_vty_blocks(config: str) -> list[str]:
    issues = []
    for block in iter_blocks(config, "line vty"):
        if re.search(r"transport\s+input\s+.*telnet", block, re.I):
            issues.append("VTY allows Telnet; require SSH only.")
        if not re.search(r"\baccess-class\s+\S+\s+in\b", block, re.I):
            issues.append("VTY block has no inbound access-class source restriction.")
        if not re.search(r"\bexec-timeout\s+\d+\s+\d+\b", block, re.I):
            issues.append("VTY block has no explicit exec-timeout.")
    return issues
```

## セキュリティ衛生チェック

```python
SECURITY_PATTERNS = [
    (re.compile(r"\bsnmp-server community\s+(public|private)\b", re.I),
     "default SNMP community configured"),
    (re.compile(r"\bsnmp-server community\s+\S+", re.I),
     "SNMPv2 community string configured; prefer SNMPv3 authPriv"),
    (re.compile(r"\bip ssh version 1\b", re.I),
     "SSH version 1 enabled"),
    (re.compile(r"\benable password\b", re.I),
     "enable password is present; use enable secret"),
    (re.compile(r"\busername\s+\S+\s+password\b", re.I),
     "local username uses password instead of secret"),
]

BEST_PRACTICE_PATTERNS = [
    (re.compile(r"\bntp server\b", re.I), "NTP server"),
    (re.compile(r"\bservice timestamps\b", re.I), "log timestamps"),
    (re.compile(r"\blogging\s+\S+", re.I), "logging destination or buffer"),
    (re.compile(r"\bsnmp-server group\s+\S+\s+v3\s+priv\b", re.I), "SNMPv3 authPriv group"),
    (re.compile(r"\bbanner\s+(login|motd)\b", re.I), "login banner"),
]

def check_security(config: str) -> list[str]:
    return [message for pattern, message in SECURITY_PATTERNS if pattern.search(config)]

def check_missing_hygiene(config: str) -> list[str]:
    return [
        f"Missing {description}"
        for pattern, description in BEST_PRACTICE_PATTERNS
        if not pattern.search(config)
    ]
```

## 例

### 変更ウィンドウプリフライト

1. ペーストする正確なスニペットで危険なコマンドチェックを実行
2. 完全な候補設定に対して重複 IP とサブネットオーバーラップチェックを実行
3. 参照されるすべての ACL、route-map、prefix-list が存在することを確認
4. 管理プレーン変更前にロールバックコマンドとアウトオブバンドアクセスを確認

### 自動化プリフライト

Netmiko、NAPALM、Ansible、またはベンダー API 自動化が生成された設定をプッシュする前のブロッキングゲートとして検証を使う。危険なコマンドと認証情報でフェイルクローズ。変更スコープ外のベストプラクティスギャップで警告する。

## アンチパターン

- regex 検証をデバイスパーサとして扱う
- ドライラン diff なしで生成された設定を適用
- 監視要件として SNMPv2 コミュニティ文字列を推奨
- 無関係なセクションにまたがる可能性のある regex で VTY ブロックをチェック
- カウンタ/ログを読む代わりに ACL を無効化してファイアウォール挙動をテスト

## 参照

- エージェント: `network-config-reviewer`
- エージェント: `network-troubleshooter`
- スキル: `network-interface-health`
