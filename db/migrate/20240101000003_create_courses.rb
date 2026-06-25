class CreateCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.string :name, null: false
      t.text :description
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :location
      t.integer :capacity, null: false, default: 10
      t.integer :level, null: false, default: 0
      t.decimal :duration_hours, precision: 4, scale: 2, default: 1.0

      t.timestamps
    end

    add_index :courses, :start_time
    add_index :courses, [:teacher_id, :start_time]
  end
end
