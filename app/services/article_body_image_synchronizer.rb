require "cgi"
require "nokogiri"
require "set"
require "uri"

class ArticleBodyImageSynchronizer
  class << self
    def call(article)
      new(article).call
    end
  end

  def initialize(article)
    @article = article
  end

  def call
    return result(0, 0, 0) unless @article.persisted? && @article.editor_type == "rich_text"

    referenced_blob_ids = extract_referenced_blob_ids

    detached_count = 0
    purged_count = 0
    errors_count = 0

    @article.body_images.attachments.to_a.each do |attachment|
      next if referenced_blob_ids.include?(attachment.blob_id)

      blob_id = attachment.blob_id
      begin
        attachment.purge_later
        detached_count += 1

        if completely_unattached_blob?(blob_id)
          purged_count += 1
        end
      rescue StandardError => e
        errors_count += 1
        Rails.logger.error("[ArticleBodyImageSynchronizer] Error detaching/purging blob #{blob_id}: #{e.message}")
      end
    end

    result(detached_count, purged_count, errors_count)
  rescue StandardError => e
    Rails.logger.error("[ArticleBodyImageSynchronizer] Unexpected error for article #{@article.id}: #{e.message}")
    result(0, 0, 1)
  end

  private
    def result(detached, purged, errors)
      {
        detached_count: detached,
        purged_count: purged,
        errors_count: errors
      }
    end

    def extract_referenced_blob_ids
      blob_ids = Set.new
      return blob_ids if @article.body.blank?

      fragment = Nokogiri::HTML5.fragment(@article.body.to_s)
      fragment.css("img[src]").each do |img|
        src = img["src"].to_s.strip
        blob = blob_from_src(src)
        blob_ids.add(blob.id) if blob
      end

      blob_ids
    rescue StandardError => e
      Rails.logger.error("[ArticleBodyImageSynchronizer] HTML parsing error for article #{@article.id}: #{e.message}")
      blob_ids
    end

    def blob_from_src(src)
      return nil if src.blank? || src.start_with?("//")

      uri = URI.parse(src)
      path = uri.path.to_s
      segments = path.split("/")
      return nil unless segments[1] == "rails" && segments[2] == "active_storage" && segments[3] == "blobs"

      signed_id = if %w[redirect proxy].include?(segments[4])
        segments[5]
      else
        segments[4]
      end
      return nil if signed_id.blank?

      ActiveStorage::Blob.find_signed(CGI.unescape(signed_id))
    rescue URI::InvalidURIError, ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def completely_unattached_blob?(blob_id)
      !ActiveStorage::Attachment.where(blob_id: blob_id).exists?
    end
end
