class Course < ApplicationRecord
  belongs_to :teacher, class_name: 'User'

  has_many :bookings, dependent: :destroy
  has_many :waitlists, -> { order(position: :asc) }, dependent: :destroy
  has_many :attendances, dependent: :destroy

  enum level: { beginner: 0, intermediate: 1, advanced: 2 }

  validates :name, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0 }
  validates :teacher, presence: true

  validate :end_time_after_start_time

  scope :upcoming, -> { where('start_time > ?', Time.now).order(start_time: :asc) }
  scope :today, -> { where(start_time: Date.today.beginning_of_day..Date.today.end_of_day).order(start_time: :asc) }
  scope :by_date_range, ->(start_date, end_date) { where(start_time: start_date.beginning_of_day..end_date.end_of_day).order(start_time: :asc) }

  def confirmed_bookings
    bookings.where(status: :confirmed)
  end

  def booked_count
    confirmed_bookings.count
  end

  def waitlist_count
    waitlists.where(active: true).count
  end

  def available_spots
    capacity - booked_count
  end

  def full?
    available_spots <= 0
  end

  def can_cancel?
    start_time - 2.hours > Time.now
  end

  def cancellable_free?
    can_cancel?
  end

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    errors.add(:end_time, 'must be after start time') if end_time <= start_time
  end
end
