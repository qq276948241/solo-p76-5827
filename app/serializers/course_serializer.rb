class CourseSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :start_time, :end_time, :location, :capacity, :level, :duration_hours,
             :booked_count, :waitlist_count, :available_spots, :full?, :can_cancel?

  belongs_to :teacher, serializer: UserSerializer
  has_many :confirmed_bookings, if: :include_bookings?

  def teacher
    object.teacher
  end

  def include_bookings?
    instance_options[:include_bookings] == true
  end

  def confirmed_bookings
    object.confirmed_bookings
  end
end
