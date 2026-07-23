require "test_helper"

%w[HTTP_PROXY HTTPS_PROXY http_proxy https_proxy].each do |key|
  ENV.delete(key) if ENV[key].blank?
end

ENV["NO_PROXY"] = [ ENV["NO_PROXY"], "localhost", "127.0.0.1" ].compact_blank.join(",")
ENV["no_proxy"] = [ ENV["no_proxy"], "localhost", "127.0.0.1" ].compact_blank.join(",")

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
end
