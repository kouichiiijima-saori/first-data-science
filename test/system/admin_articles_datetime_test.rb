require "application_system_test_case"

class Admin::ArticlesDatetimeTest < ApplicationSystemTestCase
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
    @article = Article.create!(
      title: "日時確認記事",
      summary: "日時表示確認用の記事です",
      body: "本文" * 200,
      status: "draft"
    )
    @article.update_columns(updated_at: Time.utc(2026, 7, 22, 2, 1, 0))
  end

  test "admin article index shows updated time in japanese format on desktop width" do
    page.current_window.resize_to(1280, 900)
    login_as_admin
    visit admin_articles_path

    assert_selector "h1", text: "記事管理"
    assert_text "2026/07/22 11:01"
    assert_no_text "22 Jul 02:01"
    assert_no_text "Jul"
  end

  test "admin article index shows updated time in japanese format on mobile width" do
    page.current_window.resize_to(390, 844)
    login_as_admin
    visit admin_articles_path

    assert_selector "h1", text: "記事管理"
    assert_text "2026/07/22 11:01"
    assert_no_text "22 Jul 02:01"
    assert_no_text "Jul"
  end

  private
    def login_as_admin
      visit admin_login_path
      fill_in "メールアドレス", with: @admin.email
      fill_in "パスワード", with: "password123"
      click_button "ログイン"
      assert_text "記事管理"
    end
end
