require "application_system_test_case"

class AdminArticleEditorTypesTest < ApplicationSystemTestCase
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
    @article = Article.create!(
      title: "Existing Markdown Article",
      summary: "Existing summary",
      body: "本文" * 200,
      status: "draft"
    )
  end

  test "selects editor type on new article form" do
    login_as_admin
    visit new_admin_article_path

    assert_selector "select[name='article[editor_type]']"
    assert_text "リッチテキストエディターは次のTaskで追加予定"

    select "リッチテキスト", from: "編集方式"
    fill_in "タイトル", with: "Rich Text Article"
    fill_in "概要", with: "Rich text summary"
    fill_in "本文 (Markdown)", with: "本文" * 200
    select "公開中 (published)", from: "公開状態"
    click_button "保存する"

    assert_text "記事を作成しました"
    article = Article.find_by!(title: "Rich Text Article")
    assert_equal "rich_text", article.editor_type
  end

  test "shows fixed editor type on existing markdown article edit form" do
    login_as_admin
    visit edit_admin_article_path(@article)

    assert_text "保存済み記事の編集方式は変更できません"
    assert_selector "select[name='article[editor_type]'][disabled]"
    editor_type_select = find("select[name='article[editor_type]']")
    assert editor_type_select.disabled?
    assert_equal "markdown", editor_type_select.value
  end

  test "keeps markdown preview working on existing article edit form" do
    login_as_admin
    visit edit_admin_article_path(@article)

    fill_in "本文 (Markdown)", with: "# 見出し\n\n#{'本文' * 200}"
    click_button "プレビューを実行する"

    within(".preview-area [data-markdown-preview-target='preview']") do
      assert_selector "h1", text: "見出し"
    end
  end

  test "prevents unsafe editor type change on existing article" do
    login_as_admin
    visit edit_admin_article_path(@article)

    page.execute_script(<<~JS)
      const editorType = document.querySelector("select[name='article[editor_type]']")
      editorType.disabled = false
      editorType.value = "rich_text"
    JS

    click_button "保存する"

    assert_text "編集方式は保存済み記事では変更できません"
    @article.reload
    assert_equal "markdown", @article.editor_type
    assert_equal "本文" * 200, @article.body
  end

  test "editor type control is visible at mobile width" do
    page.driver.browser.manage.window.resize_to(390, 844)
    login_as_admin
    visit new_admin_article_path

    assert_selector "select[name='article[editor_type]']"
    assert_text "Markdownまたはリッチテキストを選択できます"
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
end
