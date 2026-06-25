class Membership < ApplicationRecord
  belongs_to :user

  enum membership_type: { punch_card: 0, yearly: 1 }

  validates :membership_type, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :total_classes, presence: true, if: :punch_card?
  validates :remaining_classes, presence: true, if: :punch_card?

  validate :end_date_after_start_date

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end
end
