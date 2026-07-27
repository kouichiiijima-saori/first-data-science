# JoditによるMarkdown併存型記事編集 設計レビュー

## 1. Executive Summary

既存のMarkdown記事編集機能を維持したまま、Joditによるリッチテキスト編集を記事ごとに選択できる構成を推奨する。最小で安全なArchitectureは、`articles.body` をMarkdown原文またはsanitize対象HTMLの共用列として継続利用し、`editor_type` で本文形式を判別する案Aである。

既存記事はすべて `markdown` として扱い、Jodit記事は `rich_text` としてHTMLを保存する。MarkdownとJoditの完全な相互変換は行わず、保存済み記事の編集方式は初期Scopeでは固定する。公開表示時は `editor_type` に応じてMarkdown用 `MarkdownRenderer` またはJodit HTML用の新規 `RichTextRenderer` を通し、どちらもRails側でsanitize済みHTMLとして出力する。

画像はJoditのBase64保存を使わず、認証済み管理者用upload endpointからActive Storageへ保存する。本文HTMLにはActive Storageの同一origin URLと表示サイズ情報のみを保持し、元画像は加工しない。

最終判定は **READY WITH OPEN QUESTIONS** とする。実装方針は確定可能だが、未保存記事への画像upload UX、本文画像のorphan cleanup方針、production storage/backup運用、文字色・文字サイズの許可範囲は実装前に先方確認すると安全である。

## 2. 先方要件

- 記事本文の編集画面で、見出し、段落、文字サイズ、文字色、下線、URLリンク、本文画像挿入、挿入画像のサイズ変更を扱えること。
- Markdown編集機能は削除しない。
- 既存Markdown記事を壊さない。
- 記事ごとに編集方式を区別する。
- Joditは文章と画像の両方を扱う本文エディターとして使う。
- Jodit生成HTMLをそのまま信用せず、Rails側でsanitizeする。
- 画像はActive Storageへ保存し、Base64画像の本文保存は採用しない。
- 元画像は保持し、サイズ変更は表示サイズ変更として扱う。
- PC、タブレット、スマートフォンで操作できること。

## 3. 確定Scope

- Joditを管理画面の記事本文エディターとして追加する。
- Markdown記事とJodit記事を記事単位で区別する。
- Jodit記事はHTMLを保存し、公開表示時にHTML sanitizerを通す。
- Joditの画像uploadはRails管理者用endpointを経由してActive Storageへ保存する。
- 画像の表示サイズは本文HTML内の限定属性として保存し、公開画面にも反映する。
- Markdown記事の既存Previewは維持する。

## 4. Out of Scope

- 画像のトリミング、回転、反転、色補正、フィルター、文字入れ。
- 画像ファイル自体の上書き加工。
- Base64画像の本文保存。
- MarkdownとJodit HTMLの完全な相互変換。
- Action Text / Trixへの移行。
- 本文画像の高度なファイルブラウザ、再利用UI、CDN移行。
- Mermaid、数式、syntax highlight library追加。

## 5. 既存実装

- `Article` は `articles.body` にMarkdown原文を保存している。
- `Article::BODY_MAX_LENGTH` はMarkdown原文15,000文字である。
- `MarkdownPlainTextExtractor` により、Markdown記号やHTMLタグを除いたplain text相当400文字以上を検証している。
- `MarkdownRenderer` はCommonMarkerでHTML化し、Rails HTML sanitizerとNokogiriでallowlist sanitize、link/image/class正規化を行う。
- 公開記事詳細は `ArticlesController#show` で `MarkdownRenderer.render(@article.body)` を呼び、sanitize済みHTMLを表示している。
- 管理画面Previewは `POST /admin/markdown_preview` でMarkdown本文を受け取り、DB保存せずJSONでsanitize済みHTMLを返す。
- `Article` は `has_one_attached :thumbnail` を持ち、JPEG/PNG/WebP、拡張子、5MB以下の検証をModelに持つ。
- JavaScriptはImportmap + Stimulus構成で、Node build pipelineは存在しない。
- CSP initializerはRails標準コメント状態で、実効CSPはまだ定義されていない。
- `articles.body` はMySQL `longtext` であり、Markdown 15,000文字および限定HTML保存には容量上の余裕がある。

## 6. Jodit導入方式

推奨は **Joditの配布assetをバージョン固定してローカルvendor管理し、Importmap/Propshaftから読み込む方式** である。

| 観点 | npm build | Importmap + local vendor | CDN |
| --- | --- | --- | --- |
| 現行構成との整合 | Node導入が必要 | Importmap + Propshaftの現行構成に合う | 実装は軽いが外部依存 |
| 納品再現性 | Node/npm version管理が増える | firestorage納品物だけで再現しやすい | オフライン・接続制限で壊れる |
| Security | lock/audit対象を増やせる | バージョン固定とファイル監査が必要 | SRI/CSP管理が必要 |
| CSS読込 | bundler設定が必要 | `vendor` assetとして明示 | 外部CSS許可が必要 |
| 推奨度 | 将来build導入時に検討 | 初期推奨 | 非推奨 |

Joditはnpm packageとして提供され、ESM/UMD配布ファイルとCSSを含む。公式README上ではCDN利用も案内されているが、納品再現性とCSP方針を優先し、CDNは採用しない。ライセンスはGitHub repository上でMIT licenseと表示されているため、Jodit本体のライセンス表記を同梱物に残す前提で納品利用は可能と判断する。ただし、Jodit PRO/OEM pluginは別扱いの可能性があるため使用しない。

