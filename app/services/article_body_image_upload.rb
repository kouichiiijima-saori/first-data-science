class ArticleBodyImageUpload
  Result = Struct.new(:success, :blob, :errors, keyword_init: true) do
    def success?
      success
    end

    def error_message
      errors.first
    end
  end

  SIGNATURE_BYTES = 12

  class << self
    def call(file)
      new(file).call
    end

    def valid_blob?(blob)
      Article::BODY_IMAGE_ALLOWED_CONTENT_TYPES.include?(blob.content_type.to_s.downcase) &&
        Article::BODY_IMAGE_ALLOWED_EXTENSIONS.include?(blob.filename.extension_without_delimiter.to_s.downcase) &&
        blob.byte_size.positive? &&
        blob.byte_size <= Article::BODY_IMAGE_MAX_BYTE_SIZE
    end
  end

  def initialize(file)
    @file = file
    @errors = []
  end

  def call
    validate
    return failure if errors.any?

    blob = ActiveStorage::Blob.create_and_upload!(
      io: upload_io,
      filename: normalized_filename,
      content_type: content_type,
      identify: true
    )

    Result.new(success: true, blob: blob, errors: [])
  rescue StandardError
    errors << I18n.t("admin.article_images.errors.upload_failed") if errors.empty?
    failure
  end

  private
    attr_reader :file, :errors

    def validate
      if file.blank?
        errors << I18n.t("admin.article_images.errors.missing_file")
        return
      end

      errors << I18n.t("admin.article_images.errors.empty_file") unless byte_size.positive?
      errors << I18n.t("admin.article_images.errors.file_too_large") if byte_size > Article::BODY_IMAGE_MAX_BYTE_SIZE
      errors << I18n.t("admin.article_images.errors.invalid_content_type") unless allowed_content_type?
      errors << I18n.t("admin.article_images.errors.invalid_extension") unless allowed_extension?
      errors << I18n.t("admin.article_images.errors.invalid_signature") unless valid_signature?
    end

    def allowed_content_type?
      Article::BODY_IMAGE_ALLOWED_CONTENT_TYPES.include?(content_type)
    end

    def allowed_extension?
      Article::BODY_IMAGE_ALLOWED_EXTENSIONS.include?(extension)
    end

    def valid_signature?
      return false unless allowed_content_type?

      header = read_header

      case content_type
      when "image/jpeg"
        header.start_with?("\xFF\xD8\xFF".b)
      when "image/png"
        header.start_with?("\x89PNG\r\n\x1A\n".b)
      when "image/webp"
        header.start_with?("RIFF".b) && header.byteslice(8, 4) == "WEBP".b
      else
        false
      end
    end

    def read_header
      io = upload_io
      io.rewind if io.respond_to?(:rewind)
      header = io.read(SIGNATURE_BYTES).to_s.b
      io.rewind if io.respond_to?(:rewind)
      header
    end

    def upload_io
      io = file.respond_to?(:tempfile) ? file.tempfile : file
      io.rewind if io.respond_to?(:rewind)
      io
    end

    def byte_size
      return file.size if file.respond_to?(:size)

      upload_io.size
    end

    def content_type
      file.content_type.to_s.downcase
    end

    def extension
      ActiveStorage::Filename.new(normalized_filename).extension_without_delimiter.to_s.downcase
    end

    def normalized_filename
      @normalized_filename ||= ActiveStorage::Filename.new(original_filename).sanitized
    end

    def original_filename
      if file.respond_to?(:original_filename) && file.original_filename.present?
        file.original_filename
      elsif file.respond_to?(:path) && file.path.present?
        File.basename(file.path)
      else
        "body-image"
      end
    end

    def failure
      Result.new(success: false, blob: nil, errors: errors)
    end
end
