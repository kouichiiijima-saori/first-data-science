# はじめてのデータサイエンス

Ruby on Rails 8.1 系で構築した、データサイエンス入門向けの記事管理・公開アプリケーションです。

## 納品基準

- 納品基準日時: 2026/08/13 12:00 JST
- 納品対象: アプリケーション本体、正式記事 seed、記事画像正本、起動・検証ドキュメント
- 納品対象外: Git 履歴、development DB、development storage、tmp/log、秘密情報、ローカル環境固有ファイル

## 主な機能

- 公開記事一覧・記事詳細表示
- 管理画面での記事作成・編集・削除
- `display_order ASC, id ASC` による記事表示順制御
- Markdown 記事と Rich Text / Jodit 記事の併存
- Active Storage によるサムネイル・本文画像管理
- 初期管理者と正式記事 1〜10 の seed 作成

## 動作前提

検証済み環境の目安です。

- OS: Ubuntu 24.04
- Ruby: 3.4.10
- Bundler: 2.6.9
- Rails: 8.1.3.1
- Active Storage: 8.1.3.1
- MySQL: 8.0 系
- json gem: 2.21.2
- ruby-vips: 2.3.0
- libvips: 8.13 以上（Ubuntu 24.04 では 8.15 系を確認）
- Node.js / npm: Rails asset build に必要なバージョン

Ubuntu 24.04 での libvips 導入例:

```bash
sudo apt-get update
apt-cache policy libvips libvips42t64 libvips-tools
sudo apt-get install --no-install-recommends -y libvips42t64 libvips-tools
vips --version
```

## セットアップ

### 1. OS パッケージ

```bash
sudo apt-get update
sudo apt-get install -y build-essential default-libmysqlclient-dev git libvips42t64 libvips-tools
```

### 2. Ruby gem

```bash
bundle install
```

### 3. データベース設定

`config/database.yml` は MySQL を使用します。必要に応じて以下の環境変数を設定してください。

```bash
export FIRST_DATA_SCIENCE_DATABASE_PASSWORD='your_password'
```

MySQL 側に開発用ユーザー・DB 権限を用意します。

```sql
CREATE USER 'first_data_science'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON first_data_science_development.* TO 'first_data_science'@'localhost';
GRANT ALL PRIVILEGES ON first_data_science_test.* TO 'first_data_science'@'localhost';
FLUSH PRIVILEGES;
```

### 4. DB 作成・migration

```bash
bin/rails db:prepare
```

### 5. 初期管理者と正式記事 seed

初期管理者を作成する場合は、以下を設定してから seed を実行します。

```bash
export INITIAL_ADMIN_EMAIL='admin@example.com'
export INITIAL_ADMIN_PASSWORD='change-me'
bin/rails db:seed
```

`db/seeds.rb` は次を作成します。

- 初期管理者（`INITIAL_ADMIN_EMAIL` / `INITIAL_ADMIN_PASSWORD` がある場合）
- 記事 1〜10（DB に記事が存在しない場合のみ）
- 記事 1〜5: Markdown
- 記事 6〜10: Rich Text / Jodit HTML
- `display_order` 1〜10
- published status
- tags
- 記事 1〜5 の thumbnail
- 記事 6〜9 の本文画像

seed は既存記事がある場合、正式記事の再投入を skip します。既存記事を上書きしないため、納品先で記事編集後に誤って seed を再実行しても本文や画像を置換しません。

正式記事本文の正本は `docs/articles/`、seed 用画像正本は `docs/assets/articles/*.png` です。development 環境の Active Storage blob ID、signed_id、URL、secret 依存値は seed に含めません。

## 起動

```bash
bin/rails server
```

公開画面:

- `/`
- `/articles`
- `/articles/:id`

管理画面:

- `/admin`
- `/admin/articles`

## テスト・品質確認

CI 相当の確認:

```bash
bin/rubocop -f github
bin/bundler-audit
bin/rails db:test:prepare test
bin/rails test:system
```

正式 seed の単体確認:

```bash
bin/rails test test/integration/article_seed_test.rb
```

## 納品時の注意

納品 ZIP には以下を含めないでください。

- `.git/`
- `.env` など秘密情報を含むファイル
- `config/master.key`
- credentials の復号鍵や本番秘密情報
- development / test DB ダンプ
- development / test の `storage/`
- `tmp/`
- `log/`
- CI やローカル実行の一時生成物

顧客環境では、空 DB から migration と seed を実行し、Git 管理された正式記事・正式画像だけで再構築する方式を推奨します。

## 関連ドキュメント

- 納品チェックリスト: `docs/delivery-checklist.md`
- 記事本文正本: `docs/articles/`
- 記事画像正本: `docs/assets/articles/`
