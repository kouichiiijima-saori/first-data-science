# はじめてのデータサイエンス

Ruby on Rails と MySQL で動作する、データサイエンス初心者向け学習サイトです。
管理者はログイン後にMarkdown形式の記事を作成・編集・削除できます。一般利用者は公開済みの記事だけを閲覧できます。

## 基本環境

主な動作確認環境は次の通りです。

- Windows 11 + WSL2 + Ubuntu 24.04
- Ruby 3.4.10
- Rails 8.1.3
- Bundler 2.6.9
- MySQL 8.0.46
- Puma 8.0.2

## 初期管理者の作成

このアプリには管理者登録用の公開画面はありません。初期管理者は `db/seeds.rb` から作成します。

`db/seeds.rb` は次の環境変数を読み取ります。

- `INITIAL_ADMIN_EMAIL`: 初期管理者のメールアドレス
- `INITIAL_ADMIN_PASSWORD`: 初期管理者のパスワード

メールアドレスとパスワードの実値をREADME、Git管理対象、ソースコードへ記載しないでください。`.env` やcredentials等を利用する場合は、実値をGitへcommitせず、納品先の秘密情報管理方針に従ってください。パスワードは `has_secure_password` により `password_digest` へハッシュ化して保存され、平文では保存されません。

### WSL Ubuntu Terminalでの実行例

Windows PowerShellから作業する場合は、まずUbuntuへ入ります。

```powershell
wsl -d Ubuntu-24.04
```

Ubuntu Terminalで、アプリを配置したディレクトリへ移動してください。次の `/path/to/first-data-science` は例のため、実際の配置先へ読み替えてください。その後、メールアドレスとパスワードを入力してseedを実行します。`read -s` を使うことで、パスワードを画面へ表示しません。

```bash
cd /path/to/first-data-science

read -r -p "管理者メールアドレス: " INITIAL_ADMIN_EMAIL
read -r -s -p "管理者パスワード: " INITIAL_ADMIN_PASSWORD
echo

INITIAL_ADMIN_EMAIL="$INITIAL_ADMIN_EMAIL" \
INITIAL_ADMIN_PASSWORD="$INITIAL_ADMIN_PASSWORD" \
bin/rails db:seed

unset INITIAL_ADMIN_EMAIL INITIAL_ADMIN_PASSWORD
```

この例では、シェル履歴に実際のパスワード値が残りにくい形で一時環境変数を渡します。seed実行後は `unset` で平文パスワードを環境変数から削除してください。

### 再実行時の挙動

同じメールアドレスで `bin/rails db:seed` を複数回実行しても、管理者は重複作成されません。既存管理者がいる場合、seedは既存の `password_digest` と `updated_at` を変更せずにスキップします。

環境変数が未設定の場合、development/test環境では初期管理者作成をスキップします。production環境では、管理者が1件も存在しない場合に限り、環境変数未設定を明確なエラーとして扱います。

## テスト

通常のテストは次で実行します。

```bash
bin/rails test
bin/rails test:system
```

CI相当の検証は次で実行します。

```bash
bin/ci
```
