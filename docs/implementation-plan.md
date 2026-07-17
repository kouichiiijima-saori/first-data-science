# 実装計画

## 前提

- 正本は `docs/requirements.md` とする。
- 開発期間は4週間、想定作業時間は80〜100時間、1週間あたり20〜25時間とする。
- 今回は設計資料のみを作成し、Rails初期化、Gem追加、Migration、Rubyコード、ERB、CSS、JavaScriptの実装は行わない。
- 実装順は「まず動く最小構成を完成させ、その後に装飾や改善を加える」構成とする。
- CodexとAntigravityが同じStepで同じファイルを同時編集しないよう、Backend/DB/認証とFrontend/表示調整を分ける。

## 役割分担

| 役割 | 担当 |
| --- | --- |
| ChatGPT | 要件・設計方針・進行管理・レビュー・次Task決定 |
| Codex | 設計、Rails Backend、DB、認証、テスト、コードレビュー |
| Antigravity | ERB、CSS、レスポンシブ、ブラウザ確認、表示修正 |
| ユーザー | 最終判断、実行、ブラウザ確認、push、CI確認 |

## 4週間の進め方

- Week 1: 要件・設計確定、開発環境確認、Railsプロジェクト初期化、MySQL接続、Article CRUD Backend、基本画面
- Week 2: 管理者認証、管理画面、タグ、Action Text、Active Storage
- Week 3: 一般向け画面、デザイン、レスポンシブ、記事作成
- Week 4: テスト、不具合修正、セキュリティ確認、README、納品準備

## Step一覧

| Step ID | Week | Step名 | 主担当 | 想定時間 | 依存関係 |
| --- | --- | --- | --- | --- | --- |
| W1-01 | Week 1 | 要件・設計確定 | ChatGPT / Codex / ユーザー | 4h | なし |
| W1-02 | Week 1 | 開発環境確認 | Codex / ユーザー | 3h | W1-01 |
| W1-03 | Week 1 | Railsプロジェクト初期化 | Codex / ユーザー | 4h | W1-02 |
| W1-04 | Week 1 | MySQL接続確認 | Codex / ユーザー | 4h | W1-03 |
| W1-05 | Week 1 | Article CRUD Backend | Codex | 7h | W1-04 |
| W1-06 | Week 1 | 基本画面の骨組み | Antigravity | 4h | W1-05 |
| W2-01 | Week 2 | 管理者認証 | Codex | 6h | W1-05 |
| W2-02 | Week 2 | 管理画面 | Codex / Antigravity | 5h | W2-01 |
| W2-03 | Week 2 | タグ機能 | Codex | 5h | W1-05 |
| W2-04 | Week 2 | Action Text導入 | Codex | 5h | W1-05 |
| W2-05 | Week 2 | Active Storage導入 | Codex | 4h | W2-04 |
| W3-01 | Week 3 | 一般向け画面 | Antigravity | 6h | W2-03, W2-05 |
| W3-02 | Week 3 | デザイン調整 | Antigravity | 5h | W3-01 |
| W3-03 | Week 3 | レスポンシブ対応 | Antigravity | 5h | W3-02 |
| W3-04 | Week 3 | 記事作成・登録 | ユーザー / Antigravity | 8h | W2-05 |
| W4-01 | Week 4 | テスト | Codex | 6h | W3-03 |
| W4-02 | Week 4 | 不具合修正 | Codex / Antigravity | 6h | W4-01 |
| W4-03 | Week 4 | セキュリティ確認 | Codex | 4h | W4-02 |
| W4-04 | Week 4 | README整備 | Codex / ユーザー | 4h | W4-02 |
| W4-05 | Week 4 | 納品準備・最終確認 | ChatGPT / Codex / Antigravity / ユーザー | 5h | W4-03, W4-04 |

想定合計: 100時間

## 各Step詳細

### W1-01 要件・設計確定

