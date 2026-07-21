# 実装計画

## 前提

- 正本は `docs/requirements.md` とする。
- 開発期間は4週間、想定作業時間は80時間とする。
- 1日4時間、週5日、週20時間、合計80時間で完成可能なMVPを優先する。
- 今回は設計資料のみを修正し、Rails初期化、Gem追加、Migration、Rubyコード、ERB、CSS、JavaScriptの実装は行わない。
- Ruby on Rails + MySQL + MarkdownによるQiita風学習サイトとして実装する。
- Action Text、Trix、React、Vue、Next.js等は導入しない。
- JavaScriptはMarkdown previewなどの補助機能に限定する。
- Pythonは記事内の学習サンプルとして表示するだけで、Webアプリ本体やブラウザ上では実行しない。
- CodexとAntigravityが同じfileを同時編集しないよう、Backend/DB/Markdown変換とFrontend/表示調整を分ける。

## 役割分担

| 役割 | 担当 |
| --- | --- |
| ChatGPT | 要件・設計方針、進行管理、完了報告レビュー、次Task決定、push判断 |
| Codex | Rails Backend、DB、Model、Controller、認証、Markdown変換、Sanitization、テスト、Security review、docs更新、commit |
| Antigravity | ERB、CSS、レスポンシブ、Markdown表示調整、code block見た目、Preview UI、ブラウザ確認、表示修正、docs更新、commit |
| ユーザー | 最終判断、実行、ブラウザ確認、記事内容確認、push、CI確認 |

## 80時間の週別配分

| Week | 時間 | 主な内容 |
| --- | ---: | --- |
| Week 1 | 20h | 設計確定、開発環境確認、Rails初期化、MySQL接続、Article CRUDの土台 |
| Week 2 | 20h | 管理者認証、タグ、Markdown変換・表示、Active Storage |
| Week 3 | 20h | 一般向け画面、Markdown preview、code block表示、CSS、レスポンシブ |
| Week 4 | 20h | 記事8本作成、テスト、不具合修正、README、納品準備 |
| 合計 | 80h | 4週間MVP |

## 優先順位

### 必須

- Railsで動作
- MySQL接続
- 管理者認証
- 記事CRUD
- `draft` / `published`
- Markdown本文
- Markdown変換・sanitize
- code block
- タグ
- thumbnail
- 本文画像
- 記事8本
- 1記事400文字以上
- レスポンシブ
- README

### 時間不足時に簡略化可能

- real-time preview
- 自動目次
- 文字色の種類
- 画像サイズ選択
- 関連記事
- 404画面の装飾
- 高度なsyntax highlighting

## Step一覧

| Step ID | Week | Step名 | 主担当 | 想定時間 | 依存関係 | 簡略化可能か |
| --- | --- | --- | --- | ---: | --- | --- |
| W1-01 | Week 1 | 要件・設計確定 | ChatGPT / Codex / ユーザー | 3h | なし | 不可 |
| W1-02 | Week 1 | 開発環境確認 | Codex / ユーザー | 3h | W1-01 | 不可 |
| W1-03 | Week 1 | Rails初期化・MySQL接続 | Codex / ユーザー | 5h | W1-02 | 不可 |
| W1-04 | Week 1 | Article CRUD土台 | Codex | 7h | W1-03 | 不可 |
| W1-05 | Week 1 | 管理画面最小View | Antigravity | 2h | W1-04 | 一部可 |
| W2-01 | Week 2 | 管理者認証 | Codex | 5h | W1-04 | 不可 |
| W2-02 | Week 2 | タグ機能 | Codex | 4h | W1-04 | 不可 |
| W2-03 | Week 2 | Markdown変換・sanitize | Codex | 5h | W1-04 | 不可 |
| W2-04 | Week 2 | Active Storage画像 | Codex | 4h | W1-04 | 不可 |
| W2-05 | Week 2 | 管理画面連携調整 | Codex / Antigravity | 2h | W2-01, W2-04 | 一部可 |
| W3-01 | Week 3 | 一般向け画面 | Antigravity | 5h | W2-03, W2-04 | 不可 |
| W3-02 | Week 3 | Markdown preview | Codex / Antigravity | 4h | W2-03 | 一部可 |
| W3-03 | Week 3 | code block表示 | Antigravity | 3h | W3-01 | 一部可 |
| W3-04 | Week 3 | CSS・レスポンシブ | Antigravity | 6h | W3-01 | 不可 |
| W3-05 | Week 3 | 画面表示レビュー | Codex / Antigravity / ユーザー | 2h | W3-04 | 一部可 |
| W4-01 | Week 4 | 記事8本作成・登録 | ユーザー / Antigravity | 6h | W3-02 | 不可 |
| W4-02 | Week 4 | テスト | Codex | 5h | W4-01 | 不可 |
| W4-03 | Week 4 | 不具合修正・Security確認 | Codex / Antigravity | 5h | W4-02 | 不可 |
| W4-04 | Week 4 | README | Codex / ユーザー | 2h | W4-03 | 不可 |
| W4-05 | Week 4 | 納品準備・最終確認 | ChatGPT / Codex / Antigravity / ユーザー | 2h | W4-04 | 不可 |

