class BookingService
  class BookingError < StandardError; end
  class WaitlistError < StandardError; end

  def initialize(user, course)
    @user = user
    @course = course
  end

  def book!
    validate_booking!

    ActiveRecord::Base.transaction do
      if @course.full?
        add_to_waitlist!
      else
        create_booking!
      end
    end
  end

  def cancel!
    booking = @user.bookings.find_by(course_id: @course.id, status: [:confirmed, :waitlisted])
    raise BookingError, 'No active booking found for this course' unless booking

    ActiveRecord::Base.transaction do
      if booking.confirmed?
        cancel_confirmed_booking!(booking)
      else
        cancel_waitlisted_booking!(booking)
      end
    end

    booking
  end

  private

  def validate_booking!
    raise BookingError, 'Course has already started' if @course.start_time <= Time.now
    raise BookingError, 'Teachers cannot book their own courses' if @user.id == @course.teacher_id

    existing_booking = @user.bookings.find_by(course_id: @course.id)
    if existing_booking
      if existing_booking.confirmed? || existing_booking.waitlisted?
        raise BookingError, 'You have already booked this course'
      end
    end

    existing_waitlist = @user.waitlists.find_by(course_id: @course.id, active: true)
    raise BookingError, 'You are already on the waitlist for this course' if existing_waitlist

    raise BookingError, 'No active membership found' unless @user.active_membership
    raise BookingError, 'Insufficient class credits' unless @user.can_book_course?
  end

  def create_booking!
    booking = @user.bookings.create!(
      course: @course,
      status: :confirmed,
      reminder_sent_at: nil
    )

    @user.deduct_class!

    begin
      NotificationService.create_booking_confirmed_notification(@user, @course, booking)
    rescue StandardError => e
      Rails.logger.error "Failed to send booking confirmed notification for user #{@user.id}: #{e.message}"
    end

    booking
  end

  def add_to_waitlist!
    booking = @user.bookings.create!(
      course: @course,
      status: :waitlisted,
      reminder_sent_at: nil
    )

    waitlist = @course.waitlists.create!(
      user: @user,
      active: true
    )

    begin
      NotificationService.create_waitlist_notification(@user, @course, waitlist)
    rescue StandardError => e
      Rails.logger.error "Failed to send waitlist notification for user #{@user.id}: #{e.message}"
    end

    { booking: booking, waitlist: waitlist }
  end

  def cancel_confirmed_booking!(booking)
    unless @course.can_cancel?
      raise BookingError, 'Cancellation is only allowed more than 2 hours before class start'
    end

    booking.update!(status: :cancelled, cancelled_at: Time.now)
    @user.refund_class!

    begin
      NotificationService.create_cancellation_notification(@user, @course, booking)
    rescue StandardError => e
      Rails.logger.error "Failed to send cancellation notification for user #{@user.id}: #{e.message}"
    end

    promote_from_waitlist!
  end

  def cancel_waitlisted_booking!(booking)
    waitlist = @user.waitlists.find_by(course_id: @course.id, active: true)
    waitlist&.update!(active: false)

    booking.update!(status: :cancelled, cancelled_at: Time.now, cancel_reason: 'Removed from waitlist')

    begin
      NotificationService.create_cancellation_notification(@user, @course, booking)
    rescue StandardError => e
      Rails.logger.error "Failed to send waitlist cancellation notification for user #{@user.id}: #{e.message}"
    end

    reorder_waitlist!
  end

  def promote_from_waitlist!
    first_waitlisted = @course.waitlists.active.order(position: :asc).first
    return unless first_waitlisted

    user = first_waitlisted.user
    return unless user.can_book_course?

    booking = user.bookings.find_by(course_id: @course.id, status: :waitlisted)

    ActiveRecord::Base.transaction do
      booking&.update!(status: :confirmed)
      first_waitlisted.update!(active: false)
      user.deduct_class!
      reorder_waitlist!

      begin
        NotificationService.create_promotion_notification(user, @course, booking)
      rescue StandardError => e
        Rails.logger.error "Failed to send promotion notification for user #{user.id}: #{e.message}"
      end
    end
  end

  def reorder_waitlist!
    active_waitlists = @course.waitlists.active.order(position: :asc)
    active_waitlists.each_with_index do |wl, index|
      wl.update_column(:position, index + 1)
    end
  end
end