| 項目 | 内容 |
| --- | --- |
| 主担当 | ChatGPT / Codex / ユーザー |
| 目的 | 要件、画面、DB、実装順を確定する |
| 前提 | `docs/requirements.md` が正本として存在する |
| 成果物 | 画面一覧、画面遷移、DB設計、実装計画 |
| 完了条件 | ユーザーがMVP方針、URL、table構成、Action Text/Active Storage採用を確認済み |
| 想定時間 | 4h |
| 依存関係 | なし |
| リスク | 文字装飾要件の厳密さにより追加実装が増える |
| CodexまたはAntigravityの担当 | Codexが設計資料を作成。Antigravityはまだ実装しない |

### W1-02 開発環境確認

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex / ユーザー |
| 目的 | Ruby、Rails、MySQL、Node系ツールの利用可否を確認する |
| 前提 | 設計方針が確定している |
| 成果物 | 環境確認メモ、バージョン情報 |
| 完了条件 | RailsとMySQLで開発開始できる状態を確認する |
| 想定時間 | 3h |
| 依存関係 | W1-01 |
| リスク | ローカル環境差異により初期化が遅れる |
| CodexまたはAntigravityの担当 | Codexが確認コマンドと手順を整理。ユーザーが必要な実行を判断 |

### W1-03 Railsプロジェクト初期化

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex / ユーザー |
| 目的 | Railsアプリケーションの土台を作る |
| 前提 | 開発環境が確認済み |
| 成果物 | Railsプロジェクト一式 |
| 完了条件 | Railsアプリが起動できる |
| 想定時間 | 4h |
| 依存関係 | W1-02 |
| リスク | Railsバージョン、MySQLアダプタ、既存ディレクトリ構成の調整が必要になる |
| CodexまたはAntigravityの担当 | Codexが初期化方針を担当。Antigravityはまだ画面調整しない |

### W1-04 MySQL接続確認

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex / ユーザー |
| 目的 | RailsからMySQLへ接続できる状態にする |
| 前提 | Railsプロジェクトが初期化済み |
| 成果物 | DB接続設定、DB作成、接続確認結果 |
| 完了条件 | RailsからMySQLへの接続とDB作成が成功する |
| 想定時間 | 4h |
| 依存関係 | W1-03 |
| リスク | MySQLユーザー、パスワード、権限設定で詰まる可能性 |
| CodexまたはAntigravityの担当 | CodexがDB設定を担当 |

### W1-05 Article CRUD Backend

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex |
| 目的 | 記事の作成・一覧・更新・削除のBackendを作る |
| 前提 | MySQL接続が完了している |
| 成果物 | Article Model、Migration、Controller、基本Validation |
| 完了条件 | 管理者用の記事CRUDがBackendとして動作する |
| 想定時間 | 7h |
| 依存関係 | W1-04 |
| リスク | Action Text導入前後で本文column設計を間違える可能性 |
| CodexまたはAntigravityの担当 | CodexがDB、Model、Controller、テストを担当 |

### W1-06 基本画面の骨組み

| 項目 | 内容 |
| --- | --- |
| 主担当 | Antigravity |
| 目的 | CRUD確認に必要な最小限のERB画面を作る |
| 前提 | Article CRUD Backendが動作している |
| 成果物 | 管理記事一覧、新規作成、編集の最小View |
| 完了条件 | ブラウザから記事の作成・編集・削除を確認できる |
| 想定時間 | 4h |
| 依存関係 | W1-05 |
| リスク | 見た目調整に時間を使いすぎる |
| CodexまたはAntigravityの担当 | AntigravityがERBを担当。Codexは同じViewを同時編集しない |

### W2-01 管理者認証

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex |
| 目的 | 管理者ログイン、ログアウト、アクセス制御を実装する |
| 前提 | Article CRUDの土台がある |
| 成果物 | Admin Model、Session Controller、認証フィルタ、seed管理者 |
| 完了条件 | 未ログインでは管理画面へ入れず、ログイン後に管理画面を使える |
| 想定時間 | 6h |
| 依存関係 | W1-05 |
| リスク | パスワードハッシュ化、セッション管理、seed情報管理の漏れ |
| CodexまたはAntigravityの担当 | Codexが認証とBackendを担当 |

