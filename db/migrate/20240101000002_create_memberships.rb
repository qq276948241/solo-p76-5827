class CreateMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :membership_type, null: false, default: 0
      t.integer :total_classes
      t.integer :remaining_classes
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