## 7. Markdown併存Architecture

### 比較

| 案 | 内容 | 既存Markdown互換性 | 実装工数 | データ消失リスク | validation | sanitize | Preview | 画像管理 | test容易性 | 保守性 | 将来画像加工 | DB migration | rollback | 初心者向けUI | Security |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 案A | `articles.body` 共用、`editor_type`で判別 | 高い。既存bodyをそのまま維持 | 低〜中 | 切替を固定すれば低い | editor_type別に分岐 | rendererを分ける | Markdownのみ維持、JoditはWYSIWYG | Active Storage追加で対応 | 高い | 高い | 別Task追加可能 | `editor_type`追加、本文画像添付追加 | 容易 | 新規作成時選択で分かりやすい | 高い |
| 案B | `markdown_body` と `rich_text_body` を別列 | 高いが移行が大きい | 中〜高 | 並行保持できるが同期事故あり | 複雑 | 分岐が明確 | 両方保持なら複雑 | 対応可能 | 中 | 中 | 対応可能 | 複数列追加、既存body移行 | 複雑 | 入力欄が増えやすい | 中〜高 |
| 案C | Action Text等へ移行 | 低い。現行方針と衝突 | 高い | 既存Markdown移行リスク高 | Action Text前提へ変更 | Trix/Action Text前提 | 既存Preview再設計 | Action Text添付へ移行 | 低〜中 | 既存から乖離 | Rails標準には乗る | 大きい | 難しい | Jodit要件とズレる | 要再設計 |

### 推奨

**案Aを採用する。**

理由:

- 既存Markdown記事の `body` を移行せず維持できる。
- DB変更が `editor_type` と本文画像添付の追加に収まり、rollbackしやすい。
- MarkdownとJoditの完全相互変換を避けられる。
- 公開表示・validation・sanitizeを `editor_type` で明確に分岐できる。
- 納品前の規模に対して過剰設計にならない。

初期実装では、保存後の編集方式変更は原則不可とする。どうしても切替を提供する場合は、空本文の新規記事だけ許可するか、明示的な確認画面と「変換ではなく新形式へコピー」を別Taskで設計する。

## 8. Database

推奨migration:

- `articles.editor_type`: `string`, `null: false`, `default: "markdown"`
- index: 必須ではないが、管理画面で方式別filterを作る可能性がある場合は `index_articles_on_editor_type` を検討する。
- `Article has_many_attached :body_images` を追加する。Active Storage既存tableを利用するため、専用tableは不要。

`articles.body` は既存の `longtext` を継続利用する。Markdown 15,000文字、Jodit表示テキスト15,000文字、HTML全体上限60,000文字程度であれば、MySQL `longtext` の容量を大きく下回る。

`editor_type` 候補値:

- `markdown`
- `rich_text`

既存記事のdefaultは `markdown` とする。migration後も既存記事の本文解釈は変わらない。

## 9. Article Model

`Article` は本文形式の状態管理とvalidationを担当する。

推奨定数:

- `EDITOR_TYPES = %w[markdown rich_text].freeze`
- `MARKDOWN_BODY_MAX_LENGTH = 15_000`
- `RICH_TEXT_PLAIN_TEXT_MAX_LENGTH = 15_000`
- `RICH_TEXT_HTML_MAX_LENGTH = 60_000`
- `MINIMUM_BODY_PLAIN_TEXT_LENGTH = 400`

validation:

- `editor_type` presence/inclusion。
- `markdown` は既存のMarkdown原文15,000文字上限とplain text 400文字以上を維持する。
- `rich_text` はHTML全体60,000文字以下、HTMLタグを除いた表示テキスト15,000文字以下、表示テキスト400文字以上を検証する。
- unsafe HTMLの有無は保存拒否ではなく、表示時sanitizeを正本とする。ただし、`script`、`iframe`、`data:` 画像、Base64などは保存前validationでも拒否を検討する。
- body blank時はpresence errorを優先し、400文字不足errorを重複させない。

`Article` がJoditやDOM処理の詳細に直接依存しすぎないよう、plain text抽出とsanitizeはserviceへ分離する。

## 10. Admin UX

### 編集方式UX比較

| 案 | 内容 | 利点 | リスク | 判定 |
| --- | --- | --- | --- | --- |
| 案1 | 新規作成時に「Markdown」「リッチテキスト」を選択 | 既存記事を壊しにくく初心者にも説明しやすい | 後から方式変更しにくい | 推奨 |
| 案2 | 編集画面上部のタブで切替 | 見た目は便利 | MarkdownとHTMLの相互変換不能により内容消失リスクが高い | 非推奨 |
| 案3 | 管理設定でサイト全体の方式を固定 | 運用は単純 | 既存Markdown維持要件と相性が悪い | 非推奨 |

推奨UX:

- 新規作成画面で編集方式を選ぶ。
- 既存記事の編集画面では現在の方式を表示し、本文editorは固定する。
- Markdown記事では従来のtextareaとPreview buttonを表示する。
- Jodit記事ではWYSIWYG editorを表示し、Markdown Previewは表示しない。
- 保存済み記事を無警告で別方式へ変換しない。

## 11. Jodit Toolbar

先方要件を満たす最小toolbar候補:

