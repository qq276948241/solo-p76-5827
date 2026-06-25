class CreateBookings < ActiveRecord::Migration[7.0]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :cancelled_at
      t.string :cancel_reason

      t.timestamps
    end

    add_index :bookings, [:user_id, :course_id], unique: true
    add_index :bookings, :status
  end
end
