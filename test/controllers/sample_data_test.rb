require "test_helper"

class SampleDataTest < ActionDispatch::IntegrationTest
  test "sales data csv is publicly available and matches docs source" do
    get "/sample-data/sales_data.csv"

    assert_response :success
    assert_equal "text/csv", response.media_type

    public_body = response.body
    docs_body = Rails.root.join("docs/sample-data/sales_data.csv").binread
    assert_equal docs_body, public_body.b

    lines = public_body.dup.force_encoding("UTF-8").lines.map(&:chomp)
    headers = lines.first.split(",")
    rows = lines.drop(1).map { |line| headers.zip(line.split(",")).to_h }

    assert_equal 16, rows.length
    assert_equal %w[date product category quantity unit_price sales], headers
    assert rows.all? { |row| row["sales"].to_i == row["quantity"].to_i * row["unit_price"].to_i }
  end
end