## 各Step詳細

### W1-01 要件・設計確定

| 項目 | 内容 |
| --- | --- |
| Week | Week 1 |
| 主担当 | ChatGPT / Codex / ユーザー |
| 目的 | Markdown方針、画面、DB、80時間計画を確定する |
| 成果物 | 要件定義、画面一覧、画面遷移、DB設計、実装計画 |
| 完了条件 | ユーザーがMarkdown方針、URL、table構成、80時間MVPを確認済み |
| 想定時間 | 3h |
| 依存関係 | なし |
| リスク | Markdown装飾要件を広げすぎると80時間を超える |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | Codexが設計資料を作成。Antigravityはまだ実装しない |

### W1-02 開発環境確認

| 項目 | 内容 |
| --- | --- |
| Week | Week 1 |
| 主担当 | Codex / ユーザー |
| 目的 | Ruby、Rails、MySQL、Node系ツールの利用可否を確認する |
| 成果物 | 環境確認メモ、バージョン情報 |
| 完了条件 | RailsとMySQLで開発開始できる状態を確認する |
| 想定時間 | 3h |
| 依存関係 | W1-01 |
| リスク | ローカル環境差異により初期化が遅れる |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | Codexが確認コマンドと手順を整理。ユーザーが実行判断 |

### W1-03 Rails初期化・MySQL接続

| 項目 | 内容 |
| --- | --- |
| Week | Week 1 |
| 主担当 | Codex / ユーザー |
| 目的 | Railsアプリケーションの土台を作り、MySQLへ接続する |
| 成果物 | Railsプロジェクト、DB接続設定、DB作成確認 |
| 完了条件 | RailsからMySQLへ接続できる |
| 想定時間 | 5h |
| 依存関係 | W1-02 |
| リスク | MySQL権限やRailsバージョン調整で時間を使う |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | Codexが初期化と接続設定を担当 |

### W1-04 Article CRUD土台

| 項目 | 内容 |
| --- | --- |
| Week | Week 1 |
| 主担当 | Codex |
| 目的 | Markdown本文を持つ記事CRUDのBackend土台を作る |
| 成果物 | Article Model、Migration、Controller、基本Validation |
| 完了条件 | 管理者側で記事の作成・編集・削除のBackendが動く |
| 想定時間 | 7h |
| 依存関係 | W1-03 |
| リスク | `articles.body` の型や400文字判定の実装方針が曖昧になる |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | CodexがDB、Model、Controller、テストを担当 |

### W1-05 管理画面最小View

| 項目 | 内容 |
| --- | --- |
| Week | Week 1 |
| 主担当 | Antigravity |
| 目的 | CRUD確認に必要な最小限のERB画面を作る |
| 成果物 | 管理記事一覧、新規作成、編集の最小View |
| 完了条件 | ブラウザからMarkdown本文を入力して記事保存を確認できる |
| 想定時間 | 2h |
| 依存関係 | W1-04 |
| リスク | 見た目調整に時間を使いすぎる |
| 簡略化可能か | 一部可。装飾は後回し |
| Codex / Antigravityの担当 | AntigravityがERBを担当。Codexは同じViewを同時編集しない |

### W2-01 管理者認証