- `paragraph` または heading selector
- `fontsize`
- `brush` または text color
- `underline`
- `link`
- `image`
- `undo`
- `redo`
- `removeFormat`

要件外のtable、video、file browser、source editor、fullsize、print、symbols等は初期表示しない。source editorを許可するとHTML直接入力の攻撃面が増えるため、初期Scopeでは非表示にする。

## 12. Image Upload

推奨Flow:

1. Joditのimage upload操作。
2. Stimulus controllerがCSRF token付きでRails管理者用upload endpointへ送信。
3. Rails側で認証済み管理者のみ許可。
4. MIME type、拡張子、容量を検証。
5. Active Storage blobとして保存。
6. JSONで `url`, `signed_id`, `filename`, `alt` 候補を返す。
7. Joditがカーソル位置へ `<img>` を挿入する。
8. Article保存時に本文HTML中の参照画像を抽出し、`body_images` へattachする。

推奨route候補:

- `POST /admin/rich_text_images`

記事IDに依存しないendpointにすると、未保存記事でもuploadしやすい。一方で未使用blobが発生するため、一定時間経過したunattached blobを削除するcleanup taskを別途設計する。

画像制限:

- 許可: JPEG, PNG, WebP。
- 拒否: SVG, GIF, HTML, PDF, その他。
- 最大容量: thumbnailと同じ5MBを初期値とする。
- MIME typeと拡張子を二重確認する。
- client側 `beforeUpload` はUX補助として使えるが、Security判定は必ずRails側で行う。

Joditのimage dialogにはURL入力tabが常時出るため、初期実装では外部画像URLを禁止する。可能ならJodit設定でURL tabを非表示または送信時に拒否し、Rails sanitizerでも外部 `img[src]` を削除する。

## 13. Image Resize

初期ScopeではJoditの標準ResizerまたはImage Propertiesを利用する。元画像は加工せず、表示サイズだけを本文HTMLへ保存する。

| 方式 | 利点 | リスク | 判定 |
| --- | --- | --- | --- |
| `width` 属性 | sanitizeしやすい。公開CSSと併用しやすい | 高さ指定を保持しない | 推奨 |
| `width` / `height` 属性 | Jodit標準出力と相性がよい | 縦横比を壊す可能性 | 条件付き許可 |
| inline `style` | Jodit出力を保持しやすい | 無制限styleはXSS/崩れリスク | 限定propertyのみ |
| CSS class 小/中/大/全幅 | sanitizeしやすい | Jodit標準Resizerとの相性が弱い | 将来検討 |
| Jodit標準出力をそのまま保存 | 実装は軽い | sanitize後に危険属性が残る可能性 | 非推奨 |

推奨:

- `img` の `width` と `height` は正の整数のみ許可する。
- Jodit側は縦横比保持を有効にする。
- 公開CSSでは `max-width: 100%; height: auto;` を基本にし、スマートフォンで記事幅を超えないようにする。
- `style` は原則禁止し、どうしても必要な場合でも `width`, `height` に変換してから保存する。

## 14. Active Storage

thumbnailと本文画像は分離する。

- thumbnail: 既存 `has_one_attached :thumbnail` を維持。
- body images: 新規 `has_many_attached :body_images` を推奨。

本文HTML内の `img[src]` とActive Storage blobの関係は、Article保存時にHTMLからActive Storage signed_idまたはblob pathを抽出して `body_images` にattachする。記事更新で参照されなくなった画像はdetach候補とし、purgeは他記事参照や監査方針を確認してから行う。

初期方針:

- 他記事で同一画像を再利用するUIは作らない。
- 記事削除時は、その記事にのみattachされた本文画像をpurgeする方針を検討する。
- 未保存記事でuploadされたが保存本文から参照されなかったblobはorphan cleanup対象にする。
- production storageは納品先運用によりDisk継続またはS3等を決める。firestorageでソース納品する場合、upload済み画像データの納品・backup対象をREADME等に明記する必要がある。

## 15. HTML Sanitize

Markdown記事:

- 既存 `MarkdownRenderer` を維持する。
- CommonMarkerのunsafe HTML無効化とRails sanitizerのallowlistを継続する。

Jodit記事:

- 新規 `RichTextRenderer` または `RichTextSanitizer` を追加する。
- ViewやControllerへsanitize処理を直接書かない。
- rendererはsanitize済みHTMLを返す契約にする。

許可tag候補:

- `p`, `br`
- `h1`, `h2`, `h3`, `h4`, `h5`, `h6`
- `strong`, `em`, `u`
- `a`
- `ul`, `ol`, `li`
- `blockquote`
- `img`
- `span`

許可attribute候補:

- `a`: `href`, `title`, `target`, `rel`
- `img`: `src`, `alt`, `width`, `height`
- `span`: `class` または限定 `style`

文字色・文字サイズ:

- 第一候補はJodit側で選択肢を限定し、保存時に `span` の安全なclassへ正規化する方式。
- class方式が難しい場合、`span[style]` は `color` と `font-size` のみに限定し、値はHEX色または許可済みCSS keyword、font-sizeは許可リストまたは安全なpx範囲に制限する。
- `style` を無制限に許可しない。

禁止:

- `script`, `iframe`, `object`, `embed`, `form`, `input`
- `onerror`, `onclick` 等のevent handler属性
- `javascript:` URL
- `data:text/html`
- `data:image/*` を含むBase64画像
- 外部画像URL
- protocol-relative URL

