require "application_system_test_case"

class Admin::ArticlesPreviewTest < ApplicationSystemTestCase
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
    @article = Article.create!(
      title: "Existing Article",
      summary: "Existing summary",
      body: "本文" * 200,
      status: "draft"
    )
  end

  def login_as_admin
    visit admin_login_path
    fill_in "メールアドレス", with: @admin.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"
    assert_text "記事管理" # ログイン完了を待機
  end

  test "preview markdown on new article form" do
    login_as_admin
    visit new_admin_article_path

    assert_text "まだプレビューされていません"

    click_button "プレビューを実行する"
    assert_text "本文が入力されていません。Markdownを入力してからプレビューを実行してください。"

    markdown_input = "# 見出し1\n\n- リスト1\n- リスト2\n<script>alert('xss')</script>"
    fill_in "本文 (Markdown)", with: markdown_input

    assert_no_difference("Article.count") do
      click_button "プレビューを実行する"

      within(".preview-area [data-markdown-preview-target='preview']") do
        assert_selector "h1", text: "見出し1"
        assert_selector "li", text: "リスト1"
        assert_selector "li", text: "リスト2"
        # scriptタグがサニタイズされている（そのまま実行・表示されない）ことを確認
        assert_no_selector "script", visible: false
        assert_no_text "alert('xss')" # XSSの文字列が完全に除去されるか、または無害化されていればOKですが、今回は除去される仕様なのでno_textで検証
      end
    end

    # プレビュー後も入力値が維持されていること
    assert_equal markdown_input, find_field("本文 (Markdown)").value
  end

  test "preview markdown on edit article form" do
    login_as_admin
    visit edit_admin_article_path(@article)

    assert_text "まだプレビューされていません"

    markdown_input = "## 見出し2\n\n**太字**です"
    fill_in "本文 (Markdown)", with: markdown_input

    original_body = @article.body
    original_updated_at = @article.updated_at

    click_button "プレビューを実行する"

    within(".preview-area [data-markdown-preview-target='preview']") do
      assert_selector "h2", text: "見出し2"
      assert_selector "strong", text: "太字"
    end

    # DBの状態が変わっていないこと
    @article.reload
    assert_equal original_body, @article.body
    assert_equal original_updated_at, @article.updated_at

    # プレビュー後も入力値が維持されていること
    assert_equal markdown_input, find_field("本文 (Markdown)").value
  end
end