| 項目 | 内容 |
| --- | --- |
| Week | Week 2 |
| 主担当 | Codex |
| 目的 | 管理者ログイン、ログアウト、アクセス制御を実装する |
| 成果物 | Admin Model、Session Controller、認証フィルタ、seed管理者 |
| 完了条件 | 未ログインでは管理画面へ入れず、ログイン後は常に `/admin` へ移動する |
| 想定時間 | 5h |
| 依存関係 | W1-04 |
| リスク | パスワードハッシュ化、セッション管理、seed情報管理の漏れ |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | Codexが認証とBackendを担当 |

### W2-02 タグ機能

| 項目 | 内容 |
| --- | --- |
| Week | Week 2 |
| 主担当 | Codex |
| 目的 | 記事に複数タグを設定・表示できるようにする |
| 成果物 | Tag Model、ArticleTag Model、カンマ区切り入力処理、Validation |
| 完了条件 | カンマ区切りタグを保存でき、一般画面でタグ表示できる |
| 想定時間 | 4h |
| 依存関係 | W1-04 |
| リスク | 重複タグ、空タグ、全角カンマの扱い |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | CodexがDBと保存処理を担当。Antigravityは表示調整のみ |

### W2-03 Markdown変換・sanitize

| 項目 | 内容 |
| --- | --- |
| Week | Week 2 |
| 主担当 | Codex |
| 目的 | Markdown本文を安全なHTMLへ変換して表示する |
| 成果物 | `commonmarker` 導入、MarkdownRenderer、MarkdownPlainTextExtractor、sanitize処理、plain text 400文字validation |
| 完了条件 | 見出し、表、inline code、fenced code block、画像記法をsanitize済みHTMLへ変換でき、plain text相当400文字以上を判定できる |
| 想定時間 | 5h |
| 依存関係 | W1-04 |
| リスク | raw HTMLや危険なlink schemeを許可してしまう |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | Codexが変換、sanitize、Security reviewを担当 |

### W2-04 Active Storage画像

| 項目 | 内容 |
| --- | --- |
| Week | Week 2 |
| 主担当 | Codex |
| 目的 | thumbnailと本文画像を扱えるようにする |
| 成果物 | Active Storage設定、thumbnail添付、本文画像upload補助、画像Validation |
| 完了条件 | thumbnailを登録でき、本文画像のMarkdown記法をcopyして本文へ貼り付けられる |
| 想定時間 | 4h |
| 依存関係 | W1-04 |
| リスク | 画像容量、形式制限、参照URLの安全性確認漏れ |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | CodexがStorage設定とValidationを担当 |

### W2-05 管理画面連携調整

| 項目 | 内容 |
| --- | --- |
| Week | Week 2 |
| 主担当 | Codex / Antigravity |
| 目的 | 認証、タグ、Markdown、画像を管理画面でつなぐ |
| 成果物 | 管理記事フォームの項目整理、エラー表示、画像記法表示 |
| 完了条件 | 管理者がMarkdown記事、タグ、thumbnail、本文画像を登録できる |
| 想定時間 | 2h |
| 依存関係 | W2-01, W2-04 |
| リスク | CodexとAntigravityの同時編集競合 |
| 簡略化可能か | 一部可。UI装飾はWeek 3へ回す |
| Codex / Antigravityの担当 | CodexがController/route、AntigravityがERB。作業順はCodex完了後にAntigravity |

### W3-01 一般向け画面

| 項目 | 内容 |
| --- | --- |
| Week | Week 3 |
| 主担当 | Antigravity |
| 目的 | 一般利用者がトップ、記事一覧、記事詳細を閲覧できるようにする |
| 成果物 | トップページ、記事一覧、記事詳細のERB |
| 完了条件 | `published` のみ一般画面に表示され、投稿日は表示されない |
| 想定時間 | 5h |
| 依存関係 | W2-03, W2-04 |
| リスク | 投稿日非表示、非公開記事除外の漏れ |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | AntigravityがERBを担当。Codexは表示条件レビュー |

### W3-02 Markdown preview

| 項目 | 内容 |
| --- | --- |
| Week | Week 3 |
| 主担当 | Codex / Antigravity |
| 目的 | 保存前にMarkdown変換結果を確認できるようにする |
| 成果物 | Preview button、Rails側preview endpoint、sanitize後preview表示 |
| 完了条件 | 管理者がMarkdown本文のpreviewを確認できる |
| 想定時間 | 4h |
| 依存関係 | W2-03 |
| リスク | real-time previewまで広げると時間超過する |
| 簡略化可能か | 一部可。button式を優先し、real-time previewは対象外 |
| Codex / Antigravityの担当 | Codexが変換endpoint、AntigravityがPreview UI |