linkは `http`, `https`, `mailto`, same-origin pathのみ許可する。`target="_blank"` を許可する場合は `rel="noopener noreferrer"` を必ず付与する。

## 16. Public Rendering

公開記事詳細は `editor_type` に応じて本文rendererを選択する。

推奨構成:

- `ArticleBodyRenderer.render(article)` のような薄いdispatcherを置く。
- `markdown` は `MarkdownRenderer.render(article.body)`。
- `rich_text` は `RichTextRenderer.render(article.body)`。
- ControllerまたはViewにHTML変換詳細を埋め込まない。
- 公開一覧は本文HTMLを表示しないため、既存のtitle/summary/tags/thumbnail表示を維持する。

公開CSS:

- MarkdownとJodit本文で共通の `.article-body` または既存 `.markdown-body` を使うか、`rich-text-body` を追加する。
- 画像は `max-width: 100%; height: auto;` を保証する。
- tableやcode blockはJodit初期Scope外だが、既存Markdown表示を壊さない。

## 17. Input Limits

現在:

- Markdown原文: 15,000文字。
- Markdown plain text: 400文字以上。

推奨:

- Markdown: 原文15,000文字、plain text 400文字以上を維持。
- Jodit: 表示テキスト15,000文字以内、HTML全体60,000文字以内、表示テキスト400文字以上。
- Base64画像を拒否するため、画像バイト列でHTML上限を消費する設計にしない。

責務:

- Model: 保存時validation。
- Service: HTML plain text抽出、HTMLサイズ検証補助、sanitize。
- Controller: strong parametersと失敗response。
- Frontend: `maxlength` やJodit設定によるUX補助。ただしSecurity判定はRails側。

Preview:

- Markdown Preview APIはMarkdown記事専用として維持する。
- Jodit記事はWYSIWYGで編集結果を確認できるため、別Preview APIは初期Scopeでは不要。

## 18. Security

必須対応:

- Jodit生成HTMLを信頼せず、Rails側で必ずsanitizeする。
- `raw` や `html_safe` はrendererのsanitize済みHTML返却箇所に限定する。
- upload endpointは `Admin::BaseController` 配下に置き、認証済み管理者のみ許可する。
- CSRF tokenを送信し、Rails標準のCSRF検証を使う。
- 画像はJPEG/PNG/WebP、拡張子、MIME type、5MB以下を検証する。
- SVG/GIF/HTML/PDFを拒否する。
- Base64画像と外部画像URLを拒否する。
- link/imageのURL schemeをallowlist方式で検証する。
- CSPを実効化する場合、CDN不要の `script-src 'self'` / `style-src 'self'` を基本にし、unsafe-inlineを増やさない。
- JoditのURL tabやsource editorなど、攻撃面が広い機能は初期Scopeで隠すかサーバー側で拒否する。

## 19. Responsive Design

- 管理画面ではJodit toolbarがモバイル幅で折り返しても本文入力欄を押し潰さないようにする。
- タブレット/スマートフォンでは画像resize操作が難しいため、最低限「挿入済み画像の選択、幅変更、保存」ができることをsystem testと手動確認で見る。
- 公開画面では本文画像に `max-width: 100%` を適用し、横スクロールを防ぐ。
- Jodit固有CSSは管理画面に限定して読み込み、公開画面CSSと過剰に干渉させない。

## 20. Test Plan

Model:

- `editor_type` validation。
- 既存Markdown記事がdefault `markdown` として扱われる。
- Markdown原文15,000文字上限を維持。
- Jodit表示テキスト15,000文字上限。
- Jodit HTML全体60,000文字上限。
- Jodit表示テキスト400文字未満を拒否。
- unsafe HTML保存時でも公開renderで無害化される。

Controller:

- Markdown記事create/update。
- Jodit記事create/update。
- 保存済み記事の編集方式が無警告で切り替わらない。
- 未認証upload拒否。
- CSRFなしupload拒否。
- invalid image拒否。
- oversized image拒否。
- safe upload response。
- validation失敗時の入力保持。

Service:

- `RichTextRenderer` が許可tag/attributeを保持する。
- `script`, `iframe`, event handler, `javascript:` を除去する。
- `data:` 画像を拒否する。
- 外部画像URLを拒否する。
- `width` / `height` の安全な数値属性を保持する。
- 文字色・文字サイズの許可範囲だけ保持する。
- 二重escape・二重sanitizeを起こさない。

System:

- Markdown記事作成・編集・Preview回帰。
- Jodit記事作成。
- 見出し、段落、文字サイズ、文字色、下線、URLリンク。
- 画像upload、挿入、サイズ変更。
- 保存後の再編集。
- 公開表示。
- mobile幅。

Security:

- XSS payload。
- `script`, `onerror`, `javascript:` URL。
- `data:` URL、SVG、HTML偽装画像。
- unauthorized upload。
- Brakeman、bundler-audit、importmap audit、bin/ci。

## 21. Migration

Task 1で実施する最小migration:

- `articles.editor_type` 追加。
- 既存rowはdefaultにより `markdown`。
- 必要ならcheck constraint相当はModel validationを先行し、DB constraintは後続で検討する。

本文画像はActive Storage既存tableを利用する。`has_many_attached :body_images` の追加自体はmigration不要だが、保存済みHTMLとblobの関連追跡を厳密にする場合は後続で専用join modelを検討する。

rollback:

