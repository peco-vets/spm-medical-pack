---
name: homelab-network-setup
description: ゲートウェイ、スイッチ、AP、IP 範囲、DHCP 予約、DNS、ケーブリング、よくある初心者ミスを扱う実用的なホーム・ホームラボネットワーク計画（homelab network setup, gateway, switch, AP, DHCP, DNS）。
origin: community
---

# ホームラボネットワークセットアップ

完全再構築不要に成長できるホームまたは小規模ラボネットワークを設計するために用いる。

## 利用タイミング

- 新規ホームネットワーク計画、または ISP ルーターのみ構成のリデザイン
- ゲートウェイ・スイッチ・AP の役割選定
- IP 範囲・DHCP スコープ・静的予約・DNS の設計
- 将来の VLAN・Pi-hole・NAS・ラボサーバ・VPN アクセス準備
- 二重 NAT、不安定 Wi-Fi、サーバアドレス変動を伴う新ネットワークのトラブルシューティング

## 仕組み

デバイス役割の分離から始める:

```text
Internet
  |
Modem or ONT
  |
Gateway or router      NAT, firewall, DHCP, DNS, inter-VLAN routing
  |
Managed switch         wired clients, AP uplinks, optional VLAN trunks
  |
Access points          Wi-Fi only; ideally wired backhaul
Servers and NAS        stable addresses, DNS names, monitoring
Clients and IoT        DHCP pools, isolated later if VLANs are available
```

機能チェックリストではなくオペレータに合うゲートウェイを選ぶ:

| 選択肢 | 適合 | 備考 |
| --- | --- | --- |
| ISP ルーター | 基本インターネットのみ | 制御が限定的で VLAN サポートが弱いことが多い |
| UniFi ゲートウェイ | 管理されたホームネットワーク | 良好な UI、エコシステムロックイン |
| OPNsense / pfSense | 柔軟なホームラボ | 強力な VLAN・firewall・VPN・DNS 制御 |
| MikroTik | 上級ネットワークユーザー | パワフルだが誤構成しやすい |
| Linux ルーター | いじり屋向け | 主ゲートウェイとして使う前にロールバックをドキュメント化 |

## IP プラン

VPN 利用を見越す場合、最も一般的なデフォルト `192.168.1.0/24` を避ける。ホテル・オフィス・ISP ルーターと衝突しがちである。

```text
Example small homelab plan:

192.168.10.0/24  trusted clients
192.168.20.0/24  IoT and media devices
192.168.30.0/24  servers and NAS
192.168.40.0/24  guest Wi-Fi
192.168.99.0/24  network management

Gateway convention: .1
Infrastructure reservations: .2 through .49
Dynamic DHCP pool: .50 through .240
Spare room: .241 through .254
```

ローカル名には `home.arpa` を使う。ホームネットワーク向けに予約されており、`home.lan` のようなアドホック名の漏洩/衝突問題を避けられる。

```text
nas.home.arpa
pihole.home.arpa
gateway.home.arpa
switch-01.home.arpa
```

## DHCP と DNS

- SSH 接続、ブックマーク、監視、サービス公開する対象には DHCP 予約を使う
- ローカルリゾルバを意図的に展開するまで、DNS としてゲートウェイを配る
- Pi-hole や他の DNS フィルタを使うなら、先に予約を割り当ててから DHCP の DNS オプションをそのアドレスに向ける
- サブネットごとに小さな静的/予約範囲を保ち、置換が動的 lease と衝突しないようにする

## ケーブリングと Wi-Fi

- Ethernet を引ける場合はメッシュより有線 AP バックホールを優先する
- 予算が許せば AP とカメラには PoE スイッチを使う
- 各ケーブルの両端にラベルを付け、シンプルなポートマップを保つ
- 停電が頻繁なら、ゲートウェイ・スイッチ・DNS サーバ・NAS を UPS 電源に置く

## 例

### 初心者アップグレード

目標: ISP ルーターを保ちつつ小規模ラボを安定化する。

1. NAS、Pi、任意の SSH ホストに DHCP 予約を設定する
2. ローカル名を `home.arpa` に移行する
3. 二次ルーターや AP の重複 DHCP サーバを無効化する
4. ワイヤレスバックホールではなく主 AP を有線にする

### VLAN レディプラン

目標: 即時有効化せずに将来のセグメンテーションに備える。

1. trusted・IoT・servers・guest・management に非重複 /24 範囲を選ぶ
2. 各サブネットでゲートウェイ用に .1、インフラ用に .2〜.49 を予約する
3. VLAN と inter-VLAN firewall ルールをサポートするゲートウェイとスイッチを購入する
4. どの SSID とスイッチポートが最終的に各ネットワークにマップされるかドキュメント化する

## アンチパターン

- 理由やドキュメントなしの二重 NAT
- VPN アクセス計画があるのに `192.168.1.0/24` を使う
- NAS、Pi-hole、Home Assistant 等サービスホストへの動的アドレス
- DHCP サーバが有効なまま AP として転用された家庭用ルーター
- カメラ、スマートプラグ、ノート PC、サーバがすべて同じ信頼境界を共有するフラットネットワーク

## 関連

- Skill: `network-interface-health`
- Skill: `network-config-validation`
