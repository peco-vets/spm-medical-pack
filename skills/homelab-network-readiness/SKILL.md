---
name: homelab-network-readiness
description: ホームラボ VLAN セグメンテーション、ローカル DNS フィルタリング、WireGuard 型リモートアクセス向けのレディネスチェックリスト（homelab network, VLAN, DNS filtering, WireGuard, readiness）。ルーター、ファイアウォール、DHCP、VPN 設定変更前に用いる。
origin: community
---

# ホームラボネットワークレディネス

VLAN、Pi-hole その他ローカル DNS リゾルバ、ファイアウォールルール、リモート VPN アクセスを混在させる家庭または小規模ラボネットワークの変更前に用いる。

これは計画とレビューのスキルである。対象プラットフォーム、現トポロジ、ロールバックパス、コンソールアクセス、メンテナンスウィンドウがすべて既知でない限り、コピペ可能なルーター・ファイアウォール・VPN 設定にはしないこと。

## 利用タイミング

- フラットネットワークを trusted・IoT・guest・サーバ・管理 VLAN へ分割する準備
- DHCP クライアントを Pi-hole、AdGuard Home、Unbound などローカル DNS リゾルバへ移行
- WireGuard、Tailscale、ZeroTier、OpenVPN、ルーターネイティブ VPN アクセスの追加
- ホームラボ変更がオペレータをゲートウェイ・スイッチ・AP・DNS サーバ・VPN サーバからロックアウトする可能性のレビュー
- 非公式なホームネットワーク案を、検証根拠付きの段階的移行計画へ転化する

## 安全ルール

- 最初の回答は read-only に保つ: インベントリ、リスク、段階計画、検証、ロールバック
- ゲートウェイ管理パネル・DNS リゾルバ・SSH・NAS コンソール・VPN 管理 UI を公衆インターネットへ直接露出させない
- プラットフォームとロールバック手順が確定するまで、firewall・NAT・VLAN・DHCP・VPN コマンドを提供しない
- 管理 VLAN・trunk ポート・firewall デフォルトポリシー・DHCP/DNS 設定変更前に、out-of-band または同室コンソールアクセスを必須とする
- ネットワーク全体を新 DNS リゾルバや VPN ルートに向ける前に、インターネットへの動作パスを確保しておく
- IoT・guest・カメラ・ラボサーバネットワークは、オペレータが明示選択しない限り異なる信頼ゾーンとして扱う

## 必須インベントリ

実装ステップ提供前に以下を収集する:

| 領域 | 質問 |
| --- | --- |
| Internet edge | モデムまたは ONT は何か? ISP ルーターは bridged かまだルーティング中か? |
| Gateway | 何がルーティング・firewall・DHCP・VPN 終端を担うか? |
| Switching | どのスイッチポートが uplink・access・trunk・unmanaged か? |
| Wi-Fi | どの SSID がどのネットワークにマップするか? AP は有線かメッシュか? |
| Addressing | 現存するサブネットと VPN サイトと衝突する範囲は? |
| DNS/DHCP | 現在 lease とリゾルバアドレスを配るサービスは? |
| Management | 変更後にオペレータがゲートウェイ・スイッチ・AP に到達する手段は? |
| Recovery | DNS・DHCP・VLAN・VPN ルートが壊れた場合にローカルで戻せるものは何か? |

## VLAN と信頼ゾーン計画

ベンダー構文ではなく意図から始める。

| ゾーン | 典型的内容 | デフォルトポリシー |
| --- | --- | --- |
| Trusted | ノート PC、スマホ、管理ワークステーション | 必要時のみ共有サービスと管理に到達可能 |
| Servers | NAS、Home Assistant、ラボホスト、DNS リゾルバ | trusted クライアントからの狭い inbound のみ受け入れ |
| IoT | TV、スマートプラグ、カメラ、スピーカー | インターネットアクセス + 明示例外のみ |
| Guest | 訪問者デバイス | インターネット限定、LAN 到達なし |
| Management | ゲートウェイ、スイッチ、AP、コントローラ | trusted 管理デバイスからのみ到達可能 |
| VPN | リモートクライアント | trusted クライアントと同等か、より狭いアクセス |

VLAN ID やサブネット推奨前に以下を確認する:

1. ゲートウェイが inter-VLAN ルーティングと firewall ルールをサポートする
2. スイッチが必要な tagged/untagged ポート挙動をサポートする
3. AP が SSID を VLAN にマップできる
4. 変更中にオペレータがどのポート経由で接続しているか把握している
5. trunk と SSID 変更後も管理ネットワークが到達可能なまま