- `editor_type` を削除しても既存Markdown記事は影響を受けない。
- rich_text記事はHTMLとして `body` に残るため、rollback時は表示がMarkdownとして崩れる。rollback前にrich_text記事を非公開化または移行する手順が必要。

## 22. Backward Compatibility

- 既存記事は `markdown` として扱う。
- Markdown本文、Markdown Preview、公開Markdown表示、plain text 400文字validation、thumbnail、tag、draft非公開制御は維持する。
- Jodit追加後もMarkdown記事の `body` はMarkdown原文のまま保存する。
- Jodit記事のHTMLをMarkdownへ自動変換しない。
- `articles.body` の意味は `editor_type` により決まるため、管理画面・公開画面・seed/docsで明記する。

## 23. Implementation Breakdown

### Task 1: editor_typeと保存形式の基盤

- 目的: 記事ごとの本文形式を区別する。
- Scope: `editor_type` migration、Article validation、既存記事default、public renderer dispatcher。
- Out of Scope: Jodit UI、画像upload。
- 変更file候補: `db/migrate/*`, `app/models/article.rb`, `app/services/article_body_renderer.rb`, `app/controllers/articles_controller.rb`, locale, model/controller tests。
- test: 既存Markdown互換、editor_type validation、公開表示分岐。
- commit message: `feat: 記事本文の編集方式を管理`
- 依存関係: なし。
- 完了条件: 既存Markdown記事が従来通り表示され、rich_text placeholder分岐を安全に扱える。

### Task 2: Joditの導入と文章装飾

- 目的: リッチテキスト本文の編集UIを提供する。
- Scope: Jodit asset導入、Stimulus controller、toolbar最小化、rich_text form。
- Out of Scope: 本文画像upload、画像resize保存。
- 変更file候補: `vendor/javascript`, `vendor/assets`, `config/importmap.rb`, `app/javascript/controllers/rich_text_editor_controller.js`, `app/views/admin/articles/_form.html.erb`, `app/assets/stylesheets/admin.css`。
- test: Jodit記事作成、見出し、文字サイズ、文字色、下線、リンク、入力保持。
- commit message: `feat: 管理画面にリッチテキスト編集を追加`
- 依存関係: Task 1。
- 完了条件: Markdown記事とJodit記事を新規作成時に選べ、保存後も方式が固定される。

### Task 3: 本文画像upload

- 目的: Jodit本文画像をActive Storageへ保存する。
- Scope: 管理者用upload endpoint、画像validation、JSON response、CSRF、orphan方針。
- Out of Scope: 画像resize、file browser、画像再利用UI。
- 変更file候補: `app/controllers/admin/rich_text_images_controller.rb`, `config/routes.rb`, `app/models/article.rb`, upload service, locale, controller tests。
- test: 認証、CSRF、JPEG/PNG/WebP許可、SVG/GIF/HTML/PDF拒否、5MB超拒否。
- commit message: `feat: Jodit本文画像のアップロード基盤を追加`
- 依存関係: Task 2。
- 完了条件: JoditからActive Storage URLを受け取り、Base64なしで画像を挿入できる。

### Task 4: 画像挿入とサイズ変更

- 目的: 挿入画像の表示サイズ変更を保存・公開反映する。
- Scope: Jodit Resizer設定、`width`/`height`属性保存、公開CSS、sanitize保持。
- Out of Scope: トリミング、回転、画像加工。
- 変更file候補: Jodit Stimulus controller, `RichTextRenderer`, CSS, system tests。
- test: 画像サイズ変更、保存後再編集、公開表示、mobile幅。
- commit message: `feat: 本文画像の表示サイズ変更に対応`
- 依存関係: Task 3。
- 完了条件: 元画像を加工せず、表示サイズだけが保存・公開反映される。

### Task 5: sanitizeと公開表示

- 目的: Jodit HTMLを安全に公開表示する。
- Scope: `RichTextRenderer`, `RichTextPlainTextExtractor`, allowlist、URL正規化、public renderer接続。
- Out of Scope: 新規Jodit UI機能。
- 変更file候補: `app/services/rich_text_renderer.rb`, `app/services/rich_text_plain_text_extractor.rb`, `app/services/article_body_renderer.rb`, tests。
- test: XSS、unsafe attr、dangerous URL、data URI、size属性保持、文字色/文字サイズ保持。
- commit message: `feat: リッチテキスト本文を安全に表示`
- 依存関係: Task 1, Task 2。
- 完了条件: Jodit記事がsanitize済みHTMLとして公開表示され、Brakeman警告0を維持する。

### Task 6: system test・security・docs

- 目的: 納品前の回帰と運用資料を整える。
- Scope: system/security回帰、README/docs更新、CSP検討、backup/restore手順追記。
- Out of Scope: 追加機能。
- 変更file候補: `test/system/*`, README, docs。
- test: `bin/rails test`, `bin/rails test:system`, `bin/ci`, Brakeman, bundler-audit, importmap audit。
- commit message: `test: リッチテキスト編集の回帰検証を追加`
- 依存関係: Task 1〜5。
- 完了条件: 実装済み機能を顧客がWindows 11 + WSL2 + Ubuntu 24.04で再現できる。

## 24. Risks

