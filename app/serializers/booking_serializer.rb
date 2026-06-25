class BookingSerializer < ActiveModel::Serializer
  attributes :id, :status, :cancelled_at, :cancel_reason, :created_at

  belongs_to :user, serializer: UserSerializer
  belongs_to :course, serializer: CourseSerializer
  has_one :attendance, if: :include_attendance?

  def include_attendance?
    instance_options[:include_attendance] == true
  end
end
