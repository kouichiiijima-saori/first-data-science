require "application_system_test_case"

class AdminArticleInputLimitsTest < ApplicationSystemTestCase
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
  end

  test "article form shows maxlength attributes and input limit help" do
    login_as_admin
    visit new_admin_article_path

    assert_selector "input[name='article[title]'][maxlength='#{Article::TITLE_MAX_LENGTH}']"
    assert_selector "textarea[name='article[summary]'][maxlength='#{Article::SUMMARY_MAX_LENGTH}']"
    assert_selector "textarea[name='article[body]'][maxlength='#{Article::BODY_MAX_LENGTH}']"
    assert_text "タイトルは120文字以内"
    assert_text "概要は500文字以内"
    assert_text "本文は表示上の文字数で400文字以上、Markdown原文で最大15,000文字以内"
    assert_text "タグは1件50文字以内、最大10件"
  end

  test "shows japanese errors and keeps input when server side limits are exceeded" do
    login_as_admin
    visit new_admin_article_path

    fill_in "タイトル", with: "通常タイトル"
    fill_in "概要", with: "通常概要"
    fill_in "本文 (Markdown)", with: "本文" * 200
    fill_in "タグ", with: tag_names(11).join(", ")
    remove_length_limits
    set_field_value("article_title", "あ" * (Article::TITLE_MAX_LENGTH + 1))
    click_button "保存する"

    assert_text "タイトルは120文字以内で入力してください"
    assert_text "タグは10件以内で入力してください"
    assert_equal "あ" * (Article::TITLE_MAX_LENGTH + 1), find_field("タイトル").value
    assert_nil Article.find_by(title: "通常タイトル")
  end

  test "article form displays at mobile width" do
    page.driver.browser.manage.window.resize_to(390, 844)
    login_as_admin
    visit new_admin_article_path

    assert_text "タグは1件50文字以内、最大10件"
    assert_selector "textarea[name='article[body]'][maxlength='#{Article::BODY_MAX_LENGTH}']"
    assert_button "プレビューを実行する"
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

    def remove_length_limits
      page.execute_script(<<~JS)
        document.querySelectorAll('[maxlength]').forEach((element) => element.removeAttribute('maxlength'))
      JS
    end

    def set_field_value(id, value)
      page.execute_script("document.getElementById(arguments[0]).value = arguments[1]", id, value)
    end

    def tag_names(count)
      Array.new(count) { |index| "Tag%02d" % (index + 1) }
    end
end