- JoditのURL tabが外部画像URLを受け付けると、tracking pixelやmixed contentの入口になる。
- Base64画像が保存されるとDB肥大化と画面遅延が起きる。
- inline styleを広く許可するとXSSや表示崩れの原因になる。
- MarkdownとHTMLを同じ `body` に保存するため、`editor_type` を誤ると表示が壊れる。
- 保存済み記事の方式切替を許可すると、文字色・文字サイズ・下線・画像サイズなどが失われる。
- 未保存記事で画像uploadを許可するとorphan blobが発生する。
- Disk storage運用では、firestorage納品物とは別に `storage/` backup/restore手順が必要になる。
- Jodit assetをvendor固定する場合、将来の脆弱性確認は手動管理になる。

## 25. Open Questions

- 未保存の新規記事で本文画像uploadを許可するか。許可する場合、orphan blob cleanupの実行タイミングをどうするか。
- 本文画像の最大容量はthumbnailと同じ5MBで確定してよいか。
- GIFは要件外として禁止でよいか。
- 文字色は自由入力ではなく、管理画面で定義した色だけに制限してよいか。
- 文字サイズは自由入力ではなく、S/M/Lなどの段階指定に制限してよいか。
- production storageはDisk継続か、S3等へ移行するか。
- article削除時、本文画像blobを即purgeするか、一定期間保持するか。
- Joditのライセンス表記を納品物内のどこへ置くか。
- CSPをJodit導入Taskで同時に有効化するか、別Taskに分けるか。

## 26. Completion Criteria

- 既存Markdown記事が壊れない。
- 新規Jodit記事を作成・編集できる。
- Jodit記事で見出し、段落、文字サイズ、文字色、下線、URLリンク、本文画像挿入、画像サイズ変更ができる。
- Jodit記事の公開表示がRails側sanitize済みHTMLのみを出力する。
- Base64画像、SVG、危険HTML、event handler、`javascript:` URL、外部画像URLを拒否する。
- 本文画像はActive Storageへ保存され、thumbnailとは責務分離されている。
- Markdown PreviewはMarkdown記事で維持され、Jodit記事では不要なPreviewを表示しない。
- PC、タブレット、スマートフォンで編集・保存・公開表示を確認する。
- `bin/rails test`, `bin/rails test:system`, `bin/ci`, Brakeman, bundler-audit, importmap audit, `git diff --check` が成功する。
- READMEまたはdocsに運用上必要なstorage backup/restore、Jodit asset、本文画像制約が記載されている。

## Task 1 実装結果

実装Task: `feat: 記事の編集方式を追加`

確定したDB定義:

- `articles.editor_type`: `string`, `null: false`, `default: "markdown"`
- 既存記事はmigration後にDB defaultにより `markdown` として扱う。
- `articles.body` は既存の `longtext` 共用列のまま維持し、本文内容は変更しない。
- `body_images` やJodit用assetはTask 1では追加しない。

Model方針:

- `Article::EDITOR_TYPES = %w[markdown rich_text].freeze`
- `Article::DEFAULT_EDITOR_TYPE = "markdown"`
- Rails enumは採用しない。既存 `status` と同じく、string定数とinclusion validationで扱う。
- 理由は、既存コードの文字列paramsとの整合を優先し、Task 1では状態遷移やenum helperを必要としないため。

編集方式変更ルール:

- 新規記事では `markdown` / `rich_text` を選択できる。
- 新規記事の既定値は `markdown`。
- 保存済み記事の `editor_type` は変更不可。
- 本文の自動変換は行わない。
- 不正に変更paramsが送信された場合も、Model validationで保存を拒否する。
- 編集画面では現在方式を表示し、selectはdisabledにする。

Task 2への前提:

- `rich_text` を選択して保存する基盤はできている。
- ただしJodit asset、toolbar、HTML sanitizer、RichTextRenderer、本文画像upload、画像サイズ変更は未実装。
- Task 2では、`rich_text` 記事の管理画面本文入力欄をJoditへ置き換える。
- Markdown Previewは引き続きMarkdown記事向け機能として維持する。

## Task 2 実装結果

実装Task: `feat: Joditによる本文編集を追加`

採用Jodit version:

- `jodit@4.13.5`
- 設計レビュー時点ではdocs内で具体versionを固定していなかったため、Task 2でnpm公開packageの最新版を確認し、`4.13.5` に固定した。

Asset取得元とlicense:

- 取得元: npm registry tarball `https://registry.npmjs.org/jodit/-/jodit-4.13.5.tgz`
- license: MIT
- license file: `vendor/licenses/jodit/LICENSE.txt`
- 追跡情報: `vendor/licenses/jodit/package.json`, `vendor/licenses/jodit/README.md`

配置file:

- JavaScript: `vendor/javascript/jodit/jodit.min.js`
- CSS: `app/assets/stylesheets/jodit/jodit.min.css`
- license: `vendor/licenses/jodit/LICENSE.txt`
- metadata: `vendor/licenses/jodit/package.json`, `vendor/licenses/jodit/README.md`

読込方法:

- CDNは使用しない。
- `config/importmap.rb` で `jodit` を `jodit/jodit.min.js` へpinする。
- `rich_text_editor_controller.js` から `import "jodit"` し、UMD buildが提供する `window.Jodit` を利用する。
- CSSは管理画面layoutから `stylesheet_link_tag "jodit/jodit.min"` で読み込む。
- ESM buildは多数の分割moduleとplugin importを伴うため、Importmapでの最小導入よりUMD buildを採用した。

Toolbar構成:

