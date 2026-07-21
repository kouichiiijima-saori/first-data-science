class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :require_admin

  helper_method :current_admin, :admin_logged_in?

  private
    def current_admin
      @current_admin ||= Admin.find_by(id: session[:admin_id]) if session[:admin_id].present?
    end

    def admin_logged_in?
      current_admin.present?
    end

    def require_admin
      return if admin_logged_in?

      redirect_to admin_login_path, alert: "ログインしてください"
    end
end
