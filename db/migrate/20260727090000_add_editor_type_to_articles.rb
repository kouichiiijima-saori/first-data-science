class AddEditorTypeToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :editor_type, :string, null: false, default: "markdown"
  end
end
