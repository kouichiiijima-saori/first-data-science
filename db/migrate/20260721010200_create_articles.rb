class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title, null: false
      t.text :summary, null: false
      t.text :body, limit: 4.gigabytes - 1, null: false
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :articles, :title
    add_index :articles, :status
  end
end
