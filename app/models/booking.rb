class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :course

  has_one :attendance, dependent: :destroy

  enum status: { confirmed: 0, cancelled: 1, waitlisted: 2, completed: 3, no_show: 4 }

  validates :user_id, uniqueness: { scope: :course_id, message: 'has already booked this course' }
  validates :status, presence: true

  after_create :create_attendance_record, if: :confirmed?

  def create_attendance_record
    Attendance.create!(booking: self, course: course, user: user)
  end
end
