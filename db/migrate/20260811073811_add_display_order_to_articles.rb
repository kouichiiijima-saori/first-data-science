class AddDisplayOrderToArticles < ActiveRecord::Migration[8.0]
  def up
    add_column :articles, :display_order, :integer
    add_index :articles, :display_order

    titles_in_order = [
      "データサイエンスとは？身近な例から学ぼう",
      "データ分析はどのように進めるのか",
      "データ分析で使われるPythonとは",
      "Pythonの基本文法を読んでみよう",
      "リスト・辞書・条件分岐・繰り返し",
      "CSVと表形式データの基本を知ろう",
      "データ前処理とデータクリーニングの基本",
      "平均値・中央値・最頻値とばらつきの基本",
      "データ可視化とグラフの使い分け",
      "カフェの売上データで分析の流れを体験しよう"
    ]

    titles_in_order.each_with_index do |title, index|
      Article.where("title LIKE ?", "%#{title}%").update_all(display_order: index + 1)
    end
  end

  def down
    remove_index :articles, :display_order
    remove_column :articles, :display_order
  end
end
