module Admin::ArticlesHelper
  def admin_datetime(datetime)
    return "" if datetime.blank?

    l(datetime.in_time_zone, format: :admin_datetime)
  end
end