### W3-03 code block表示

| 項目 | 内容 |
| --- | --- |
| Week | Week 3 |
| 主担当 | Antigravity |
| 目的 | Qiita風にコードサンプルと実行結果例を読みやすく表示する |
| 成果物 | code block、inline code、table、quoteの表示調整 |
| 完了条件 | Pythonコード例と実行結果例が読みやすく表示される |
| 想定時間 | 3h |
| 依存関係 | W3-01 |
| リスク | 高度なsyntax highlightingに時間を使いすぎる |
| 簡略化可能か | 一部可。高度なsyntax highlightingは省略可能 |
| Codex / Antigravityの担当 | AntigravityがCSSと表示確認、Codexはsanitize class確認 |

### W3-04 CSS・レスポンシブ

| 項目 | 内容 |
| --- | --- |
| Week | Week 3 |
| 主担当 | Antigravity |
| 目的 | PC、タブレット、スマートフォンで大きく崩れないようにする |
| 成果物 | CSS、レスポンシブ調整、ブラウザ確認結果 |
| 完了条件 | スマートフォンで文字、画像、メニュー、code blockが画面外へ大きくはみ出さない |
| 想定時間 | 6h |
| 依存関係 | W3-01 |
| リスク | Markdown本文内の表やcode blockが崩れる |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | Antigravityが表示修正、Codexは必要に応じてレビュー |

### W3-05 画面表示レビュー

| 項目 | 内容 |
| --- | --- |
| Week | Week 3 |
| 主担当 | Codex / Antigravity / ユーザー |
| 目的 | 管理画面と一般画面の表示を一通り確認する |
| 成果物 | 表示確認結果、修正リスト |
| 完了条件 | 重大な表示崩れと投稿日表示漏れがない |
| 想定時間 | 2h |
| 依存関係 | W3-04 |
| リスク | 記事作成前に表示崩れを見落とす |
| 簡略化可能か | 一部可。詳細な装飾レビューはWeek 4へ回す |
| Codex / Antigravityの担当 | Codexが条件レビュー、Antigravityがブラウザ確認 |

### W4-01 記事8本作成・登録

| 項目 | 内容 |
| --- | --- |
| Week | Week 4 |
| 主担当 | ユーザー / Antigravity |
| 目的 | 最低8記事をMarkdown形式で登録する |
| 成果物 | 400文字以上の記事8本以上、タグ、thumbnail、本文画像 |
| 完了条件 | `published` 記事が8本以上あり、各記事が400文字以上ある |
| 想定時間 | 6h |
| 依存関係 | W3-02 |
| リスク | 記事本文作成に時間がかかる |
| 簡略化可能か | 不可。記事8本と400文字以上は必須 |
| Codex / Antigravityの担当 | Antigravityは表示確認を補助。Codexは文字数や公開状態の確認を補助 |

### W4-02 テスト

| 項目 | 内容 |
| --- | --- |
| Week | Week 4 |
| 主担当 | Codex |
| 目的 | 主要機能が要件どおり動くことを確認する |
| 成果物 | Model/Request/Systemテストまたは手動確認表 |
| 完了条件 | CRUD、認証、Markdown変換、sanitize、公開記事表示、タグ、画像、投稿日非表示を確認済み |
| 想定時間 | 5h |
| 依存関係 | W4-01 |
| リスク | テスト導入に時間がかかる場合、手動確認が増える |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | Codexがテストとレビューを担当 |

### W4-03 不具合修正・Security確認

| 項目 | 内容 |
| --- | --- |
| Week | Week 4 |
| 主担当 | Codex / Antigravity |
| 目的 | テストとブラウザ確認で見つかった不具合を直し、Securityを確認する |
| 成果物 | 不具合修正済みコード、Security確認結果 |
| 完了条件 | Markdown変換後HTMLのsanitize、危険なtag/attribute/scheme拒否、画像Validation、未認証アクセス防止を確認済み |
| 想定時間 | 5h |
| 依存関係 | W4-02 |
| リスク | Backend修正とFrontend修正が同じfileに集中する |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | CodexがBackend/Security、AntigravityがERB/CSS。修正対象fileを分けて順番に作業 |

