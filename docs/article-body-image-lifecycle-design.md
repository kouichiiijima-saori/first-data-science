# 記事本文画像のライフサイクル調査・削除方針設計書

本ドキュメントは、「はじめてのデータサイエンス」における Active Storage を用いた記事本文画像（`body_images`）のライフサイクル調査結果、および今後の安全なクリーンアップ実装（Task 8）に向けた削除方針と設計をまとめた技術仕様書です。

---

## 1. 概要と背景

本システムでは、リッチテキスト（Jodit）または Markdown 記事の本文内に挿入する画像を Active Storage (`has_many_attached :body_images`) で管理しています。

画像ファイルの物理削除やDBの未参照レコード（Orphan Data）に関しては、安全性を最優先とするため、**「HTMLから消えただけで即座に物理ファイルを削除しない」「トランザクション内で外部ストレージ削除を行わない」** という原則の下で運用・設計されます。

---

## 2. 現状の挙動（調査結果）

| ケース | 操作・状況 | DB (`articles` / `attachments`) | DB (`blobs`) | ストレージ実ファイル | 現状の挙動 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. 本文から画像だけ削除** | エディタ上で `<img>` を削除して記事更新 | 本文HTMLから `<img>` 消去。<br>`attachments` は保持 | 保持 | 保持 | 本文から削除しても `attachments` および `blobs` / 実ファイルは自動消去されず残る。 |
| **2. 記事自体を削除** | 記事削除 (`Article#destroy`) | `Article` および `attachments` 削除 | 削除 (`purge_later`) | 削除 (`purge_later`) | `dependent: :purge_later` により非同期ジョブで `blobs` および実ファイルが物理削除される。 |
| **3. 保存前に離脱** | 画像アップロード後にフォームを保存せず閉鎖 | `Article` / `attachments` なし (`unattached`) | 保持 | 保持 | `ActiveStorage::Blob.unattached` レコードおよび実ファイルが永続的に残る。 |
| **4. Validation 失敗** | 入力エラー等で保存失敗 | 未保存 | 保持 (`signed_id` フォーム保持) | 保持 | `signed_id` がフォームで保持され、修正後の再送信で正常に `attach` される。 |

---

## 3. 重要設計方針・原則

1. **即時 purge の拒否**
   - 本文 HTML から `<img ...>` が削除されたという理由だけで、同トランザクション内または即座に `blob.purge` を実行しません。
2. **共有・参照の保護**
   - 複数記事や他アタッチメントから同一 Blob が参照される可能性を考慮し、`blob.attachments.count == 0`（完全未参照）であることを確認するまで Blob 本体は削除しません。
3. **トランザクションと物理削除の境界分離**
   - DB トランザクション内で外部ストレージ（S3 / ディスク）の物理ファイル削除を行いません。ストレージ削除の遅延やネットワークエラーが記事の保存・更新トランザクションを失敗させない設計とします。
4. **Validation 失敗時・編集中の保護**
   - 保存処理中やバリデーション失敗で画面を再描写している最中の Blob、および編集開始直後の Blob を誤って削除しないように保護します。
5. **未保存 Orphan Blob に対する猶予時間の設定**
   - 未保存画像（`unattached` な Blob）に対しては、最低 `24時間`（運用上推奨は `7日間`）の猶予時間を設け、作成直後の未保存画像を誤削除しない設計とします。

---

## 4. クリーンアップ・削除設計（Task 8 実装仕様）

### A. 本文から削除された画像（`Article` 更新時）
- **検知ロジック**:
  - 記事更新（`Article#update`）時、送信された本文 HTML (`body`) 内の Active Storage Signed Route URL から使用中 Blob ID 群を抽出。
  - `@article.body_images` にアタッチされている Blob ID 群との差分を算出。
- **detach 処理**:
  - 本文 HTML 内で参照されなくなった Blob の Attachment を `detach`（DBの関連付け解除）します。
- **purge 処理 (Job)**:
  - `detach` された Blob について、他記事や他 Attachment からの参照の有無（`blob.attachments.count == 0`）を検証。
  - 完全未参照となった Blob に限り、バックグラウンドジョブ経由で安全に `purge_later` を呼び出し、物理ファイルと `blobs` レコードをクリーンアップします。

### B. 記事削除時（`Article#destroy`）
- **標準機能の維持**:
  - `Article` モデルに定義されている `has_one_attached :thumbnail` および `has_many_attached :body_images, dependent: :purge_later` を継続利用。