## DNS フィルタリングレディネス

Pi-hole または他のローカルリゾルバは単一障害点ではなく依存として導入する。

1. DHCP オプションで使う前にリゾルバに予約アドレスを与える
2. 公衆 DNS と `home.arpa` ローカル名を解決可能か確認する
3. ゲートウェイまたは二次リゾルバを一時フォールバックとして利用可能に保つ
4. 全 DHCP スコープ変更前に1クライアントまたは1 VLAN でテストする
5. どのネットワークがフィルタリングをバイパスしてよいか、その理由をドキュメント化する
6. ブロックルールがキャプティブポータル・職場 VPN・ファームウェア更新・医療/セキュリティデバイスを壊さないか確認する

有用な検証根拠:

```text
Client gets expected DHCP lease
Client receives expected DNS resolver
Public DNS lookup succeeds
Local home.arpa lookup succeeds
Blocked test domain is blocked only where intended
Gateway and DNS admin interfaces are not reachable from guest or IoT networks
```

## リモートアクセスレディネス

WireGuard 型アクセスでは、鍵生成やポート開放前に、VPN が何へ到達してよいかを決める。

| モード | 利用シーン | リスク備考 |
| --- | --- | --- |
| 単一サブネットへの split tunnel | NAS やラボホストのリモート管理 | ルートリストを狭く保つ |
| 信頼サービスへの split tunnel | IP/DNS で選択アプリへアクセス | 厳密な firewall ルールが必要 |
| Full tunnel | 信頼できないネットワークまたは旅行 | 帯域と DNS 責任が増す |
| Overlay VPN | アイデンティティ制御付きのシンプルなリモートアクセス | 依然 ACL レビューが必要 |

オペレータが以下を確認するまでポートフォワーディングを推奨しない:

- VPN エンドポイントがパッチ適用済みでアクティブにメンテされている
- フォワード先ポートが管理 UI ではなく VPN サービスのみ向き
- ダイナミック DNS・公衆 IP 挙動・ISP CGNAT 状況が把握されている
- 全ネットワーク再構築なしにピア鍵を失効できる
- 誰がいつ接続したかをログまたは接続状態で検証できる

## 変更シーケンス

小さく可逆な変更を優先する:

1. 現トポロジ・IP プラン・DHCP 設定・DNS 設定・firewall ルールをスナップショットする
2. ゲートウェイ・DNS・コントローラ・AP・NAS・VPN エンドポイントにインフラアドレスを予約する
3. クリティカルデバイスを移動せず新ゾーンまたは VLAN を作る
4. 1テストクライアントを移動し DHCP・DNS・ルーティング・インターネット・ブロック挙動を検証する
5. 必要フロー向けに狭い firewall 例外を追加する
6. 低リスクな1デバイスグループを移動する
7. ユースケースを満たす最も狭いルートと firewall ポリシーで VPN アクセスを追加する
8. 最終状態・既知例外・ロールバックコマンド/UI ステップをドキュメント化する

## レビューチェックリスト

- 各ネットワークに存在理由と明確な信頼境界がある
- guest・IoT・公衆インターネットから管理インターフェースに到達不能
- DNS 障害がオペレータのローカル復旧能力を奪わない
- DHCP スコープ変更は広範展開前に1クライアントでテスト済み
- VPN クライアントが必要なルートと DNS 設定のみを受け取る
- firewall ルールはゾーン間でデフォルト deny、名付き例外を持つ
- ゲートウェイ・スイッチ・AP・DNS・VPN 管理表面に依然到達可能
- ロールバックが選定プラットフォーム UI/CLI の語彙でドキュメント化されている

## アンチパターン

- どのスイッチポートと SSID がどの VLAN を運ぶか把握する前にネットワークをセグメント化する
- 管理ワークステーションを唯一到達可能な管理ネットワークから移動する
- フォールバック DNS をテストせず全 DHCP スコープを Pi-hole へ向ける
- NAS・DNS・ルーター・ハイパーバイザ管理を直接インターネットへ公開する
- VPN アクセスをフル trusted-LAN アクセスと同等に扱う
- 一時的に allow-all firewall ルールを追加し削除を忘れる
- 別ベンダーまたはファームウェアバージョンのコマンドをプラットフォーム構文を確認せずコピペする

## 関連

- Skill: `homelab-network-setup`
- Skill: `network-config-validation`
- Skill: `network-interface-health`
