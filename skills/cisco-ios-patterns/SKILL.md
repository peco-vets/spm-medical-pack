---
name: cisco-ios-patterns
description: show コマンド、設定階層、ワイルドカードマスク、ACL 配置、インターフェース衛生、安全な変更ウィンドウ検証のための Cisco IOS と IOS-XE レビューパターン (Cisco IOS, IOS-XE, show command, ACL, wildcard mask, change window)。
origin: community
---

# Cisco IOS パターン

Cisco IOS や IOS-XE スニペットをレビューする、変更ウィンドウチェックリストを構築する、インシデントを悪化させずにルータやスイッチから証拠を収集する方法を説明する際にこのスキルを使う。

## 利用するタイミング

- 計画された変更前の IOS または IOS-XE 設定のレビュー。
- トラブルシューティングのための読み取り専用 `show` コマンドの選択。
- ACL ワイルドカードマスクとインターフェース方向のチェック。
- グローバル、インターフェース、ルーティングプロセス、ラインの設定モードの説明。
- 変更が running config に着地し意図的に保存されたことの検証。

## 運用ルール

IOS の例はパターンとして扱い、貼り付けてすぐの本番変更として扱わない。実機での変更前に、プラットフォーム、インターフェース名、現在の設定、ロールバックパス、アウトオブバンドアクセスを確認する。

以下のワークフローを優先する:

1. 読み取り専用コマンドで現在の状態をキャプチャする。
2. 正確な候補設定をレビューする。
3. 管理アクセスがロックアウトされないことを確認する。
4. メンテナンスウィンドウで最小の変更を適用する。
5. 状態を再読込し、ベースラインと比較し、検証後にのみ保存する。

## モードリファレンス

```text
Router> enable
Router# show running-config
Router# configure terminal
Router(config)# interface GigabitEthernet0/1
Router(config-if)# description UPLINK-TO-CORE
Router(config-if)# no shutdown
Router(config-if)# exit
Router(config)# end
Router# show running-config interface GigabitEthernet0/1
```

`running-config` はアクティブメモリ。`startup-config` はリロードで生き残るもの。コマンドが受け入れられたという理由だけで変更を保存しない。最初に挙動を検証し、変更が承認されたら `copy running-config startup-config` を使う。

## 読み取り専用収集

```text
show version
show inventory
show processes cpu sorted
show memory statistics
show logging
show running-config | section line vty
show running-config | section interface
show running-config | section router bgp
show ip interface brief
show interfaces
show interfaces status
show vlan brief
show mac address-table
show spanning-tree
show ip route
show ip protocols
show ip access-lists
show route-map
show ip prefix-list
```

設定にシークレット、顧客名、私有トポロジが含まれる可能性があるとき、フル設定をチケットにダンプするのではなく必要な特定セクションを収集する。

## ワイルドカードマスク

IOS ACL と多くのルーティング文はサブネットマスクではなくワイルドカードマスクを使う。

```text
Subnet mask       Wildcard mask
255.255.255.255   0.0.0.0
255.255.255.252   0.0.0.3
255.255.255.0     0.0.0.255
255.255.0.0       0.0.255.255
```

デプロイ前にワイルドカードマスクをレビューする。ワイルドカードとして誤って使用されたサブネットマスクは意図したよりはるかに多いトラフィックをマッチしうる。

```text
ip access-list extended WEB-IN
  10 permit tcp 192.0.2.0 0.0.0.255 any eq 443
  999 deny ip any any log
```

すべての ACL は末尾に暗黙の deny を持つ。運用目標にミスの観測が含まれる場合は明示的にログ付き deny を追加し、ログボリュームが安全であることを確認する。

## ACL 配置レビュー

ACL をインターフェースに適用する前に、これらの質問に答える:

- どのトラフィック方向がフィルタされるか、`in` か `out` か?
- 管理トラフィックは既知のジャンプホストや管理サブネットから発生しているか?
- 必要なルーティング、DNS、NTP、モニタリング、アプリケーショントラフィックの明示的な permit があるか?
- 安全なテストソースからのヒットカウンタが利用可能か?
- ロールバックコマンドとアクティブなコンソールやアウトオブバンドパスがあるか?

ファイアウォールや ACL の保護を削除して到達性をテストしない。最初にカウンタ、ログ、ルート状態を読む。

## インターフェース衛生

```text
interface GigabitEthernet0/1
 description UPLINK-TO-CORE
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30
 switchport trunk native vlan 999
 no shutdown
```

明確な description、明示的な switchport mode、文書化されたネイティブ VLAN を使う。ルーテッドインターフェースでは、リンク状態がフォワーディングが正しいことを意味すると仮定する前にマスク、ピアアドレッシング、ルーティングプロセスを確認する。

## 変更ウィンドウ検証

実際の変更にマッチする前後チェックを使う。

```text
show running-config | section interface GigabitEthernet0/1
show interfaces GigabitEthernet0/1
show logging | include GigabitEthernet0/1|changed state|line protocol
show ip route <prefix>
show ip access-lists <name>
```

ルーティング変更では、変更前後でネイバー状態とルートテーブルもキャプチャする。ACL 変更では、汎用 ping に頼るのではなく計画されたテストソースからのヒットカウンタを比較する。

## アンチパターン

- デバイス固有の diff なしに生成された設定を適用する。
- 変更後チェックがパスする前に設定を保存する。
- IOS がワイルドカードマスクを期待する場所でサブネットマスクを使う。
- ACL を誤ったインターフェース方向に適用する。
- ACL、ルートポリシー、認証を無効化してトラブルシューティングする。
- シークレットとトポロジをサニタイズせずに完全な設定をパブリックツールに貼り付ける。

## 関連

- エージェント: `network-config-reviewer`
- エージェント: `network-troubleshooter`
- スキル: `network-config-validation`
- スキル: `network-interface-health`