### W4-04 README

| 項目 | 内容 |
| --- | --- |
| Week | Week 4 |
| 主担当 | Codex / ユーザー |
| 目的 | 起動方法、初期設定、管理者ログイン情報、提出情報をまとめる |
| 成果物 | README |
| 完了条件 | 第三者が起動方法と管理者ログイン情報を確認できる |
| 想定時間 | 2h |
| 依存関係 | W4-03 |
| リスク | DB作成、seed、画像保存先、Markdown仕様の説明漏れ |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | CodexがREADME草案、ユーザーが提出情報を最終確認 |

### W4-05 納品準備・最終確認

| 項目 | 内容 |
| --- | --- |
| Week | Week 4 |
| 主担当 | ChatGPT / Codex / Antigravity / ユーザー |
| 目的 | 完成条件を満たしているか最終確認する |
| 成果物 | 最終確認結果、提出物 |
| 完了条件 | 完成条件を満たし、ユーザーがブラウザ確認とpush/CI確認を完了している |
| 想定時間 | 2h |
| 依存関係 | W4-04 |
| リスク | 記事数、文字数、投稿日非表示、sanitizeなど課題条件の見落とし |
| 簡略化可能か | 不可 |
| Codex / Antigravityの担当 | Codexが最終チェック、Antigravityが表示崩れ修正、ユーザーが最終判断 |

## 同時編集を避けるための作業順

1. CodexがDB、Model、Controller、route、認証、Markdown変換、sanitize、テストを先に実装する。
2. AntigravityがERB、CSS、レスポンシブ、Markdown表示調整、Preview UI、ブラウザ確認を行う。
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
  - `active_storage_blobs`
  - `active_storage_attachments`
  - `active_storage_variant_records`
- Model関連:
  - `Article has_many :article_tags`
  - `Article has_many :tags, through: :article_tags`
  - `Article has_one_attached :thumbnail`
  - `Tag has_many :article_tags`
  - `Tag has_many :articles, through: :article_tags`
  - `Admin has_secure_password`
- Markdown:
  - `articles.body` にMarkdown原文を保存
  - RubyのMarkdown libraryでHTMLへ変換
  - sanitizeした安全なHTMLとして表示
  - `action_text_rich_texts` は使わない
- Preview:
  - button式でRails側Markdown変換・sanitizeを共通利用
- 本文画像:
  - Active Storageへuploadし、生成されたMarkdown画像記法をcopyして本文へ貼り付ける方式を推奨
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
  - `draft` / `published`
  - 一般画面は `published` のみ表示
- 4週間のStep構成:
  - 20 Step、合計80時間
- 次に行うTask:
  - Railsプロジェクト初期化前の開発環境確認とMarkdown Gem候補の最終選定

## 要件上の注意点

- Action TextとTrixは採用しない。
- `articles.body` にMarkdown原文を保存する。
- Markdown変換後HTMLは必ずsanitizeする。
- code block内のPythonは表示のみで実行しない。
- 文字色、下線、画像サイズは限定classまたは限定記法で扱う。
- 自由なdrag resize、無制限color picker、任意style属性は対象外とする。
- 時間不足時は、自動目次、real-time preview、文字色種類、画像サイズ選択、関連記事、404装飾、高度なsyntax highlightingを簡略化する。

## セルフレビュー項目

- `docs/requirements.md` と4設計資料がMarkdown方針で一致していること
- Action Text採用の記載が残っていないこと
- Trix採用の記載が残っていないこと
- `action_text_rich_texts` がtable一覧から削除されていること
- `articles.body` が追加されていること
- Active Storageは維持されていること
- Ruby on Railsが主構成であること
- Pythonは記事例のみであること
- React/Vue等を追加していないこと
- browser上code実行をScopeに入れていないこと
- 80時間以内であること
- 各週20時間以内であること
- 記事8本以上を含むこと
- 1記事400文字以上を含むこと
- 投稿日非表示を維持していること
- `draft` / `published` を維持していること
- 管理者認証を維持していること
- タグ正規化を維持していること
- Markdown previewを含むこと
- Sanitization方針を含むこと
- 画像upload方式の推奨案を示していること
