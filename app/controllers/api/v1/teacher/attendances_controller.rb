module Api
  module V1
    module Teacher
      class AttendancesController < ApplicationController
        before_action :authorize_teacher!

        def create
          attendance = Attendance.find(params[:attendance_id] || params[:id])

          unless current_user.teaching_courses.exists?(attendance.course_id)
            return render json: { error: 'You are not authorized to manage this course' }, status: :forbidden
          end

          attendance.check_in!

          render json: {
            message: 'Check-in successful',
            attendance: AttendanceSerializer.new(attendance).as_json
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Attendance record not found' }, status: :not_found
        end

        def batch_check_in
          course = current_user.teaching_courses.find(params[:course_id])
          user_ids = params[:user_ids] || []

          attendances = course.attendances.where(user_id: user_ids)
          checked_in_count = 0

          ActiveRecord::Base.transaction do
            attendances.each do |attendance|
              unless attendance.checked_in?
                attendance.check_in!
                checked_in_count += 1
              end
            end
          end

          render json: {
            message: "Checked in #{checked_in_count} out of #{user_ids.length} users",
            checked_in_count: checked_in_count
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Course not found' }, status: :not_found
        end
      end
    end
  end
end
