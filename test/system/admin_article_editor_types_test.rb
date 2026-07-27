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

  test "selects rich text editor on new article form and saves html body" do
    login_as_admin
    visit new_admin_article_path

    assert_selector "select[name='article[editor_type]']"
    assert_no_selector ".jodit-container"
    assert_selector "textarea#article_body_markdown:not([disabled])", visible: :all

    select "リッチテキスト", from: "編集方式"
    assert_rich_text_editor_ready
    assert_selector "textarea#article_body_markdown[disabled]", visible: :all
    assert_selector "textarea#article_body_rich_text:not([disabled])", visible: :all

    fill_in "タイトル", with: "Rich Text Article"
    fill_in "概要", with: "Rich text summary"
    set_rich_text_body(rich_text_body)
    select "公開中 (published)", from: "公開状態"
    click_button "保存する"

    assert_text "記事を作成しました"
    article = Article.find_by!(title: "Rich Text Article")
    assert_equal "rich_text", article.editor_type
    assert_equal rich_text_body, article.body
  end

  test "rich text editor exposes minimal toolbar configuration" do
    login_as_admin
    visit new_admin_article_path
    select "リッチテキスト", from: "編集方式"
    assert_rich_text_editor_ready

    buttons = rich_text_editor_option("buttons")
    assert_equal %w[paragraph fontsize brush underline link undo redo eraser], buttons
    assert_equal({ "p" => "通常段落", "h2" => "見出し2", "h3" => "見出し3", "h4" => "見出し4" }, rich_text_editor_option("controls")["paragraph"]["list"])
    assert_equal({ "0.875rem" => "小", "1rem" => "標準", "1.25rem" => "大", "1.5rem" => "特大" }, rich_text_editor_option("controls")["fontsize"]["list"])
    assert_equal [ "#111827", "#374151", "#2563EB", "#047857", "#B45309", "#B91C1C" ], rich_text_editor_option("colors")

    disabled_plugins = rich_text_editor_option("disablePlugins")
    assert_includes disabled_plugins, "image"
    assert_includes disabled_plugins, "file"
    assert_includes disabled_plugins, "video"
    assert_includes disabled_plugins, "source"
    assert_includes disabled_plugins, "table"
  end

  test "edits existing rich text article and keeps body after validation failure" do
    article = Article.create!(
      title: "Existing Rich Text Article",
      summary: "Existing rich text summary",
      body: rich_text_body,
      status: "draft",
      editor_type: "rich_text"
    )

    login_as_admin
    visit edit_admin_article_path(article)

    assert_text "保存済み記事の編集方式は変更できません"
    assert_rich_text_editor_ready
    updated_body = "<h2>更新見出し</h2><p>#{'本文' * 200}</p><p><u>下線</u><a href=\"https://example.com\">リンク</a></p>"
    fill_in "タグ", with: "あ" * 51
    set_rich_text_body(updated_body)
    click_button "保存する"

    assert_text "保存できませんでした"
    assert_text "タグ名は50文字以内で入力してください"
    assert_rich_text_editor_ready
    assert_equal updated_body, rich_text_source_value
    article.reload
    assert_equal "Existing Rich Text Article", article.title
    assert_equal rich_text_body, article.body
  end

  test "shows fixed editor type on existing markdown article edit form" do
    login_as_admin
    visit edit_admin_article_path(@article)

    assert_text "保存済み記事の編集方式は変更できません"
    assert_selector "select[name='article[editor_type]'][disabled]"
    assert_no_selector ".jodit-container"
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

  test "rich text editor is available at mobile width" do
    page.driver.browser.manage.window.resize_to(390, 844)
    login_as_admin
    visit new_admin_article_path

    select "リッチテキスト", from: "編集方式"
    assert_rich_text_editor_ready
    assert_selector ".jodit-toolbar__box"
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

    def assert_rich_text_editor_ready
      assert_selector "textarea#article_body_rich_text[data-rich-text-editor-ready='true']", visible: :all
      assert_selector ".jodit-container"
      assert_selector ".jodit-wysiwyg"
      assert_equal 1, page.evaluate_script("document.querySelectorAll('.jodit-container').length")
    end

    def set_rich_text_body(html)
      assert_rich_text_editor_ready
      page.execute_script(<<~JS, html)
        const source = document.querySelector("#article_body_rich_text")
        source.richTextEditor.value = arguments[0]
        source.value = source.richTextEditor.value
      JS
    end

    def rich_text_source_value
      page.evaluate_script("document.querySelector('#article_body_rich_text').value")
    end

    def rich_text_editor_option(name)
      page.evaluate_script("document.querySelector('#article_body_rich_text').richTextEditor.options[arguments[0]]", name)
    end

    def rich_text_body
      "<h2>リッチ見出し</h2><p>#{'本文' * 200}</p><p><span style=\"font-size: 1.25rem; color: #2563EB;\"><u>装飾本文</u></span><a href=\"https://example.com\">リンク</a></p>"
    end
end
