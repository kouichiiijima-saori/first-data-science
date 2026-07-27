require "test_helper"

class Admin::ArticlesHelperTest < ActionView::TestCase
  test "formats datetime with admin datetime format in tokyo time" do
    assert_equal "2026/07/22 11:01", admin_datetime(Time.utc(2026, 7, 22, 2, 1, 0))
  end

  test "returns blank for nil datetime" do
    assert_equal "", admin_datetime(nil)
  end
end
