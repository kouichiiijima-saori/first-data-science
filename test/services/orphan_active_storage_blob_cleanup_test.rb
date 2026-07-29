require "test_helper"

class OrphanActiveStorageBlobCleanupTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
  end

  test "cleans up unattached blobs created before 7 days ago" do
    old_unattached = create_body_image_blob("sample.png")
    old_unattached.update_column(:created_at, 8.days.ago)

    recent_unattached = create_body_image_blob("sample.png")
    recent_unattached.update_column(:created_at, 2.days.ago)

    attached_blob = create_body_image_blob("sample.png")
    attached_blob.update_column(:created_at, 10.days.ago)
    article = Article.create!(
      title: "Attached Test Article",
      summary: "Summary text",
      body: "<h2>見出し</h2><p>#{'本文' * 200}</p>",
      status: "draft",
      editor_type: "rich_text"
    )
    article.body_images.attach(attached_blob)

    perform_enqueued_jobs do
      result = OrphanActiveStorageBlobCleanup.call(days: 7, dry_run: false)
      assert_equal false, result[:dry_run]
      assert_equal 1, result[:target_count]
      assert_equal 1, result[:enqueued_count]
      assert_includes result[:target_blob_ids], old_unattached.id
    end

    assert_not ActiveStorage::Blob.exists?(old_unattached.id)
    assert ActiveStorage::Blob.exists?(recent_unattached.id)
    assert ActiveStorage::Blob.exists?(attached_blob.id)
  end

  test "dry run mode reports targets without purging any blob" do
    old_unattached = create_body_image_blob("sample.png")
    old_unattached.update_column(:created_at, 10.days.ago)

    result = OrphanActiveStorageBlobCleanup.call(days: 7, dry_run: true)

    assert_equal true, result[:dry_run]
    assert_equal 1, result[:target_count]
    assert_equal 0, result[:enqueued_count]
    assert_equal old_unattached.byte_size, result[:target_total_bytes]
    assert_includes result[:target_blob_ids], old_unattached.id

    assert ActiveStorage::Blob.exists?(old_unattached.id)
  end

  test "falls back safely to default 7 days when days parameter is invalid or unsafe (0 or negative)" do
    recent_unattached = create_body_image_blob("sample.png")
    recent_unattached.update_column(:created_at, 2.hours.ago)

    old_unattached = create_body_image_blob("sample.png")
    old_unattached.update_column(:created_at, 8.days.ago)

    perform_enqueued_jobs do
      result = OrphanActiveStorageBlobCleanup.call(days: 0, dry_run: false)
      # Should fallback to default 7 days and NOT target the 2 hours ago blob
      assert_equal 1, result[:target_count]
      assert_includes result[:target_blob_ids], old_unattached.id
      assert_not_includes result[:target_blob_ids], recent_unattached.id
    end

    assert ActiveStorage::Blob.exists?(recent_unattached.id)
    assert_not ActiveStorage::Blob.exists?(old_unattached.id)
  end

  test "skips blob if attached immediately before purge execution" do
    target_blob = create_body_image_blob("sample.png")
    target_blob.update_column(:created_at, 10.days.ago)

    article = Article.create!(
      title: "Race Condition Article",
      summary: "Summary text",
      body: "<h2>見出し</h2><p>#{'本文' * 200}</p>",
      status: "draft",
      editor_type: "rich_text"
    )

    cleanup = OrphanActiveStorageBlobCleanup.new(days: 7, dry_run: false)

    # Before attaching, blob is unattached and eligible:
    assert cleanup.send(:unattached_and_eligible?, target_blob, 7.days.ago)

    # Attach blob (simulating race condition right before purge check):
    article.body_images.attach(target_blob)

    # Now unattached_and_eligible? returns false (skips blob):
    assert_not cleanup.send(:unattached_and_eligible?, target_blob, 7.days.ago)
  end

  test "handles empty target list gracefully" do
    result = OrphanActiveStorageBlobCleanup.call(days: 7, dry_run: false)
    assert_equal 0, result[:target_count]
    assert_equal 0, result[:enqueued_count]
    assert_equal 0, result[:skipped_count]
    assert_equal 0, result[:error_count]
  end

  private
    def create_body_image_blob(filename)
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("test/fixtures/files", filename)),
        filename: filename,
        content_type: "image/png"
      )
    end
end