- `paragraph`
- `fontsize`
- `brush`
- `underline`
- `link`
- `undo`
- `redo`
- `eraser`

非表示・無効化する機能:

- `image`
- `file`
- `video`
- `table`
- `source`
- `iframe`
- `preview`
- `print`
- `fullsize`
- `speech-recognize`
- `symbols`
- 今回要件外のupload/file browser系plugin

見出し範囲:

- 通常段落: `p`
- 見出し2: `h2`
- 見出し3: `h3`
- 見出し4: `h4`
- `h1` は公開記事タイトルとの階層重複を避けるため、本文editorの候補から外す。

文字サイズ方式:

- 任意px入力は許可しない。
- Joditの候補を次へ制限する。
  - 小: `0.875rem`
  - 標準: `1rem`
  - 大: `1.25rem`
  - 特大: `1.5rem`
- Task 5のsanitizeでは、この限定値だけを保持できる方式へ接続する。

文字色方式:

- ブラウザ標準の無制限color pickerは使用しない。
- Joditの色候補を次のpaletteへ制限する。
  - `#111827`
  - `#374151`
  - `#2563EB`
  - `#047857`
  - `#B45309`
  - `#B91C1C`
- Task 5のsanitizeでは、このpaletteだけを保持できる方式へ接続する。

Stimulus lifecycle:

- `article_editor_mode_controller.js` が `markdown` / `rich_text` の入力panelとtextareaの有効・無効を切り替える。
- `rich_text_editor_controller.js` は `rich_text` のときだけJoditを初期化する。
- `connect` 時、`editor_type` が `rich_text` の場合のみ初期化する。
- `disconnect` 時にJoditを `destruct` し、Turbo back/forwardや再接続で二重初期化しない。
- editor切替直前、Jodit change時、form submit直前にtextareaへ同期する。
- JavaScript無効時も `textarea` fallbackに入力できる構造を残す。

Form同期方式:

- `articles.body` の送信元は既存textareaのまま維持する。
- Markdown記事ではMarkdown textareaとMarkdown Previewを維持する。
- Rich text記事ではJoditがtextareaを編集UIへ置き換え、submit前にJodit HTMLを同じtextareaへ同期する。
- validation失敗後は、serverから返った `article.body` をtextareaへ戻し、Joditがその内容で再初期化する。

Article validationへの影響:

- 既存のMarkdown plain text 400文字validationはMarkdown記事で維持する。
- Rich text記事ではHTML tagを文字数に含めないよう、validation用にRails標準のfull sanitizerで表示文字列を抽出する。
- これは公開表示用sanitizeではなく、本文文字数判定のための最小対応である。

Security上の前提:

- Jodit生成HTMLは安全と見なさない。
- Task 2では最終HTML sanitizer、`RichTextRenderer`、公開画面でのrich text HTML表示は未実装。
- 公開画面ではrich text bodyを危険にraw HTML表示しない。
- 画像、file upload、file browser、source編集、Base64画像挿入は有効化しない。
- Jodit配布file内にあった任意のsource editor向けCDN loader URLは、source pluginを無効化したうえでvendored fileからも除去した。
- Jodit本体にはupload/filebrowser用の通信処理が含まれるが、Task 2では関連button/plugin/URLを無効化し、自動通信しない構成とする。
- CSP initializerは現時点で未有効化のため変更しない。CDNを使用しないため、将来CSPを有効化する場合も基本は `self` 前提で検討できる。

Task 3への前提:

- 本文画像uploadは未実装。
- 次Taskでは認証済み管理者専用upload endpoint、CSRF、JPEG/PNG/WebP制限、Active Storage保存、Base64禁止を追加する。
- Joditのimage button、file browser、drag & drop uploadはTask 3で安全なendpointとvalidationを接続してから有効化する。


## Task 3 実装結果

実装日: 2026-07-27

採用Architecture:

- 本文画像は `Article` の `has_many_attached :body_images` として扱う。
- 未保存の新規記事でも画像を挿入できるよう、upload時点ではActive Storage blobを先に作成し、responseで `signed_id` を返す。
- 記事保存時に `article[body_image_signed_ids][]` を検証し、`rich_text` 記事へ未attachのblobだけをattachする。
- `articles.body` にはBase64ではなく、Active Storageのsigned blob routeへの画像URLを含むHTMLを保存する。
- サムネイル `thumbnail` とは別用途のattachmentとして分離する。

Upload endpoint:

- `POST /admin/article_images`
- Controller: `Admin::ArticleImagesController#create`
- 認証済み管理者のみ利用可能。
- 未認証時はJSONで `401 Unauthorized` を返し、公開側routeには露出しない。
- CSRF tokenはJodit uploaderから `X-CSRF-Token` headerで送信する。

Response形式:

```json
{
  "success": true,
  "url": "/rails/active_storage/blobs/redirect/.../sample.png",
  "signed_id": "...",
  "filename": "sample.png",
  "content_type": "image/png",
  "data": {
    "files": ["/rails/active_storage/blobs/redirect/.../sample.png"],
    "isImages": [true],
    "baseurl": "",
    "messages": [],
    "signed_ids": ["..."],
    "filename": "sample.png",
    "content_type": "image/png"
  }
}
```

失敗時は `success: false` と日本語error messageを返す。stack trace、storage内部path、secret、平文情報は返さない。

許可file形式:

- MIME type: `image/jpeg`, `image/png`, `image/webp`
- extension: `.jpg`, `.jpeg`, `.png`, `.webp`
- 最大容量: 5MB以下

