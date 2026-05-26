---
name: peco-ui
description: SPM 全プロジェクトの UI 実装時に必ず使う。フロントエンドのコンポーネント・色・タイポグラフィ・スペーシング・ロゴは必ずこのスキルを参照して実装する。Next.js + Tailwind CSS + peco-ui コンポーネントライブラリ（github.com/ishii-code/peco-ui）を使う全てのプロジェクトに適用。
---

# PECO UI デザインシステム

SPM 全プロジェクト共通の UI ルール。フロントエンドを実装する際は必ずこのスキルを参照すること。

## コンポーネントライブラリ

リポジトリ: https://github.com/ishii-code/peco-ui
パス: src/components/peco/

使用可能なコンポーネント: PecoLogo, PecoButton, PecoCard, PecoHeader, PecoLayout, PecoModal, PecoInput, PecoSelect, PecoBadge, PecoTable, PecoAlert, PecoEmptyState, PecoSpinner, PecoToast

import方法: import { PecoButton, PecoCard, PecoLogo } from "@/components/peco";

## デザイントークン（src/styles/tokens.css）

色は必ずCSS変数を使うこと。直接カラーコードを書かない。

Primary: --peco-primary: #00B5AD / --peco-primary-dark: #009490
Semantic: --peco-success: #27AE60 / --peco-warning: #F39C12 / --peco-danger: #E74C3C / --peco-info: #2980B9
Triage: --peco-triage-green: #27AE60 / --peco-triage-yellow: #F39C12 / --peco-triage-red: #E74C3C
Neutral: --peco-gray-900: #1A1A2E / --peco-gray-500: #6B7280 / --peco-gray-100: #F3F4F6
Font: --peco-font-sans: Noto Sans JP, Inter, sans-serif
Radius: --peco-radius-sm: 6px / --peco-radius-md: 10px / --peco-radius-lg: 16px
Shadow: --peco-shadow-sm / --peco-shadow-md / --peco-shadow-lg

## ロゴ

PecoLogo コンポーネントを使う。色付き背景: color="white" / 白背景: color="primary"
サブタイトル変更可: subtitle="Dev Agent"

## 実装ルール

1. 色は必ずCSS変数を使う（var(--peco-primary)）
2. 既存コンポーネントがあれば必ず使う
3. フォントは Noto Sans JP を第一候補
4. ボタンは --peco-primary を基本色
5. 危険操作は --peco-danger、警告は --peco-warning
6. 医療UIの緊急度は triage カラーを使う

## 新規プロジェクト導入

cp -r ~/workspace/peco-ui/src/components/peco src/components/peco
cp ~/workspace/peco-ui/src/styles/tokens.css src/styles/tokens.css
globals.css に @import ../styles/tokens.css を追加