### W2-02 管理画面

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex / Antigravity |
| 目的 | 管理者が迷わず記事管理できる画面を整える |
| 前提 | 管理者認証が動作している |
| 成果物 | 管理画面トップ、記事管理導線、ログアウト導線 |
| 完了条件 | ログイン後に管理画面トップから記事管理へ移動できる |
| 想定時間 | 5h |
| 依存関係 | W2-01 |
| リスク | CodexとAntigravityの同時編集競合 |
| CodexまたはAntigravityの担当 | CodexがController/route、AntigravityがERB/CSS。作業順はCodex完了後にAntigravity |

### W2-03 タグ機能

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex |
| 目的 | 記事に複数タグを設定・表示できるようにする |
| 前提 | Article CRUDが動作している |
| 成果物 | Tag Model、ArticleTag Model、カンマ区切り入力処理、Validation |
| 完了条件 | 管理画面でカンマ区切りタグを保存でき、一般画面でタグ表示できる |
| 想定時間 | 5h |
| 依存関係 | W1-05 |
| リスク | 重複タグ、空タグ、全角カンマの扱い |
| CodexまたはAntigravityの担当 | CodexがDBと保存処理を担当。Antigravityは表示調整のみ |

### W2-04 Action Text導入

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex |
| 目的 | 記事本文をリッチテキストで編集できるようにする |
| 前提 | Article CRUDが動作している |
| 成果物 | Action Text設定、本文入力フォーム、本文表示 |
| 完了条件 | 見出し、段落、リンク、画像挿入の土台が動作する |
| 想定時間 | 5h |
| 依存関係 | W1-05 |
| リスク | Trixへの最小CSS・JavaScript拡張で文字色、文字サイズ、下線、画像サイズプリセットを実現する必要がある |
| CodexまたはAntigravityの担当 | Codexが導入とBackend確認を担当 |

### W2-05 Active Storage導入

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex |
| 目的 | 一覧用画像と本文内画像を扱えるようにする |
| 前提 | Action Text導入方針が決まっている |
| 成果物 | Active Storage設定、thumbnail添付、画像Validation |
| 完了条件 | thumbnailを登録でき、本文内画像を表示できる |
| 想定時間 | 4h |
| 依存関係 | W2-04 |
| リスク | 画像容量、形式制限、保存先設定の確認漏れ |
| CodexまたはAntigravityの担当 | CodexがStorage設定とValidationを担当 |

### W3-01 一般向け画面

| 項目 | 内容 |
| --- | --- |
| 主担当 | Antigravity |
| 目的 | 一般利用者がトップ、記事一覧、記事詳細を閲覧できるようにする |
| 前提 | 記事、タグ、画像、本文がBackendで扱える |
| 成果物 | トップページ、記事一覧、記事詳細のERB |
| 完了条件 | 公開記事のみ一般画面に表示され、投稿日は表示されない |
| 想定時間 | 6h |
| 依存関係 | W2-03, W2-05 |
| リスク | 投稿日非表示、非公開記事除外の漏れ |
| CodexまたはAntigravityの担当 | AntigravityがERBを担当。Codexは表示条件レビュー |

### W3-02 デザイン調整

| 項目 | 内容 |
| --- | --- |
| 主担当 | Antigravity |
| 目的 | 初心者向け学習サイトとして読みやすい見た目にする |
| 前提 | 一般向け画面が表示できる |
| 成果物 | CSS、レイアウト、ボタン、記事カードの調整 |
| 完了条件 | PCでトップ、一覧、詳細、管理画面が大きく崩れない |
| 想定時間 | 5h |
| 依存関係 | W3-01 |
| リスク | 装飾過多によりMVPの時間を圧迫する |
| CodexまたはAntigravityの担当 | AntigravityがCSS/ERBを担当 |

### W3-03 レスポンシブ対応

| 項目 | 内容 |
| --- | --- |
| 主担当 | Antigravity |
| 目的 | PC、タブレット、スマートフォンで大きく崩れないようにする |
| 前提 | 基本デザインが決まっている |
| 成果物 | レスポンシブCSS、ブラウザ確認結果 |
| 完了条件 | スマートフォンで文字、画像、メニューが画面外へはみ出さない |
| 想定時間 | 5h |
| 依存関係 | W3-02 |
| リスク | Action Text本文内の画像や装飾が崩れる |
| CodexまたはAntigravityの担当 | Antigravityが表示修正、Codexは必要に応じてレビュー |

