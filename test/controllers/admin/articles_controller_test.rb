require "test_helper"
require "tempfile"

class Admin::ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
    @article = Article.create!(
      title: "Existing Article",
      summary: "Existing summary",
      body: long_body,
      status: "draft"
    )
  end

  test "redirects unauthenticated users from article admin pages" do
    get admin_articles_path
    assert_redirected_to admin_login_path

    get new_admin_article_path
    assert_redirected_to admin_login_path

    get edit_admin_article_path(@article)
    assert_redirected_to admin_login_path
  end

  test "renders article index for authenticated admin" do
    login_as_admin

    get admin_articles_path

    assert_response :success
    assert_select "h1", "記事管理"
    assert_includes response.body, @article.title
  end

  test "formats updated time for japanese administrators" do
    @article.update_columns(updated_at: Time.utc(2026, 7, 22, 2, 1, 0))
    login_as_admin

    get admin_articles_path

    assert_response :success
    assert_includes response.body, "2026/07/22 11:01"
    assert_no_match(/Jul/, response.body)
  end

  test "renders new form for authenticated admin" do
    login_as_admin

    get new_admin_article_path

    assert_response :success
    assert_select "form[action=?]", admin_articles_path
    assert_select "input[name='article[title]']"
    assert_select "textarea[name='article[summary]']"
    assert_select "textarea#article_body_markdown[name='article[body]']:not([disabled])"
    assert_select "textarea#article_body_rich_text[name='article[body]'][disabled]"
    assert_select "select[name='article[status]']"
    assert_select "select[name='article[editor_type]']"
    assert_select "select[name='article[editor_type]'] option[value='markdown'][selected]"
    assert_select "input[name='article[tag_names]']"
    assert_select "input[name='article[thumbnail]'][accept=?]", "image/jpeg,image/png,image/webp"
    assert_includes response.body, "JPEG・PNG・WebP、5MB以下"
  end

  test "creates article with permitted attributes and comma separated tags" do
    login_as_admin

    assert_difference -> { Article.count }, 1 do
      post admin_articles_path, params: {
        article: {
          title: "New Article",
          summary: "New summary",
          body: long_body,
          status: "published",
          tag_names: "Python, Statistics, Python",
          created_at: 1.year.ago
        }
      }
    end

    article = Article.order(:created_at).last
    assert_redirected_to admin_articles_path
    assert_equal "New Article", article.title
    assert_equal "New summary", article.summary
    assert_equal long_body, article.body
    assert_equal "published", article.status
    assert_equal "markdown", article.editor_type
    assert_equal %w[Python Statistics], article.tags.order(:name).pluck(:name)
    assert_operator article.created_at, :>, 1.minute.ago
  end

  test "creates rich text article" do
    login_as_admin

    assert_difference -> { Article.count }, 1 do
      post admin_articles_path, params: {
        article: valid_article_params.merge(editor_type: "rich_text", body: rich_text_body)
      }
    end

    article = Article.order(:created_at).last
    assert_redirected_to admin_articles_path
    assert_equal "rich_text", article.editor_type
    assert_equal rich_text_body, article.body
  end

  test "updates rich text article body without converting html" do
    login_as_admin
    article = Article.create!(
      title: "Rich Text Existing",
      summary: "Rich text existing summary",
      body: rich_text_body,
      status: "draft",
      editor_type: "rich_text"
    )
    updated_body = "<h2>更新見出し</h2><p>#{long_body}</p><p><u>下線</u>と<a href=\"https://example.com\">リンク</a></p>"

    patch admin_article_path(article), params: {
      article: {
        title: "Rich Text Updated",
        summary: "Rich text updated summary",
        body: updated_body,
        status: "published",
        tag_names: "Ruby"
      }
    }

    article.reload
    assert_redirected_to admin_articles_path
    assert_equal "rich_text", article.editor_type
    assert_equal updated_body, article.body
  end

  test "does not create article with invalid editor type" do
    login_as_admin

    assert_no_difference -> { Article.count } do
      post admin_articles_path, params: {
        article: valid_article_params.merge(editor_type: "plain_text")
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-explanation", /編集方式を正しく選択してください/
  end

  test "keeps selected editor type and rich text body when new form validation fails" do
    login_as_admin

    assert_no_difference -> { Article.count } do
      post admin_articles_path, params: {
        article: valid_article_params.merge(title: "", editor_type: "rich_text", body: rich_text_body)
      }
    end

    assert_response :unprocessable_entity
    assert_select "select[name='article[editor_type]'] option[value='rich_text'][selected]"
    assert_select "textarea#article_body_rich_text:not([disabled])", /リッチ見出し/
    assert_select "textarea#article_body_markdown[disabled]"
  end

  test "creates article with valid thumbnail" do
    login_as_admin

    assert_difference -> { Article.count }, 1 do
      post admin_articles_path, params: {
        article: valid_article_params.merge(thumbnail: uploaded_fixture("sample.png", "image/png"))
      }
    end

    article = Article.order(:created_at).last
    assert_redirected_to admin_articles_path
    assert article.thumbnail.attached?
    assert_equal "image/png", article.thumbnail.blob.content_type
  end

  test "does not create article with invalid thumbnail format" do
    login_as_admin

    assert_no_difference -> { Article.count } do
      post admin_articles_path, params: {
        article: valid_article_params.merge(
          tag_names: "Python",
          thumbnail: uploaded_fixture("sample.html", "text/html")
        )
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-explanation", /サムネイル画像はJPEG、PNG、WebP形式のみアップロードできます/
    assert_includes response.body, "Python"
    assert_includes response.body, "New Article"
  end

  test "does not create article with oversized thumbnail" do
    login_as_admin

    assert_no_difference -> { Article.count } do
      with_large_upload do |upload|
        post admin_articles_path, params: {
          article: valid_article_params.merge(thumbnail: upload)
        }
      end
    end

    assert_response :unprocessable_entity
    assert_select ".error-explanation", /サムネイル画像のファイルサイズは5MB以下にしてください/
  end

  test "creates article with ten tags" do
    login_as_admin

    assert_difference -> { Article.count }, 1 do
      post admin_articles_path, params: {
        article: valid_article_params.merge(tag_names: tag_names(10).join(", "))
      }
    end

    article = Article.order(:created_at).last
    assert_redirected_to admin_articles_path
    assert_equal tag_names(10), article.tags.order(:name).pluck(:name)
  end

  test "does not create article with eleven unique tags" do
    login_as_admin

    assert_no_difference -> { Article.count } do
      assert_no_difference -> { Tag.count } do
        assert_no_difference -> { ArticleTag.count } do
          post admin_articles_path, params: {
            article: valid_article_params.merge(tag_names: tag_names(11).join(", "))
          }
        end
      end
    end

    assert_response :unprocessable_entity
    assert_select ".error-explanation", /タグは10件以内で入力してください/
  end

  test "creates article when duplicate tag inputs normalize to ten or fewer tags" do
    login_as_admin
    raw_tags = (tag_names(10) + [ "Tag01" ]).join(", ")

    assert_difference -> { Article.count }, 1 do
      post admin_articles_path, params: {
        article: valid_article_params.merge(tag_names: raw_tags)
      }
    end

    article = Article.order(:created_at).last
    assert_redirected_to admin_articles_path
    assert_equal tag_names(10), article.tags.order(:name).pluck(:name)
  end

  test "does not count empty tag inputs and supports mixed commas" do
    login_as_admin
    raw_tags = "Tag01,, Tag02， ，Tag03,"

    assert_difference -> { Article.count }, 1 do
      post admin_articles_path, params: {
        article: valid_article_params.merge(tag_names: raw_tags)
      }
    end

    article = Article.order(:created_at).last
    assert_redirected_to admin_articles_path
    assert_equal %w[Tag01 Tag02 Tag03], article.tags.order(:name).pluck(:name)
  end

  test "does not create article with tag name longer than fifty characters" do
    login_as_admin

    assert_no_difference -> { Article.count } do
      assert_no_difference -> { Tag.count } do
        assert_no_difference -> { ArticleTag.count } do
          post admin_articles_path, params: {
            article: valid_article_params.merge(tag_names: "Python, #{'あ' * (Tag::NAME_MAX_LENGTH + 1)}")
          }
        end
      end
    end

    assert_response :unprocessable_entity
    assert_select ".error-explanation", /タグ名は50文字以内で入力してください/
  end

  test "does not create article when title summary or body exceeds maximum length" do
    login_as_admin

    assert_no_difference -> { Article.count } do
      post admin_articles_path, params: {
        article: valid_article_params.merge(
          title: "あ" * (Article::TITLE_MAX_LENGTH + 1),
          summary: "あ" * (Article::SUMMARY_MAX_LENGTH + 1),
          body: "あ" * (Article::BODY_MAX_LENGTH + 1)
        )
      }
    end

    assert_response :unprocessable_entity
    assert_select ".error-explanation", /タイトルは120文字以内で入力してください/
    assert_select ".error-explanation", /概要は500文字以内で入力してください/
    assert_select ".error-explanation", /本文は15,000文字以内で入力してください/
  end

  test "rerenders new with validation errors" do
    login_as_admin

    assert_no_difference -> { Article.count } do
      post admin_articles_path, params: {
        article: {
          title: "",
          summary: "",
          body: "",
          status: "published",
          tag_names: "Python"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "記事新規作成"
    assert_select ".error-explanation"
    assert_includes response.body, "Python"
  end

  test "updates article and replaces tags" do
    login_as_admin
    @article.tags << Tag.create!(name: "Old")

    patch admin_article_path(@article), params: {
      article: {
        title: "Updated Article",
        summary: "Updated summary",
        body: long_body,
        status: "published",
        tag_names: "Machine Learning, Data"
      }
    }

    @article.reload
    assert_redirected_to admin_articles_path
    assert_equal "Updated Article", @article.title
    assert_equal "Updated summary", @article.summary
    assert_equal long_body, @article.body
    assert_equal "published", @article.status
    assert_equal [ "Data", "Machine Learning" ], @article.tags.order(:name).pluck(:name)
  end

  test "does not update article with too many tags and keeps existing attributes and tags" do
    login_as_admin
    @article.tags << Tag.create!(name: "Existing")
    original_attributes = @article.attributes.slice("title", "summary", "body", "status")
    original_tag_names = @article.tags.order(:name).pluck(:name)

    assert_no_difference -> { Tag.count } do
      assert_no_difference -> { ArticleTag.count } do
        patch admin_article_path(@article), params: {
          article: {
            title: "Rejected Update",
            summary: "Rejected summary",
            body: long_body,
            status: "published",
            tag_names: tag_names(11).join(", ")
          }
        }
      end
    end

    @article.reload
    assert_response :unprocessable_entity
    assert_select ".error-explanation", /タグは10件以内で入力してください/
    assert_equal original_attributes, @article.attributes.slice("title", "summary", "body", "status")
    assert_equal original_tag_names, @article.tags.order(:name).pluck(:name)
  end

  test "does not update article with invalid thumbnail" do
    login_as_admin
    attach_existing_thumbnail
    original_attributes = @article.attributes.slice("title", "summary", "body", "status")
    original_blob_id = @article.thumbnail.blob.id

    patch admin_article_path(@article), params: {
      article: {
        title: "Rejected Update",
        summary: "Rejected summary",
        body: long_body,
        status: "published",
        tag_names: "Rejected",
        thumbnail: uploaded_fixture("sample.html", "text/html")
      }
    }

    @article.reload
    assert_response :unprocessable_entity
    assert_select ".error-explanation", /サムネイル画像はJPEG、PNG、WebP形式のみアップロードできます/
    assert_equal original_attributes, @article.attributes.slice("title", "summary", "body", "status")
    assert_equal original_blob_id, @article.thumbnail.blob.id
    assert_empty @article.tags
  end

  test "does not allow changing editor type on existing article" do
    login_as_admin
    original_attributes = @article.attributes.slice("title", "summary", "body", "status", "editor_type")

    patch admin_article_path(@article), params: {
      article: {
        title: "Updated Article",
        summary: "Updated summary",
        body: long_body,
        status: "published",
        editor_type: "rich_text",
        tag_names: "Machine Learning"
      }
    }

    @article.reload
    assert_response :unprocessable_entity
    assert_select ".error-explanation", /編集方式は保存済み記事では変更できません/
    assert_select "select[name='article[editor_type]'][disabled] option[value='markdown'][selected]"
    assert_equal original_attributes, @article.attributes.slice("title", "summary", "body", "status", "editor_type")
    assert_empty @article.tags
  end

  test "updates article without changing existing thumbnail when no new thumbnail is selected" do
    login_as_admin
    attach_existing_thumbnail
    original_blob_id = @article.thumbnail.blob.id

    patch admin_article_path(@article), params: {
      article: {
        title: "Updated Article",
        summary: "Updated summary",
        body: long_body,
        status: "published",
        tag_names: "Machine Learning"
      }
    }

    @article.reload
    assert_redirected_to admin_articles_path
    assert_equal "Updated Article", @article.title
    assert_equal original_blob_id, @article.thumbnail.blob.id
    assert_equal [ "Machine Learning" ], @article.tags.pluck(:name)
  end

  test "rerenders edit with validation errors" do
    login_as_admin

    patch admin_article_path(@article), params: {
      article: {
        title: "",
        summary: "Summary",
        body: "Body",
        status: "draft",
        tag_names: "Draft"
      }
    }

    assert_response :unprocessable_entity
    assert_select "h1", "記事編集"
    assert_select ".error-explanation"
    assert_includes response.body, "Draft"
  end

  test "destroys article" do
    login_as_admin

    assert_difference -> { Article.count }, -1 do
      delete admin_article_path(@article)
    end

    assert_redirected_to admin_articles_path
  end

  private
    def tag_names(count)
      Array.new(count) { |index| "Tag%02d" % (index + 1) }
    end

    def valid_article_params
      {
        title: "New Article",
        summary: "New summary",
        body: long_body,
        status: "published",
        tag_names: "Python"
      }
    end

    def uploaded_fixture(filename, content_type)
      Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files", filename), content_type)
    end

    def with_large_upload
      Tempfile.create([ "large-thumbnail", ".jpg" ], binmode: true) do |file|
        jpeg = File.binread(Rails.root.join("test/fixtures/files/sample.jpg"))
        file.write(jpeg)
        file.write("a" * (Article::THUMBNAIL_MAX_BYTE_SIZE + 1 - jpeg.bytesize))
        file.rewind

        yield Rack::Test::UploadedFile.new(
          file.path,
          "image/jpeg",
          true,
          original_filename: "large-thumbnail.jpg"
        )
      end
    end

    def attach_existing_thumbnail
      @article.thumbnail.attach(
        io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
        filename: "sample.png",
        content_type: "image/png"
      )
    end

    def long_body
      "本文" * 200
    end

    def rich_text_body
      "<h2>リッチ見出し</h2><p>#{long_body}</p><p><span style=\"font-size: 1.25rem; color: #2563EB;\">装飾本文</span></p>"
    end

    def login_as_admin
      post admin_login_path, params: { email: @admin.email, password: "password123" }
    end
end
