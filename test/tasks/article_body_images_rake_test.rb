require "test_helper"
require "rake"

class ArticleBodyImagesRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("article_body_images:cleanup_orphans")
    Rake::Task["article_body_images:cleanup_orphans"].reenable
  end

  test "rake article_body_images:cleanup_orphans runs successfully with DRY_RUN" do
    ENV["DRY_RUN"] = "true"
    ENV["ORPHAN_AGE_DAYS"] = "7"

    output = capture_io do
      Rake::Task["article_body_images:cleanup_orphans"].invoke
    end.join

    assert_includes output, "[DRY RUN]"
    assert_includes output, "Target count:"
    assert_includes output, "Target capacity:"
  ensure
    ENV.delete("DRY_RUN")
    ENV.delete("ORPHAN_AGE_DAYS")
  end
end
