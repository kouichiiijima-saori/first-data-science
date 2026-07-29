namespace :article_body_images do
  desc "Cleanup unattached Active Storage blobs older than grace period (default: 7 days)"
  task cleanup_orphans: :environment do
    dry_run = ENV["DRY_RUN"].to_s.downcase == "true"
    age_days = ENV["ORPHAN_AGE_DAYS"]

    result = OrphanActiveStorageBlobCleanup.call(
      days: age_days,
      dry_run: dry_run
    )

    mode_label = result[:dry_run] ? "[DRY RUN]" : "[EXECUTE]"
    puts "#{mode_label} Orphan Blob cleanup finished."
    puts "Cutoff time:      #{result[:cutoff_time].iso8601}"
    puts "Target count:     #{result[:target_count]}"
    puts "Target capacity:  #{result[:target_total_bytes]} bytes"
    puts "Enqueued count:   #{result[:enqueued_count]}"
    puts "Skipped count:    #{result[:skipped_count]}"
    puts "Error count:      #{result[:error_count]}"
  end
end
