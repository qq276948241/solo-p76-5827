class User < ApplicationRecord
  has_secure_password

  enum role: { member: 0, teacher: 1, admin: 2 }

  has_many :memberships, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :waitlists, dependent: :destroy
  has_many :attendances, dependent: :destroy
  has_many :teaching_courses, class_name: 'Course', foreign_key: 'teacher_id'

  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, if: :new_record?

  def active_membership
    memberships.where(active: true).where('start_date <= ? AND end_date >= ?', Date.today, Date.today).order(created_at: :desc).first
  end

  def can_book_course?
    membership = active_membership
    return false unless membership

    if membership.punch_card?
      membership.remaining_classes.to_i > 0
    else
      true
    end
  end

  def deduct_class!
    membership = active_membership
    return false unless membership&.punch_card?
    return false if membership.remaining_classes.to_i <= 0

    membership.decrement!(:remaining_classes)
  end

  def refund_class!
    membership = active_membership
    return false unless membership&.punch_card?

    membership.increment!(:remaining_classes)
  end
end
