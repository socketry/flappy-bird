class CreateHighscores < ActiveRecord::Migration[7.1]
  def change
    create_table :highscores do |t|
      t.string :name
      t.integer :score

      t.timestamps
    end
  end
end
