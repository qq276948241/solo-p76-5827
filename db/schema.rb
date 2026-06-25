ActiveRecord::Schema[7.0].define(version: 2024_01_01_000006) do
  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone", null: false
    t.string "email"
    t.string "password_digest", null: false
    t.integer "role", null: false, default: 0
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "membership_type", null: false, default: 0
    t.integer "total_classes"
    t.integer "remaining_classes"
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.boolean "active", null: false, default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "teacher_id", null: false
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.string "location"
    t.integer "capacity", null: false, default: 10
    t.integer "level", null: false, default: 0
    t.decimal "duration_hours", precision: 4, scale: 2, default: "1.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["start_time"], name: "index_courses_on_start_time"
    t.index ["teacher_id", "start_time"], name: "index_courses_on_teacher_id_and_start_time"
    t.index ["teacher_id"], name: "index_courses_on_teacher_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.integer "status", null: false, default: 0
    t.datetime "cancelled_at"
    t.string "cancel_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_bookings_on_course_id"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["user_id", "course_id"], name: "index_bookings_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "waitlists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.integer "position", null: false
    t.boolean "active", null: false, default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "position"], name: "index_waitlists_on_course_id_and_position"
    t.index ["course_id"], name: "index_waitlists_on_course_id"
    t.index ["user_id", "course_id"], name: "index_waitlists_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_waitlists_on_user_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "course_id", null: false
    t.bigint "user_id", null: false
    t.boolean "checked_in", null: false, default: false
    t.datetime "checked_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_attendances_on_booking_id", unique: true
    t.index ["course_id"], name: "index_attendances_on_course_id"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  add_foreign_key "memberships", "users"
  add_foreign_key "courses", "users", column: "teacher_id"
  add_foreign_key "bookings", "courses"
  add_foreign_key "bookings", "users"
  add_foreign_key "waitlists", "courses"
  add_foreign_key "waitlists", "users"
  add_foreign_key "attendances", "bookings"
  add_foreign_key "attendances", "courses"
  add_foreign_key "attendances", "users"
end
