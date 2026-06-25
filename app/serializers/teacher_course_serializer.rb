class TeacherCourseSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :start_time, :end_time, :location, :capacity, :level, :duration_hours,
             :booked_count, :waitlist_count, :available_spots, :full?

  has_many :bookings_with_attendance, key: :bookings

  def bookings_with_attendance
    object.bookings.where(status: :confirmed).includes(:user, :attendance).map do |booking|
      {
        id: booking.id,
        user: {
          id: booking.user.id,
          name: booking.user.name,
          phone: booking.user.phone,
          email: booking.user.email
        },
        attendance: booking.attendance ? {
          id: booking.attendance.id,
          checked_in: booking.attendance.checked_in,
          checked_in_at: booking.attendance.checked_in_at
        } : nil
      }
    end
  end
end