- **ジョブ実行**:
  - `Article` が DB から削除された後、ActiveJob (`SolidQueue` 等) がバックグラウンドで `ActiveStorage::PurgeJob` を実行し、アタッチされていた Blob および実ファイルを安全に削除します。

### C. 未保存 Orphan Blob（保存前離脱画像）の定期クリーンアップ
- **対象指定**:
  - `ActiveStorage::Blob.unattached` の中から、`created_at < 24.hours.ago`（または `7.days.ago`）の条件を満たす Blob のみを抽出。
- **定期ジョブ (Cron / Recurring Job)**:
  - 日次または週次のバックグラウンドタスク（例: Rake task / SolidQueue recurring job）として実行。
  - 他のどのテーブル・アタッチメントからも参照されていないことを最終確認して `purge` 実行。

### D. 監査・運用・ログ仕様
- **Dry-run モード**:
  - ジョブや Rake タスク実行時、`DRY_RUN=true` を指定することで、実際の削除を行わずに削除対象の件数および合計バイト数をログ出力可能とします。
- **ログ出力**:
  - クリーンアップ実行時、削除した Blob 件数、ファイル名、解放されたストレージ容量（Bytes）を構造化ログとして記録します。

---

## 5. 既存ドキュメントへの反映

- `docs/jodit-rich-text-editor-design.md`: ライフサイクル設計と Task 8 でのクリーンアップ方針を追記。
- `docs/article-editor-user-guide.md`: 「保存前の未保存画像」「本文から削除した画像の物理削除」に関する運用注意事項の記載と整合。
- `docs/delivery-checklist.md`: クリーンアップ実装完了を明記。

---

## 6. Task 8 実装結果

### A. 本文削除画像の同期 (`ArticleBodyImageSynchronizer`)
- **同期実行タイミング**:
  - `Admin::ArticlesController` での Article 保存・更新トランザクション成功後に同期サービス `ArticleBodyImageSynchronizer.call(@article)` を実行。
  - バリデーション失敗時や Markdown 記事更新時には実行されません。
- **detach & purge 条件**:
  - 保存された本文 HTML 内の Active Storage Blob ID 群を `Nokogiri::HTML5.fragment` で抽出。
  - `body_images` アタッチメントのうち、本文 HTML 内に存在しないものを detach。
  - detach 後に `ActiveStorage::Attachment.where(blob_id: blob_id).exists?` で他アタッチメント（他記事やアイキャッチなど）からの完全未参照を確認し、完全未参照の場合のみ `blob.purge_later` で非同期物理削除をエンキュー。

### B. 記事削除時
- `has_many_attached :body_images, dependent: :purge_later` の既存動作を維持。

### C. 未保存 Orphan Blob クリーンアップ (`OrphanActiveStorageBlobCleanup`)
- **対象**: `ActiveStorage::Blob.unattached` かつ `created_at < cutoff_time`（既定 7 日前）。
- **安全保護ルール**:
  - `ORPHAN_AGE_DAYS` 環境変数で指定された日数が 1 未満または不正値の場合、自動的に安全な既定値 `7日`（168時間）にフォールバック。
  - 削除実行直前にも `blob.attachments.exists?` を再確認し、race condition で attach された Blob はスキップ。
  - `DRY_RUN=true` では実際の purge を行わず、対象件数・対象容量・Blob ID をコンソールおよびログへ出力。
- **Rake コマンド**:
  ```bash
  # 既定（7日前 unattached 物理削除）
  bin/rails article_body_images:cleanup_orphans

  # Dry-run モード（削除を行わず確認のみ）
  DRY_RUN=true bin/rails article_body_images:cleanup_orphans

  # 猶予日数の指定（例: 14日前）
  ORPHAN_AGE_DAYS=14 bin/rails article_body_images:cleanup_orphans
  ```

### D. Concurrency / 誤削除対策
- DB トランザクション内で外部ストレージ削除を行わない設計。
- 物理削除はすべて ActiveJob 経由の `purge_later` で非同期処理。
- 個人情報保護のため、ログへは Blob ID、件数、容量のみを出力し、元ファイル名の大規模出力は抑制。
- production 定期実行（Cron / Solid Queue recurring job）は本環境構成未決定のため未設定。運用コマンドとして本 Rake タスクを完備。
