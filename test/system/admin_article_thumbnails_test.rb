require "application_system_test_case"

class AdminArticleThumbnailsTest < ApplicationSystemTestCase
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
  end

  test "thumbnail form shows upload constraints" do
    login_as_admin
    visit new_admin_article_path

    assert_selector "input[name='article[thumbnail]'][accept='image/jpeg,image/png,image/webp']"
    assert_text "JPEG・PNG・WebP、5MB以下"
  end

  test "creates article with allowed thumbnail" do
    login_as_admin
    visit new_admin_article_path

    fill_article_form
    attach_file "サムネイル画像", Rails.root.join("test/fixtures/files/sample.jpg")
    click_button "保存する"

    assert_text "記事を作成しました"
    article = Article.find_by!(title: "System Thumbnail Article")
    assert article.thumbnail.attached?
  end

  test "shows japanese error for invalid thumbnail" do
    login_as_admin
    visit new_admin_article_path

    fill_article_form
    attach_file "サムネイル画像", Rails.root.join("test/fixtures/files/sample.html")
    click_button "保存する"

    assert_text "サムネイル画像はJPEG、PNG、WebP形式のみアップロードできます"
    assert_equal "System Thumbnail Article", find_field("タイトル").value
    assert_nil Article.find_by(title: "System Thumbnail Article")
  end

  test "thumbnail form displays at mobile width" do
    page.driver.browser.manage.window.resize_to(390, 844)
    login_as_admin
    visit new_admin_article_path

    assert_selector "input[name='article[thumbnail]'][accept='image/jpeg,image/png,image/webp']"
    assert_text "JPEG・PNG・WebP、5MB以下"
    assert_selector "textarea[name='article[body]']"
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  private
    def login_as_admin
      visit admin_login_path
      fill_in "メールアドレス", with: @admin.email
      fill_in "パスワード", with: "password123"
      click_button "ログイン"
      assert_text "記事管理"
    end

    def fill_article_form
      fill_in "タイトル", with: "System Thumbnail Article"
      fill_in "概要", with: "System thumbnail summary"
      fill_in "本文 (Markdown)", with: "本文" * 200
      fill_in "タグ", with: "Python"
      select "公開中 (published)", from: "公開状態"
    end
end
