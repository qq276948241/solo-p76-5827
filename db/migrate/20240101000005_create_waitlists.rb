class CreateWaitlists < ActiveRecord::Migration[7.0]
  def change
    create_table :waitlists do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :position, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :waitlists, [:course_id, :position]
    add_index :waitlists, [:user_id, :course_id], unique: true
  end
end