### W3-04 記事作成・登録

| 項目 | 内容 |
| --- | --- |
| 主担当 | ユーザー / Antigravity |
| 目的 | 最低8記事、目標10記事を登録する |
| 前提 | 管理画面から記事登録できる |
| 成果物 | 400文字以上の記事8〜10本、タグ、画像 |
| 完了条件 | 公開記事が8本以上あり、各記事が400文字以上ある |
| 想定時間 | 8h |
| 依存関係 | W2-05 |
| リスク | 記事本文作成に時間がかかる |
| CodexまたはAntigravityの担当 | Antigravityは表示確認を補助。Codexは文字数や公開状態の確認を補助 |

### W4-01 テスト

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex |
| 目的 | 主要機能が要件どおり動くことを確認する |
| 前提 | 主要画面と機能が実装済み |
| 成果物 | Model/Request/Systemテストまたは手動確認表 |
| 完了条件 | CRUD、認証、公開記事表示、タグ、画像、投稿日非表示を確認済み |
| 想定時間 | 6h |
| 依存関係 | W3-03 |
| リスク | テスト導入に時間がかかる場合、手動確認が増える |
| CodexまたはAntigravityの担当 | Codexがテストとレビューを担当 |

### W4-02 不具合修正

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex / Antigravity |
| 目的 | テストとブラウザ確認で見つかった不具合を直す |
| 前提 | テスト結果と確認結果がある |
| 成果物 | 不具合修正済みコード |
| 完了条件 | 既知の重大不具合が解消されている |
| 想定時間 | 6h |
| 依存関係 | W4-01 |
| リスク | Backend修正とFrontend修正が同じファイルに集中する |
| CodexまたはAntigravityの担当 | CodexがBackend/DB/認証、AntigravityがERB/CSS。修正対象ファイルを分けて順番に作業 |

### W4-03 セキュリティ確認

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex |
| 目的 | 認証、入力検証、ファイルアップロード、CSRF対策を確認する |
| 前提 | 不具合修正が概ね完了している |
| 成果物 | セキュリティ確認結果 |
| 完了条件 | パスワードハッシュ化、未認証アクセス防止、画像以外の制限を確認済み |
| 想定時間 | 4h |
| 依存関係 | W4-02 |
| リスク | 画像Validationや管理画面アクセス制御の漏れ |
| CodexまたはAntigravityの担当 | Codexが確認と修正を担当 |

### W4-04 README整備

| 項目 | 内容 |
| --- | --- |
| 主担当 | Codex / ユーザー |
| 目的 | 起動方法、初期設定、管理者ログイン情報、提出情報をまとめる |
| 前提 | 実装内容が固まっている |
| 成果物 | README |
| 完了条件 | 第三者が起動方法と管理者ログイン情報を確認できる |
| 想定時間 | 4h |
| 依存関係 | W4-02 |
| リスク | DB作成、seed、画像保存先の説明漏れ |
| CodexまたはAntigravityの担当 | CodexがREADME草案、ユーザーが提出情報を最終確認 |

### W4-05 納品準備・最終確認

| 項目 | 内容 |
| --- | --- |
| 主担当 | ChatGPT / Codex / Antigravity / ユーザー |
| 目的 | 完成条件を満たしているか最終確認する |
| 前提 | テスト、修正、READMEが完了している |
| 成果物 | 最終確認結果、提出物 |
| 完了条件 | 完成条件を満たし、ユーザーがブラウザ確認とpush/CI確認を完了している |
| 想定時間 | 5h |
| 依存関係 | W4-03, W4-04 |
| リスク | 記事数、文字数、投稿日非表示など課題条件の見落とし |
| CodexまたはAntigravityの担当 | Codexが最終チェック、Antigravityが表示崩れ修正、ユーザーが最終判断 |

## 同時編集を避けるための作業順

1. CodexがDB、Model、Controller、route、認証、テストを先に実装する。
2. AntigravityがERB、CSS、レスポンシブ、ブラウザ確認を行う。
3. 表示に必要なBackend修正が見つかった場合は、Antigravityが作業を止め、CodexがBackendを修正する。
4. Codex修正後、Antigravityが表示調整を再開する。
5. 同じERBやCSSをCodexとAntigravityが同時に編集しない。

