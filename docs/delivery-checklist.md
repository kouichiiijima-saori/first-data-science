# 納品前チェックリスト

本ドキュメントは、「はじめてのデータサイエンス」記事編集機能（Task 1〜6）の納品および運用移管に向けた動作・環境・動作確認項目の最終チェックリストです。

---

## 1. 動作環境・バージョン情報

| 項目 | 動作仕様 / バージョン | 確認結果 |
| :--- | :--- | :---: |
| OS | Ubuntu 24.04 (WSL2 / Linux) | ✅ |
| Ruby | 3.4.10 | ✅ |
| Rails | 8.1.3 | ✅ |
| MySQL | 8.0.46 | ✅ |
| Bundler | 2.6.9 | ✅ |
| Jodit | 4.8.10 (Vendor管理: `vendor/javascript/jodit/`) | ✅ |

---

## 2. セットアップ・コマンド検証

| 検証コマンド / 手順 | 概要 | 結果 |
| :--- | :--- | :---: |
| `bin/setup --skip-server` | 依存関係およびDBの初期化 | ✅ PASSED |
| `bin/rails db:prepare` | マイグレーション適用 | ✅ PASSED |
| `bin/rails db:seed` | 初期管理者ユーザーの安全登録 | ✅ PASSED |
| `bin/rails test` | 単体・結合テスト全件実行 (236 runs) | ✅ 0 Failures |
| `bin/rails test:system` | システムテスト（ブラウザ統合テスト）全件実行 (31 runs) | ✅ 0 Failures |
| `bin/rails zeitwerk:check` | Zeitwerkオートロード定義の検証 | ✅ ALL CLEAR |
| `bin/rubocop` | Rubyコードスタイル検証 | ✅ 0 Offenses |
| `bin/brakeman --quiet --no-pager` | 静的セキュリティ診断 | ✅ 0 Warnings |
| `bin/bundler-audit` | Gem依存関係脆弱性診断 | ✅ 0 Vulnerabilities |
| `bin/importmap audit` | JavaScript依存関係脆弱性診断 | ✅ 0 Vulnerabilities |
| `bin/ci` | 一括CIパイプライン実行 | ✅ SUCCESS |
| `RAILS_ENV=production assets:precompile` | 本番用アセットビルド検証 | ✅ SUCCESS |
| `git diff --check` | 空白行・コンフリクトマーカーチェック | ✅ CLEARED |

---

## 3. 機能要件・動作確認チェックリスト

### 3.1 記事管理・エディタ機能
- [x] **Markdown記事編集**: Markdown文章の入力、Preview実行、エディタ初期化なし
- [x] **リッチテキスト記事編集**: Joditエディタ初期化、見出し(H2-H4)、段落、太字、斜体、下線、文字色(6色)、文字サイズ(4種)、リンク設定
- [x] **編集方式の固定**: 保存済み記事での `editor_type` 変更不可の防御策
- [x] **本文画像挿入・リサイズ**: Active Storage Blob 挿入、表示 `width`/`height` 設定、ドラッグリサイズ、再編集復元
- [x] **サムネイル設定**: 記事サムネイルの登録・変更・表示

### 3.2 セキュリティ・HTML Sanitizer
- [x] **XSS対策**: `script`, `iframe`, `object`, `svg`, `event handler (on*)` の全除去
- [x] **リンク保護**: `javascript:`, `data:` 等の不正スキーマ除去、`target="_blank"` 時の `rel="noopener noreferrer"` 強制
- [x] **画像セキュリティ**: 他記事の Blob 画像および非許可外部画像・Base64・SVG の排除
- [x] **認証・認可**: 非ログインユーザーの `/admin` アクセス拒否、CSRF トークン検証

### 3.3 表示・レスポンシブ性
- [x] **PC / Tablet / Mobile (390px)**: 管理画面および一般公開画面での崩れ防止、`max-width: 100%`, `overflow-wrap: anywhere` 適用
- [x] **下書き制御**: `draft` 記事の一般公開非表示 (404)

---

## 4. バックアップ対象・環境設定・未対応事項

### 4.1 バックアップ対象データ
- DB（MySQL）: `articles`, `tags`, `article_tags`, `admins`, `active_storage_blobs`, `active_storage_attachments`
- ストレージ（Active Storage）: `storage/` ディレクトリ配下のファイル群

### 4.2 本番構築・環境変数
- `INITIAL_ADMIN_EMAIL`, `INITIAL_ADMIN_PASSWORD`: 初回 seed 時の管理者アカウント生成用
- `SECRET_KEY_BASE`: Rails暗号化キー

### 4.3 現時点の未対応事項（将来の運用保守課題）
1. **Production Storage**: 現在はローカルディスクストレージ設定。本番インフラ構築時にS3等の外部ストレージ決定が必要。
2. **Orphan Blob / 本文削除画像 Cleanup**: `ArticleBodyImageSynchronizer`（本文削除画像の detach & purge）および `OrphanActiveStorageBlobCleanup` / `bin/rails article_body_images:cleanup_orphans`（未保存 Orphan Blob 7日後 safe purge & dry-run）が実装済み。
3. **画像編集機能**: トリミング、回転、反転、画像自体の物理的圧縮・リサイズは本Scope外。

---

## 5. 納品・Gitステータス

- **Git Status**: `working tree clean`
- **Push指定**: ローカル環境にて検証完了（リモートへの push は指示に基づき非実施）
