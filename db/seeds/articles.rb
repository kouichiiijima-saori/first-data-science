module Seeds
  class Articles
    include Rails.application.routes.url_helpers

    SOURCE_DIR = Rails.root.join("docs/articles")
    ASSET_DIR = Rails.root.join("docs/assets/articles")
    PLACEHOLDER_PATTERN = /\{\{active_storage_blob_path:([^}]+)\}\}/

    ARTICLE_DATA = [
      {
        display_order: 1,
        title: "1. データサイエンスとは？身近な例から学ぼう",
        summary: "本記事では、プログラミングや数学の専門知識がなくても理解できるように、身近な例を通してデータサイエンスの基本概念と活用の流れを分かりやすく解説します。",
        tags: [ "データサイエンス", "入門", "初心者" ],
        status: "published",
        editor_type: "markdown",
        source: "01-data-science-introduction.md",
        thumbnail: "01-data-use-cases.png",
        body_images: []
      },
      {
        display_order: 2,
        title: "2. データ分析はどのように進めるのか",
        summary: "データ分析をどのような順序で進めればよいのか、目的設定からデータ収集・前処理・分析・可視化・活用までの基本的な6つのステップを、初心者向けにわかりやすく解説します。",
        tags: [ "データ分析", "入門", "初心者" ],
        status: "published",
        editor_type: "markdown",
        source: "02-data-analysis-process.md",
        thumbnail: "02-analysis-process.png",
        body_images: []
      },
      {
        display_order: 3,
        title: "3. データ分析で使われるPythonとは",
        summary: "データ分析でPythonがよく使われる理由や、pandas・NumPy・Matplotlib・scikit-learnなどの代表的なライブラリについて、初心者向けにわかりやすく紹介します。",
        tags: [ "Python", "データ分析", "初心者" ],
        status: "published",
        editor_type: "markdown",
        source: "03-python-for-data-analysis.md",
        thumbnail: "03-python-libraries.png",
        body_images: []
      },
      {
        display_order: 4,
        title: "4. Pythonの基本文法を読んでみよう",
        summary: "Pythonのコードを読むために必要な基本文法を、変数・データ型・簡単な計算・コメントの書き方を中心に、初心者向けにわかりやすく解説します。",
        tags: [ "Python", "初心者", "基本文法" ],
        status: "published",
        editor_type: "markdown",
        source: "04-python-basics.md",
        thumbnail: "04-variables-and-types.png",
        body_images: []
      },
      {
        display_order: 5,
        title: "5. リスト・辞書・条件分岐・繰り返し",
        summary: "Pythonで複数のデータを扱うためのリストや辞書の基本と、if文による条件分岐、for文による繰り返し処理について、初心者向けにわかりやすく解説します。",
        tags: [ "Python", "データ構造", "初心者" ],
        status: "published",
        editor_type: "markdown",
        source: "05-python-data-structures.md",
        thumbnail: "05-list-vs-dictionary.png",
        body_images: []
      },
      {
        display_order: 6,
        title: "7. データ前処理とデータクリーニングの基本",
        summary: "データ分析の精度を高めるために欠かせないデータ前処理について、欠損値・表記揺れ・重複・外れ値などの代表的な問題と、データを整える基本的な流れを初心者向けにわかりやすく解説します。",
        tags: [ "データクリーニング", "データ前処理", "初心者" ],
        status: "published",
        editor_type: "rich_text",
        source: "07-data-cleaning-rich-text.html",
        thumbnail: nil,
        body_images: [ "07-data-cleaning.png" ]
      },
      {
        display_order: 7,
        title: "6. CSVと表形式データの基本を知ろう",
        summary: "データ分析でよく使われる表形式データとCSVについて、行・列・ヘッダーの考え方、CSVファイルの仕組みや特徴、扱う際の注意点を初心者向けにわかりやすく解説します。",
        tags: [ "CSV", "データ分析", "初心者" ],
        status: "published",
        editor_type: "rich_text",
        source: "06-csv-tabular-data-rich-text.html",
        thumbnail: nil,
        body_images: [ "06-csv-to-table.png" ]
      },
      {
        display_order: 8,
        title: "8. 平均値・中央値・最頻値とばらつきの基本",
        summary: "データ全体の特徴をつかむために使われる平均値・中央値・最頻値の違いと、範囲や標準偏差などのばらつきの見方を、初心者向けにわかりやすく解説します。",
        tags: [ "初心者", "基本統計", "平均値" ],
        status: "published",
        editor_type: "rich_text",
        source: "08-basic-statistics-rich-text.html",
        thumbnail: nil,
        body_images: [ "08-outliers-effect.png" ]
      },
      {
        display_order: 9,
        title: "9. データ可視化とグラフの使い分け",
        summary: "データの特徴や傾向をわかりやすく伝えるための可視化について、棒グラフ・折れ線グラフ・散布図・ヒストグラムの特徴と使い分け、グラフ作成時の注意点を初心者向けに解説します。",
        tags: [ "グラフ", "データ可視化", "初心者" ],
        status: "published",
        editor_type: "rich_text",
        source: "09-data-visualization-rich-text.html",
        thumbnail: nil,
        body_images: [ "09-four-charts.png" ]
      },
      {
        display_order: 10,
        title: "10. カフェの売上データで分析の流れを体験しよう",
        summary: "これまで学んだデータ分析の基本を振り返りながら、架空のカフェ売上データを使って、データ確認・前処理・集計・グラフ化・考察までの一連の流れを初心者向けに体験します。",
        tags: [ "データ分析", "初心者", "総合演習" ],
        status: "published",
        editor_type: "rich_text",
        source: "10-simple-data-analysis-rich-text.html",
        thumbnail: nil,
        body_images: []
      }
    ].freeze

    class << self
      def load
        new.load
      end
    end

    def load
      if Article.exists?
        puts "Article seed skipped: articles already exist."
        return
      end

      Article.transaction do
        ARTICLE_DATA.each { |data| create_article(data) }
      end

      puts "Article seed created: #{ARTICLE_DATA.size} articles."
    end

    private
      def create_article(data)
        body_blobs = data[:body_images].to_h { |filename| [ filename, create_blob(filename) ] }
        article = Article.new(data.slice(:display_order, :title, :summary, :status, :editor_type))
        article.body = body_from_source(data, body_blobs)
        attach_thumbnail(article, data[:thumbnail]) if data[:thumbnail]
        article.save!
        article.tags = data[:tags].map { |name| Tag.find_or_create_by!(name: name) }
        article.body_images.attach(body_blobs.values) if body_blobs.any?
      end

      def body_from_source(data, body_blobs)
        body = File.read(SOURCE_DIR.join(data[:source]))
        return body if data[:editor_type] == "markdown"

        placeholders = body.scan(PLACEHOLDER_PATTERN).flatten
        expected = data[:body_images]
        if placeholders.sort != expected.sort
          raise "Body image placeholders mismatch in #{data[:source]}: expected #{expected.inspect}, got #{placeholders.inspect}"
        end

        body.gsub(PLACEHOLDER_PATTERN) do
          filename = Regexp.last_match(1)
          rails_blob_path(body_blobs.fetch(filename), only_path: true)
        end
      end

      def attach_thumbnail(article, filename)
        path = asset_path(filename)
        article.thumbnail.attach(io: File.open(path, "rb"), filename: filename, content_type: "image/png")
      end

      def create_blob(filename)
        path = asset_path(filename)
        ActiveStorage::Blob.create_and_upload!(
          io: File.open(path, "rb"),
          filename: filename,
          content_type: "image/png"
        )
      end

      def asset_path(filename)
        path = ASSET_DIR.join(filename)
        raise "Seed asset is missing: #{path}" unless File.file?(path)

        path
      end
  end
end
