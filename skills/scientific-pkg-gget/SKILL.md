---
name: gget
description: ゲノムデータベースの素早いクエリ、配列検索、BLAST スタイル検索、エンリッチメントチェック、再現可能なバイオインフォマティクスエビデンスログ用の gget CLI と Python ワークフロー（gget CLI / Python for genomic database queries）。
origin: community
---

# gget

タスクが `gget` CLI または Python パッケージでゲノム参照データベース全体の素早いバイオインフォマティクスルックアップを必要とするときにこのスキルを使う。

## 使用するタイミング

- Ensembl ID、遺伝子メタデータ、転写産物詳細、または配列の検索
- フルローカルパイプラインを構築せずに素早い BLAST または BLAT ルックアップを実行
- Ensembl から参照ゲノムリンクとアノテーションを取得
- 単一インターフェース経由でタンパク質構造、パスウェイ、がん、発現、または疾患関連モジュールにクエリ
- Biopython、Snakemake、Nextflow、BLAST+、データベース固有クライアントなど重量級ツールに移行する前の再現可能な初回パスエビデンスログの作成

タスクが規制対象の臨床解釈、高スループット本番パイプライン、またはデータベースバージョンとローカルインデックスの詳細制御を要するときは、`gget` ではなく専用ワークフローを使う。

## インストール

クリーンな Python 環境を使う。

```bash
python -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install --upgrade gget
gget --help
```

`uv` が利用可能なら：

```bash
uv venv
. .venv/bin/activate
uv pip install gget
```

古い環境に依存する前に、`gget` をアップグレードしてモジュールドキュメントを再確認する。`gget` がクエリする上流データベースは時間とともに変化する。

## 基本パターン

CLI 形式：

```bash
gget <module> [arguments] [options]
```

Python 形式：

```python
import gget

result = gget.search(["BRCA1"], species="human")
print(result)
```

一般的なワークフロー：

1. 必要な種、アセンブリ、遺伝子 ID タイプ、データベースを特定する
2. 引数について現在のモジュールドキュメントをチェックする
3. 小さなクエリを先に実行する
4. 明示的なファイル名と日付で出力を保存する
5. モジュール名、バージョン、引数、データベース前提条件を記録する

## 一般的なモジュール

正確な引数には現在の上流ドキュメントを使う。これらのモジュールは一般的な最初の選択肢：

- `gget search`：検索用語から Ensembl ID を見つける
- `gget info`：Ensembl、UniProt、関連 ID のメタデータを取得
- `gget seq`：ヌクレオチドまたはアミノ酸配列を取得
- `gget ref`：参照ゲノムダウンロードリンクを取得
- `gget blast`：素早い BLAST クエリを実行
- `gget blat`：サポートされるゲノムアセンブリに対して配列を位置決め
- `gget muscle`：マルチプル配列アライメントを実行
- `gget diamond`：参照配列に対してローカル配列アライメントを実行
- `gget alphafold` と `gget pdb`：タンパク質構造参照を検査
- `gget enrichr`、`gget opentargets`、`gget archs4`、`gget bgee`、`gget cbio`、`gget cosmic`：エンリッチメント、ターゲット、発現、がん、疾患関連データを探索

すべてのモジュールがすべての Python バージョンや依存関係セットをサポートすると仮定しない。一部のオプション科学的依存関係は、コアパッケージより狭いバージョンサポートを持つ。

## クイック例

遺伝子を見つける：

```bash
gget search -s human brca1 dna repair -o brca1-search.json
```

遺伝子メタデータを取得：

```bash
gget info ENSG00000012048 -o brca1-info.json
```

配列を取得：

```bash
gget seq ENSG00000012048 -o brca1-seq.fa
```

小さな BLAST クエリを実行：

```bash
gget blast "MEEPQSDPSVEPPLSQETFSDLWKLLPEN" -l 10 -o blast-results.json
```

Python の例：

```python
import gget

genes = gget.search(["BRCA1", "DNA repair"], species="human")
info = gget.info(["ENSG00000012048"])
sequence = gget.seq("ENSG00000012048")
```

## 再現性ログ

科学的出力には、クエリをリプレイするに十分なメタデータを含める。

```markdown
| Date | gget version | Module | Query | Species/assembly | Output | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-05-11 | `gget --version` | search | `BRCA1 DNA repair` | human | `brca1-search.json` | Docs checked before run |
```

以下も記録する：

- Python バージョンと環境マネージャ
- `gget setup` でインストールされたオプション依存関係
- クエリが返したデータベース固有識別子
- 出力が JSON、CSV、FASTA、または DataFrame エクスポートか
- `gget` のアップグレードで解決された任意の失敗

## レビューチェックリスト

- `gget` のインストール済みバージョンをアップグレードまたは検証したか？
- 引数を使う前に現在の上流モジュールドキュメントをチェックしたか？
- 種またはアセンブリは明示的か？
- 識別子は Ensembl/UniProt プレフィックスを含めて正確に保存されているか？
- 結果は臨床解釈ではなくデータベース出力としてラベル付けされているか？
- 保存されたコマンドまたは Python スニペットからクエリを再現できるか？
- オプション依存関係は分離された環境にインストールされているか？

## 参照

- [gget documentation](https://pachterlab.github.io/gget/)
- [gget updates](https://pachterlab.github.io/gget/en/updates.html)
- [gget GitHub repository](https://github.com/pachterlab/gget)
- [gget Bioinformatics paper](https://doi.org/10.1093/bioinformatics/btac836)
