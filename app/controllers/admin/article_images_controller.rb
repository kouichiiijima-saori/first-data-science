class Admin::ArticleImagesController < Admin::BaseController
  def create
    result = ArticleBodyImageUpload.call(image_param)

    if result.success?
      render json: success_payload(result.blob), status: :created
    else
      render json: error_payload(result.error_message), status: :unprocessable_entity
    end
  end

  private
    def require_admin
      return if admin_logged_in?

      render json: error_payload("ログインしてください"), status: :unauthorized
    end

    def image_param
      params[:image]
    end

    def success_payload(blob)
      url = rails_blob_path(blob, only_path: true)

      {
        success: true,
        url: url,
        signed_id: blob.signed_id,
        filename: blob.filename.to_s,
        content_type: blob.content_type,
        data: {
          files: [ url ],
          isImages: [ true ],
          baseurl: "",
          messages: [],
          signed_ids: [ blob.signed_id ],
          filename: blob.filename.to_s,
          content_type: blob.content_type
        }
      }
    end

    def error_payload(message)
      {
        success: false,
        error: message,
        data: {
          messages: [ message ]
        }
      }
    end
end
