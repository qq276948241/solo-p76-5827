class Waitlist < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :user_id, uniqueness: { scope: :course_id, message: 'is already on the waitlist' }
  validates :position, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }

  before_validation :set_position, on: :create

  private

  def set_position
    max_position = course.waitlists.maximum(:position) || 0
    self.position = max_position + 1
  end
end
