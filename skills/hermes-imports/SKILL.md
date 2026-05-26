---
name: hermes-imports
description: ローカル Hermes オペレータワークフローを、サニタイズされた ECC スキルおよびリリースパックアーティファクトへ変換する（Hermes imports, ECC skills, sanitization, release pack）。Hermes ワークフローを、プライベートワークスペース状態・クレデンシャル・ローカル限定パスを漏らさずに ECC へ公開再利用化する準備のときに用いる。
origin: ECC
---

# Hermes Imports

反復された Hermes ワークフローを ECC で出荷可能な形にするときに用いる。

Hermes はオペレータシェルである。ECC は再利用可能ワークフローレイヤである。Import は安定パターンを Hermes から ECC へ移動するが、プライベート状態は移動しない。

## 利用タイミング

- Hermes ワークフローが再利用可能になるほど反復された
- ローカルオペレータプロンプトを公開 ECC スキル化したい
- ローンチ・コンテンツ・リサーチ・エンジニアリングワークフローにサニタイズされた引き継ぎドキュメントが必要
- ワークフローが、公開前に削除すべきローカルパス・クレデンシャル・個人データセット・プライベートアカウント名に言及する

## Import ルール

- ローカルパスをリポジトリ相対パスまたはプレースホルダに変換する
- 実アカウント名を `operator`、`default profile`、`workspace owner` のような役割ラベルへ置換する
- クレデンシャル要件はプロバイダ名のみで記述する
- 例を狭く運用的に保つ
- 生ワークスペースエクスポート・トークン・OAuth ファイル・健康データ・CRM データ・財務データを出荷しない
- ワークフローがプライベート状態を必要とするならローカルに留める

## サニタイズチェックリスト

import されたワークフローを commit する前に以下をスキャンする:

- `/Users/...` のような絶対パス
- ローカルセットアップを明示説明しない限り `~/.hermes` パス
- API キー・トークン・cookie・OAuth ファイル・bearer 文字列
- 電話番号・私的メールアドレス・個人接触グラフ
- 既に公開でないクライアント名・家族名・アカウント名
- 収益・健康・CRM 詳細
- プライベートシステムからのツール出力を含む生ログ

## 変換パターン

1. 再現可能なオペレータループを特定する
2. プライベート入出力を剥がす
3. ローカルパスをリポジトリ相対例に書き換える
4. 1回限りの指示を `When To Use` セクションと短いプロセスへ転化する
5. 具体的な出力要件を加える
6. PR オープン前にシークレットとローカルパスのスキャンを行う

## 例: ローンチ引き継ぎ

ローカル Hermes プロンプト:

```text
Read my local workspace files and finalize launch copy.
```

ECC 安全版:

```text
Use the public release pack under docs/releases/<version>/.
Return one X thread, one LinkedIn post, one recording checklist, and the missing assets list.
```

## 例: Quiet-Hours オペレータジョブ

ローカル Hermes ジョブ:

```text
Run my private inbox, finance, and content checks overnight.
```

ECC 安全版:

```text
Describe the scheduler policy, the quiet-hours window, the escalation rules, and the categories of checks. Do not include private data sources or credentials.
```

## 出力契約

以下を返す:

- 候補 ECC スキル名
- サニタイズ済みワークフローサマリ
- 必要な公開入力
- 削除されたプライベート入力
- 残存リスク
- 作成または更新すべきファイル