## MVP完了条件

- 画面数: 9画面
- URL案:
  - `/`
  - `/articles`
  - `/articles/:id`
  - HTTP 404
  - `/admin/login`
  - `/admin`
  - `/admin/articles`
  - `/admin/articles/new`
  - `/admin/articles/:id/edit`
- 認証が必要な画面:
  - `/admin`
  - `/admin/articles`
  - `/admin/articles/new`
  - `/admin/articles/:id/edit`
- DB table案:
  - `admins`
  - `articles`
  - `tags`
  - `article_tags`
  - `action_text_rich_texts`
  - `active_storage_blobs`
  - `active_storage_attachments`
  - `active_storage_variant_records`
- Model関連:
  - `Article has_many :article_tags`
  - `Article has_many :tags, through: :article_tags`
  - `Tag has_many :article_tags`
  - `Tag has_many :articles, through: :article_tags`
  - `Article has_rich_text :body`
  - `Article has_one_attached :thumbnail`
  - `Admin has_secure_password`
- タグ保存方式:
  - 入力UIはカンマ区切り
  - DBは `tags` / `article_tags` に正規化
- 管理者初期作成方式:
  - `db/seeds.rb` による初期管理者作成
  - 管理者登録画面は作らない
  - ログインIDはメールアドレスとし、管理者IDログインは実装しない
- ログイン後遷移:
  - ログイン成功後は常に `/admin`
  - `return_to` 保存は実装しない
- 記事公開状態:
  - `draft` / `published` を持つ
  - 一般画面は `published` のみ表示
- Action Text:
  - 採用
  - 本文は `articles.body` columnではなく `action_text_rich_texts` に保存
  - 別エディタは導入しない
  - Trixへ最小限のCSS・JavaScript拡張を行う
  - 文字色は固定色、文字サイズは小・標準・大などのプリセット、下線ボタンを追加、画像サイズは小・中・大または50%・75%・100%のプリセット
- Active Storage:
  - 採用推奨
  - thumbnailと本文内画像で利用
- 4週間のStep構成:
  - 20 Step、合計100時間想定
- 次に行うTask:
  - 設計レビュー後、Railsプロジェクト初期化とMySQL接続確認

## 要件上の注意点

- 要件に重大な矛盾はない。
- 管理者ログインIDはメールアドレスで確定する。管理者IDログインは実装しない。
- ログイン成功後は常に `/admin` へ遷移し、`return_to` 保存は実装しない。
- 「文字色・文字サイズ・下線・画像サイズの調整」はAction Text標準だけでは不足する可能性があるため、Trixへ最小限のCSS・JavaScript拡張を行う。
- 別エディタ、自由なドラッグリサイズ、無制限カラーピッカーは対象外とする。
- Action Text本文の文字数はHTMLタグを除いたplain textで400文字以上を判定する。
- 404エラーページは画面設計上維持するが、独立ルート `/404` は必須にしない。
- 時間不足時はデザインの細部や404画面の装飾を縮小し、必須機能を優先する。
- 管理者新規登録画面、タグ管理画面、タグ別一覧、全文検索、論理削除はMVPでは対象外とする。

## セルフレビュー項目

- `docs/requirements.md` と矛盾していないこと
- 一般画面に投稿日を表示しないこと
- 記事8ページ以上の条件を含めていること
- 1記事400文字以上の条件を含めていること
- 管理者認証を含めていること
- パスワードハッシュ化を含めていること
- 記事投稿・編集・削除を含めていること
- タグを含めていること
- 画像アップロードと本文埋め込みを含めていること
- 文字装飾要件を含めていること
- レスポンシブ対応を含めていること
- 4週間で実現困難な設計を追加していないこと
- Scope外機能を混ぜていないこと
- Rails標準のMVC・RESTful設計に沿っていること
- MySQLで実現可能であること
- Action TextとActive Storageのtable構成を誤って説明していないこと
- 各資料間で画面名、URL、table名、Step番号が一致していること
