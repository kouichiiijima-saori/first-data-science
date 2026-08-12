require "test_helper"
require Rails.root.join("db/seeds/articles").to_s

class ArticleSeedTest < ActiveSupport::TestCase
  EXPECTED_TITLES = [
    "1. データサイエンスとは？身近な例から学ぼう",
    "2. データ分析はどのように進めるのか",
    "3. データ分析で使われるPythonとは",
    "4. Pythonの基本文法を読んでみよう",
    "5. リスト・辞書・条件分岐・繰り返し",
    "7. データ前処理とデータクリーニングの基本",
    "6. CSVと表形式データの基本を知ろう",
    "8. 平均値・中央値・最頻値とばらつきの基本",
    "9. データ可視化とグラフの使い分け",
    "10. カフェの売上データで分析の流れを体験しよう"
  ].freeze

  EXPECTED_BODY_IMAGES = {
    6 => [ "07-data-cleaning.png" ],
    7 => [ "06-csv-to-table.png" ],
    8 => [ "08-outliers-effect.png" ],
    9 => [ "09-four-charts.png" ]
  }.freeze

  setup do
    ActiveStorage::Attachment.delete_all
    ActiveStorage::Blob.delete_all
    ArticleTag.delete_all
    Article.delete_all
    Tag.delete_all
  end

  test "creates official articles and images from tracked sources" do
    assert_difference -> { Article.count }, 10 do
      capture_io { Seeds::Articles.load }
    end

    articles = Article.order(:display_order, :id).to_a
    assert_equal (1..10).to_a, articles.map(&:display_order)
    assert_equal EXPECTED_TITLES, articles.map(&:title)
    assert_equal Array.new(5, "markdown") + Array.new(5, "rich_text"), articles.map(&:editor_type)
    assert_equal Array.new(10, "published"), articles.map(&:status)
    assert_equal 5, articles.count { |article| article.thumbnail.attached? }
    assert_equal 4, articles.sum { |article| article.body_images.count }
    assert_equal 9, ActiveStorage::Attachment.count
    assert_equal 9, ActiveStorage::Blob.count
    assert_equal 0, unattached_blob_count

    articles.each do |article|
      assert_no_forbidden_seed_reference(article.body)
      expected_body_images = EXPECTED_BODY_IMAGES.fetch(article.display_order, [])
      assert_equal expected_body_images, article.body_images.map { |image| image.blob.filename.to_s }
      assert_body_image_references(article, expected_body_images)
    end
  end

  test "does not create duplicate articles or blobs when run again" do
    capture_io { Seeds::Articles.load }
    counts = seed_counts

    stdout, = capture_io { Seeds::Articles.load }

    assert_includes stdout, "Article seed skipped: articles already exist."
    assert_equal counts, seed_counts
  end

  private
    def seed_counts
      {
        articles: Article.count,
        tags: Tag.count,
        attachments: ActiveStorage::Attachment.count,
        blobs: ActiveStorage::Blob.count,
        unattached_blobs: unattached_blob_count
      }
    end

    def unattached_blob_count
      ActiveStorage::Blob.left_outer_joins(:attachments).where(active_storage_attachments: { id: nil }).count
    end

    def assert_no_forbidden_seed_reference(body)
      forbidden_patterns = [
        "localhost",
        "/home/kouic",
        "tmp/",
        "signed_id",
        "blob_id"
      ]

      forbidden_patterns.each do |pattern|
        assert_not_includes body.to_s, pattern
      end
    end

    def assert_body_image_references(article, expected_body_images)
      refs = article.body.to_s.scan(%r{<img[^>]+src=["']([^"']+)["']}i).flatten
      assert_equal expected_body_images.size, refs.size

      expected_body_images.zip(refs).each do |filename, src|
        assert_includes src, "/rails/active_storage/blobs/"
        assert_includes src, filename
      end
    end
end
