class OrphanActiveStorageBlobCleanup
  DEFAULT_GRACE_PERIOD_DAYS = 7
  MINIMUM_GRACE_PERIOD_DAYS = 1

  class << self
    def call(days: nil, dry_run: false)
      new(days: days, dry_run: dry_run).call
    end
  end

  def initialize(days: nil, dry_run: false)
    @days_param = days
    @dry_run = dry_run.to_s.downcase == "true" || dry_run == true
  end

  def call
    grace_days = resolve_grace_period_days
    cutoff_time = grace_days.days.ago

    target_blobs = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at < ?", cutoff_time).to_a
    target_count = target_blobs.size
    target_total_bytes = target_blobs.sum(&:byte_size)
    target_blob_ids = target_blobs.map(&:id)

    enqueued_count = 0
    skipped_count = 0
    error_count = 0

    if @dry_run
      Rails.logger.info("[OrphanActiveStorageBlobCleanup] DRY RUN: cutoff=#{cutoff_time.iso8601}, target_count=#{target_count}, total_bytes=#{target_total_bytes}, blob_ids=#{target_blob_ids.inspect}")
    else
      target_blobs.each do |blob|
        begin
          if unattached_and_eligible?(blob, cutoff_time)
            blob.purge_later
            enqueued_count += 1
          else
            skipped_count += 1
            Rails.logger.info("[OrphanActiveStorageBlobCleanup] Skipped blob #{blob.id} (attached or modified)")
          end
        rescue StandardError => e
          error_count += 1
          Rails.logger.error("[OrphanActiveStorageBlobCleanup] Error purging blob #{blob.id}: #{e.message}")
        end
      end

      Rails.logger.info("[OrphanActiveStorageBlobCleanup] EXECUTE: cutoff=#{cutoff_time.iso8601}, target_count=#{target_count}, total_bytes=#{target_total_bytes}, enqueued=#{enqueued_count}, skipped=#{skipped_count}, errors=#{error_count}")
    end

    {
      dry_run: @dry_run,
      cutoff_time: cutoff_time,
      target_count: target_count,
      target_total_bytes: target_total_bytes,
      enqueued_count: enqueued_count,
      skipped_count: skipped_count,
      error_count: error_count,
      target_blob_ids: target_blob_ids
    }
  end

  private
    def resolve_grace_period_days
      raw_val = @days_param.presence || ENV["ORPHAN_AGE_DAYS"]
      parsed = raw_val.to_i if raw_val.to_s.strip.match?(/\A\d+\z/)

      if parsed && parsed >= MINIMUM_GRACE_PERIOD_DAYS
        parsed
      else
        if raw_val.present?
          Rails.logger.warn("[OrphanActiveStorageBlobCleanup] Invalid or unsafe ORPHAN_AGE_DAYS='#{raw_val}'. Fallback to #{DEFAULT_GRACE_PERIOD_DAYS} days.")
        end
        DEFAULT_GRACE_PERIOD_DAYS
      end
    end

    def unattached_and_eligible?(blob, cutoff_time)
      blob.reload
      !blob.attachments.exists? && blob.created_at < cutoff_time
    rescue ActiveRecord::RecordNotFound
      false
    end
end