拒否する形式:

- SVG
- GIF
- PDF
- HTML
- JavaScript等の未許可形式
- MIME typeと拡張子の組み合わせが一致しないfile
- 空file
- 5MB超過file

Validation:

- `ArticleBodyImageUpload` serviceでupload fileを検証する。
- content type、extension、byte sizeを確認する。
- JPEG / PNG / WebPは簡易signatureも確認し、明らかな偽装を拒否する。
- Active Storageのcontent type推定だけを無条件には信用しない。
- `Article` modelには本文画像用定数を置き、thumbnailの定数と同じ許可値を参照する。

Jodit接続:

- Task 2で無効化していた `image` buttonは、Task 3でcustom controlとして有効化した。
- image buttonはローカルfile選択だけを起動し、URL入力、file browser、Base64挿入は提供しない。
- upload成功後、Joditの現在位置へ `img` を挿入し、textareaへ同期する。
- upload済みblobの `signed_id` はhidden fieldとして保持し、validation失敗後も再表示できる。
- Markdown記事ではJodit画像upload UIを表示しない。

URL方式:

- `rails_blob_path(blob, only_path: true)` を返す。
- same-originのActive Storage signed routeを使い、独自の推測可能なstorage pathや外部URLは返さない。
- 本文HTMLへ `data:` URLや外部画像URLを挿入しない。

未保存記事とorphan blob:

- 新規記事保存前の画像uploadは許可する。
- upload後に記事作成を中止した場合、unattached blobが残る可能性がある。
- 本Taskでは本格cleanup jobは実装しない。
- 納品前または運用Taskで、24時間以上未attachのblobを `ActiveStorage::Blob.unattached` からpurgeする運用を追加検討する。

Security:

- 認証済み管理者のみupload可能。
- CSRF tokenを必須にする。
- SVG、GIF、PDF、HTML、MIME偽装、拡張子偽装、空file、容量超過を拒否する。
- Base64画像保存をしない。
- 外部画像URL入力、file browser、source編集は引き続き無効。
- Jodit生成HTMLはまだ安全と見なさない。最終sanitizeと公開画面でのrich text renderingはTask 5で実装する。

Task 4への前提:

- 画像サイズ変更は未実装。
- Task 4ではJoditのresize操作と、sanitize後にも保持できる `width` / `height` または限定style方針を確定する。
- 元画像は加工せず、表示サイズのみ本文HTMLへ保存する方針を維持する。


## Task 4 実装結果

実装日: 2026-07-27

採用方式:

- Jodit標準の `resizer` pluginを使用する。
- resize対象は本文内の `img` に限定する。
- 元画像ファイルは変更しない。
- 本文HTMLには表示サイズとして `width` / `height` 属性を保存する。
- `style` attributeは画像dimension保存の正本にしない。

Jodit設定:

- `allowResizeTags: new Set(["img"])`
- `resizer.forImageChangeAttributes: true`
- `resizer.useAspectRatio: new Set(["img"])`
- `resizer.min_width: 20`
- `resizer.min_height: 20`

保存時の正規化:

- form submit前とeditor同期時に、本文HTML内の `img` を正規化する。
- `width` / `height` は正の整数、または `px` 付き整数だけを許可し、属性値は整数文字列へ揃える。
- `0`、負数、百分率、任意style値は保存用HTMLから除去する。
- `img` の `style` attributeは削除する。
- 文字色・文字サイズなど、画像以外のstyleはTask 5 sanitizerまで既存方針を維持する。

Responsive方針:

- 管理画面editor内の画像はCSSで `max-width: 100%; height: auto;` を適用する。
- Mobile相当幅でもeditorの親幅を超えない。
- 公開画面でのrich text HTML renderingはTask 5のScopeであり、本Taskでは公開表示へ接続しない。

保持されること:

- 画像upload後に表示サイズを変更できる。
- 保存後のHTMLに `width` / `height` が残る。
- 再編集時に保存済みdimensionを読み戻せる。
- validation失敗後も画像URL、blob `signed_id`、`width` / `height` を保持する。

Security:

- Base64画像は引き続き使用しない。
- 外部画像URL入力、file browser、source編集は引き続き無効。
- 任意styleを画像サイズ保存として信用しない。
- 最終HTML sanitizerと公開画面でのrich text renderingはTask 5で実装する。

未対応:

- 画像ファイル自体の縮小・再生成。
- トリミング、回転、反転、色補正、filter、画像への文字入れ。
- orphan blob cleanup。
- RichTextRenderer、最終HTML sanitizer、公開画面でのrich text HTML表示。

Task 5への前提:

- Task 5 sanitizerでは `img[src]` にActive Storage signed routeだけを許可する。
- `img[width]` / `img[height]` は正の整数のみ許可する。
- `img[style]` は原則許可しない。
- 公開表示CSSでも `max-width: 100%; height: auto;` を適用する。


## 参考情報

- Jodit GitHub repository: https://github.com/xdan/jodit
- Jodit npm package: https://www.npmjs.com/package/jodit
- Jodit uploader options: https://xdsoft.net/jodit/docs/interfaces/types.IUploaderOptions.html
- Jodit image plugin: https://xdsoft.net/jodit/docs/modules/plugins_image.html
- Jodit Base64 upload example: https://xdsoft.net/jodit/examples/another/image-upload-base64.html
