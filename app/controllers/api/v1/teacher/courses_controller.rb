module Api
  module V1
    module Teacher
      class CoursesController < ApplicationController
        before_action :authorize_teacher!

        def index
          date = params[:date] ? Date.parse(params[:date]) : Date.today
          @courses = current_user.teaching_courses
                                  .by_date_range(date, date)
                                  .includes(:bookings, :attendances)

          render json: @courses,
                 each_serializer: TeacherCourseSerializer,
                 include_bookings: true
        end

        def today
          @courses = current_user.teaching_courses
                                  .today
                                  .includes(:bookings, :attendances)

          render json: @courses,
                 each_serializer: TeacherCourseSerializer,
                 include_bookings: true
        end

        def show
          @course = current_user.teaching_courses.find(params[:id])
          render json: @course,
                 serializer: TeacherCourseSerializer,
                 include_bookings: true
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Course not found' }, status: :not_found
        end
      end
    end
  end
end
