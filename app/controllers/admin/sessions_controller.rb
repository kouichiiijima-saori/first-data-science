class Admin::SessionsController < ApplicationController
  AUTHENTICATION_ERROR_MESSAGE = "ログイン情報が正しくありません".freeze

  before_action :redirect_if_logged_in, only: %i[new create]
  before_action :require_admin, only: :destroy

  def new
  end

  def create
    admin = Admin.find_by(email: normalized_email)

    if admin&.authenticate(params[:password].to_s)
      reset_session
      session[:admin_id] = admin.id
      redirect_to admin_root_path, notice: "ログインしました"
    else
      session.delete(:admin_id)
      @email = normalized_email
      flash.now[:alert] = AUTHENTICATION_ERROR_MESSAGE
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to admin_login_path, notice: "ログアウトしました"
  end

  private
    def normalized_email
      params[:email].to_s.strip.downcase
    end

    def redirect_if_logged_in
      admin_id = session[:admin_id]
      return if admin_id.blank?

      redirect_to admin_root_path if Admin.exists?(id: admin_id)
    end

    def require_admin
      admin_id = session[:admin_id]
      return if admin_id.present? && Admin.exists?(id: admin_id)

      redirect_to admin_login_path, alert: "ログインしてください"
    end
end
