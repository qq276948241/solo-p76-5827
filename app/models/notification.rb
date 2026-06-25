class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :title, presence: true
  validates :body, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def unread?
    read_at.nil?
  end

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.now) unless read?
  end
end
