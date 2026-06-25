class Attendance < ApplicationRecord
  belongs_to :booking
  belongs_to :course
  belongs_to :user

  validates :booking_id, uniqueness: true

  def check_in!
    update!(checked_in: true, checked_in_at: Time.now)
  end
end
