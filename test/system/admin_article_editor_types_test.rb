require "application_system_test_case"
require "securerandom"

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
    assert_equal %w[paragraph fontsize brush underline link undo redo eraser image], buttons
    assert_equal({ "p" => "通常段落", "h2" => "見出し2", "h3" => "見出し3", "h4" => "見出し4" }, rich_text_editor_option("controls")["paragraph"]["list"])
    assert_equal({ "0.875rem" => "小", "1rem" => "標準", "1.25rem" => "大", "1.5rem" => "特大" }, rich_text_editor_option("controls")["fontsize"]["list"])
    assert_equal [ "#111827", "#374151", "#2563EB", "#047857", "#B45309", "#B91C1C" ], rich_text_editor_option("colors")

    disabled_plugins = rich_text_editor_option("disablePlugins")
    assert_not_includes disabled_plugins, "image"
    assert_includes disabled_plugins, "image-properties"
    assert_includes disabled_plugins, "file"
    assert_includes disabled_plugins, "video"
    assert_includes disabled_plugins, "source"
    assert_includes disabled_plugins, "table"
    assert_equal true, page.evaluate_script("document.querySelector('#article_body_rich_text').richTextEditor.options.controls.image.popup === undefined")
    assert_equal true, page.evaluate_script("Array.from(document.querySelector(\"#article_body_rich_text\").richTextEditor.options.allowResizeTags).includes(\"img\")")
    assert_equal true, page.evaluate_script("document.querySelector(\"#article_body_rich_text\").richTextEditor.options.resizer.forImageChangeAttributes")
    assert_equal true, page.evaluate_script("Array.from(document.querySelector(\"#article_body_rich_text\").richTextEditor.options.resizer.useAspectRatio).includes(\"img\")")
  end

  test "uploads body image into rich text article and keeps it after re-edit" do
    login_as_admin
    visit new_admin_article_path
    select "リッチテキスト", from: "編集方式"
    assert_rich_text_editor_ready
    assert_selector ".jodit-toolbar-button_image"

    fill_in "タイトル", with: "Rich Text Image Article"
    fill_in "概要", with: "Rich text image summary"
    set_rich_text_body("<h2>画像見出し</h2><p>#{'本文' * 200}</p>")
    upload_body_image_fixture("sample.png")

    assert_selector ".jodit-wysiwyg img[src*='/rails/active_storage/blobs/']"
    assert_selector "input[name='article[body_image_signed_ids][]']", visible: :all
    assert_no_match(/data:image/i, rich_text_source_value)
    select "公開中 (published)", from: "公開状態"
    click_button "保存する"

    assert_text "記事を作成しました"
    article = Article.find_by!(title: "Rich Text Image Article")
    assert_equal "rich_text", article.editor_type
    assert article.body_images.attached?
    assert_includes article.body, "/rails/active_storage/blobs/"

    visit edit_admin_article_path(article)
    assert_rich_text_editor_ready
    assert_selector ".jodit-wysiwyg img[src*='/rails/active_storage/blobs/']"
  end

  test "keeps resized body image dimensions after save and re-edit" do
    login_as_admin
    visit new_admin_article_path
    select "リッチテキスト", from: "編集方式"
    assert_rich_text_editor_ready

    fill_in "タイトル", with: "Rich Text Resized Image Article"
    fill_in "概要", with: "Rich text resized image summary"
    set_rich_text_body("<h2>画像サイズ見出し</h2><p>#{"本文" * 200}</p>")
    upload_body_image_fixture("sample.png")
    assert_selector ".jodit-wysiwyg img[src*=\"/rails/active_storage/blobs/\"]"

    resize_body_image(width: 320, height: 240)
    assert_includes rich_text_source_value, "width=\"320\""
    assert_includes rich_text_source_value, "height=\"240\""
    assert_no_match(/<img[^>]+style=/i, rich_text_source_value)

    click_button "保存する"

    assert_text "記事を作成しました"
    article = Article.find_by!(title: "Rich Text Resized Image Article")
    assert_includes article.body, "width=\"320\""
    assert_includes article.body, "height=\"240\""
    assert_no_match(/<img[^>]+style=/i, article.body)

    visit edit_admin_article_path(article)
    assert_rich_text_editor_ready
    assert_selector ".jodit-wysiwyg img[width=\"320\"][height=\"240\"]"
  end

  test "keeps uploaded body image reference after validation failure" do
    login_as_admin
    visit new_admin_article_path
    select "リッチテキスト", from: "編集方式"
    assert_rich_text_editor_ready

    fill_in "タイトル", with: "Rich Text Image Validation Article"
    fill_in "概要", with: "Rich text image summary"
    fill_in "タグ", with: "あ" * 51
    set_rich_text_body("<h2>画像見出し</h2><p>#{'本文' * 200}</p>")
    upload_body_image_fixture("sample.jpg")
    assert_selector "input[name=\"article[body_image_signed_ids][]\"]", visible: :all
    resize_body_image(width: 280, height: 210)
    signed_id = page.evaluate_script("document.querySelector('input[name=\\\"article[body_image_signed_ids][]\\\"]').value")

    click_button "保存する"

    assert_text "保存できませんでした"
    assert_rich_text_editor_ready
    assert_selector "input[name='article[body_image_signed_ids][]'][value='#{signed_id}']", visible: :all
    assert_includes rich_text_source_value, "/rails/active_storage/blobs/"
    assert_includes rich_text_source_value, "width=\"280\""
    assert_includes rich_text_source_value, "height=\"210\""
  end

  test "shows japanese error when body image upload is invalid" do
    login_as_admin
    visit new_admin_article_path
    select "リッチテキスト", from: "編集方式"
    assert_rich_text_editor_ready

    upload_body_image_fixture("sample.html")

    assert_text "本文画像はJPEG、PNG、WebP形式のみアップロードできます"
    assert_no_selector ".jodit-wysiwyg img"
    assert_no_selector "input[name='article[body_image_signed_ids][]']", visible: :all
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

    def upload_body_image_fixture(filename)
      input_id = "body-image-upload-#{SecureRandom.hex(4)}"
      page.execute_script(<<~JS, input_id)
        const input = document.createElement("input")
        input.type = "file"
        input.id = arguments[0]
        document.body.append(input)
      JS
      attach_file input_id, Rails.root.join("test/fixtures/files", filename)
      page.execute_script(<<~JS, input_id)
        const source = document.querySelector("#article_body_rich_text")
        const input = document.getElementById(arguments[0])
        const controller = window.Stimulus.getControllerForElementAndIdentifier(source.closest("form"), "rich-text-editor")
        controller.uploadBodyImageFiles(input.files).catch(() => {}).finally(() => input.remove())
      JS
    end

    def resize_body_image(width:, height:)
      assert_rich_text_editor_ready
      page.execute_script(<<~JS, width, height)
        const source = document.querySelector("#article_body_rich_text")
        const image = document.querySelector(".jodit-wysiwyg img")
        const controller = window.Stimulus.getControllerForElementAndIdentifier(source.closest("form"), "rich-text-editor")
        image.setAttribute("width", arguments[0])
        image.setAttribute("height", arguments[1])
        image.setAttribute("style", `width: ${arguments[0]}px; height: ${arguments[1]}px; border: 10px solid red;`)
        controller.syncToSource()
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
