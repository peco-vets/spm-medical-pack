---
name: nutrient-document-processing
description: Nutrient DWS API を使ってドキュメントを処理、変換、OCR、抽出、リダクション、署名、フィルする。PDF、DOCX、XLSX、PPTX、HTML、画像と連携する (Process, convert, OCR, extract, redact, sign, fill documents using Nutrient DWS API; works with PDFs, DOCX, XLSX, PPTX, HTML, images)。
origin: ECC
---

# Nutrient ドキュメント処理

> **注:** このスキルは Nutrient 商用 API と統合する。使用前に利用規約を確認すること。

[Nutrient DWS Processor API](https://www.nutrient.io/api/) でドキュメントを処理する。フォーマット変換、テキストとテーブルの抽出、スキャンドキュメントの OCR、PII のリダクション、ウォーターマーク追加、デジタル署名、PDF フォームのフィル。

## セットアップ

**[nutrient.io](https://dashboard.nutrient.io/sign_up/?product=processor)** で無料 API キーを取得

```bash
export NUTRIENT_API_KEY="pdf_live_..."
```

すべてのリクエストは `instructions` JSON フィールドを持つマルチパート POST として `https://api.nutrient.io/build` に送信される。

## 操作

### ドキュメント変換

```bash
# DOCX to PDF
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "document.docx=@document.docx" \
  -F 'instructions={"parts":[{"file":"document.docx"}]}' \
  -o output.pdf

# PDF to DOCX
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "document.pdf=@document.pdf" \
  -F 'instructions={"parts":[{"file":"document.pdf"}],"output":{"type":"docx"}}' \
  -o output.docx

# HTML to PDF
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "index.html=@index.html" \
  -F 'instructions={"parts":[{"html":"index.html"}]}' \
  -o output.pdf
```

サポートされる入力: PDF、DOCX、XLSX、PPTX、DOC、XLS、PPT、PPS、PPSX、ODT、RTF、HTML、JPG、PNG、TIFF、HEIC、GIF、WebP、SVG、TGA、EPS。

### テキストとデータの抽出

```bash
# Extract plain text
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "document.pdf=@document.pdf" \
  -F 'instructions={"parts":[{"file":"document.pdf"}],"output":{"type":"text"}}' \
  -o output.txt

# Extract tables as Excel
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "document.pdf=@document.pdf" \
  -F 'instructions={"parts":[{"file":"document.pdf"}],"output":{"type":"xlsx"}}' \
  -o tables.xlsx
```

### スキャンドキュメントの OCR

```bash
# OCR to searchable PDF (supports 100+ languages)
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "scanned.pdf=@scanned.pdf" \
  -F 'instructions={"parts":[{"file":"scanned.pdf"}],"actions":[{"type":"ocr","language":"english"}]}' \
  -o searchable.pdf
```

言語: ISO 639-2 コード (例: `eng`、`deu`、`fra`、`spa`、`jpn`、`kor`、`chi_sim`、`chi_tra`、`ara`、`hin`、`rus`) 経由で 100 以上の言語をサポート。`english` や `german` などのフル言語名も動作する。サポートされるすべてのコードについては [完全な OCR 言語表](https://www.nutrient.io/guides/document-engine/ocr/language-support/) を参照。

### 機密情報のリダクション

```bash
# Pattern-based (SSN, email)
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "document.pdf=@document.pdf" \
  -F 'instructions={"parts":[{"file":"document.pdf"}],"actions":[{"type":"redaction","strategy":"preset","strategyOptions":{"preset":"social-security-number"}},{"type":"redaction","strategy":"preset","strategyOptions":{"preset":"email-address"}}]}' \
  -o redacted.pdf

# Regex-based
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "document.pdf=@document.pdf" \
  -F 'instructions={"parts":[{"file":"document.pdf"}],"actions":[{"type":"redaction","strategy":"regex","strategyOptions":{"regex":"\\b[A-Z]{2}\\d{6}\\b"}}]}' \
  -o redacted.pdf
```

プリセット: `social-security-number`、`email-address`、`credit-card-number`、`international-phone-number`、`north-american-phone-number`、`date`、`time`、`url`、`ipv4`、`ipv6`、`mac-address`、`us-zip-code`、`vin`。

### ウォーターマークの追加

```bash
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "document.pdf=@document.pdf" \
  -F 'instructions={"parts":[{"file":"document.pdf"}],"actions":[{"type":"watermark","text":"CONFIDENTIAL","fontSize":72,"opacity":0.3,"rotation":-45}]}' \
  -o watermarked.pdf
```

### デジタル署名

```bash
# Self-signed CMS signature
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "document.pdf=@document.pdf" \
  -F 'instructions={"parts":[{"file":"document.pdf"}],"actions":[{"type":"sign","signatureType":"cms"}]}' \
  -o signed.pdf
```

### PDF フォームのフィル

```bash
curl -X POST https://api.nutrient.io/build \
  -H "Authorization: Bearer $NUTRIENT_API_KEY" \
  -F "form.pdf=@form.pdf" \
  -F 'instructions={"parts":[{"file":"form.pdf"}],"actions":[{"type":"fillForm","formFields":{"name":"Jane Smith","email":"jane@example.com","date":"2026-02-06"}}]}' \
  -o filled.pdf
```

## MCP サーバー (代替)

ネイティブツール統合の場合、curl の代わりに MCP サーバーを使う:

```json
{
  "mcpServers": {
    "nutrient-dws": {
      "command": "npx",
      "args": ["-y", "@nutrient-sdk/dws-mcp-server"],
      "env": {
        "NUTRIENT_DWS_API_KEY": "YOUR_API_KEY",
        "SANDBOX_PATH": "/path/to/working/directory"
      }
    }
  }
}
```

## 使用するタイミング

- フォーマット間のドキュメント変換 (PDF、DOCX、XLSX、PPTX、HTML、画像)
- PDF からのテキスト、テーブル、またはキー値ペアの抽出
- スキャンドキュメントや画像の OCR
- ドキュメント共有前の PII のリダクション
- ドラフトや機密ドキュメントへのウォーターマーク追加
- 契約書や合意書のデジタル署名
- PDF フォームのプログラム的フィル

## リンク

- [API Playground](https://dashboard.nutrient.io/processor-api/playground/)
- [完全な API ドキュメント](https://www.nutrient.io/guides/dws-processor/)
- [npm MCP サーバー](https://www.npmjs.com/package/@nutrient-sdk/dws-mcp-server)
