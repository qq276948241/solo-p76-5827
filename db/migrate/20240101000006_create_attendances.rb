class CreateAttendances < ActiveRecord::Migration[7.0]
  def change
    create_table :attendances do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :checked_in, null: false, default: false
      t.datetime :checked_in_at

      t.timestamps
    end

    add_index :attendances, [:booking_id], unique: true
  end
end
